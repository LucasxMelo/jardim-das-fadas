#!/usr/bin/env python3
"""Simulador independente da interface: regras competitivas da v207.
Não executa o GDScript nem reproduz a IA do Godot. Python >= 3.10, sem dependências.
"""
from __future__ import annotations
import argparse, csv, hashlib, itertools, json, random, re, statistics, time
from collections import Counter, defaultdict
from concurrent.futures import ProcessPoolExecutor
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'scripts/jogo/jardim.gd'
C = ('vermelha','amarela','lilas')
DIRS = ((1,0),(-1,0),(0,1),(0,-1))
POS = tuple((i%3-1,i//3-1) for i in range(9))
PROFILES = {'jardineiro':(1.65,.65,1.25),'coletor':(.75,1.7,.45),'equilibrado':(1.,1.,.85)}

def add(a,b): return a[0]+b[0],a[1]+b[1]
def sign(x): return (x>0)-(x<0)
def dist(a,b): return max(abs(a[0]-b[0]),abs(a[1]-b[1]))
def line(a,b):
    dx,dy=b[0]-a[0],b[1]-a[1]
    if a==b or (dx and dy and abs(dx)!=abs(dy)): return ()
    return tuple((a[0]+i*sign(dx),a[1]+i*sign(dy)) for i in range(1,max(abs(dx),abs(dy))+1))
def score(p): return sum(p)+2*sum(x//3 for x in p)

@dataclass(frozen=True)
class Card:
    id:str; category:str; kind:int; points:int; colors:tuple=(); rotations:tuple=(); anchors:tuple=()

# Importar catálogo verdadeiro a cada execução, sem editar pontuação do jogo.
@lru_cache(maxsize=3)
def read_catalog(n):
    raw=SOURCE.read_text(encoding='utf8')
    s=re.sub(r'(?m)#.*$','',raw)
    def arr(name): return re.search(r'const '+name+r'[^=]*=\s*\[([^]]*)\]',s)[1]
    medium=list(map(int,arr('TIPOS_MEDIOS_ABERTURA_SEGURA').split(',')))
    hard=list(map(int,arr('TIPOS_DIFICEIS_ATIVOS').split(',')))
    models=s.split('const MODELOS_OBJETIVO:',1)[1].split('\n}',1)[0]
    flower=[]; sigs=set()
    for k in sorted(medium+hard):
        b=re.search(r'\b'+str(k)+r':\s*\{([^}]+)\}',models)[1]
        qs=list(map(int,re.search(r'"quadrantes":\s*\[([^]]+)\]',b)[1].split(',')))
        labels=re.findall(r'"([AB])"',re.search(r'"padrao":\s*\[([^]]+)\]',b)[1]); pts=int(re.search(r'"pontos":\s*(\d+)',b)[1]); cat='medio' if k in medium else 'dificil'
        for a,bcol in itertools.permutations(range(3),2):
            coords=[POS[q-1] for q in qs]; colors=[a if l=='A' else bcol for l in labels]
            rots=[]
            for _ in range(4):
                x0=min(x for x,y in coords); y0=min(y for x,y in coords)
                r=tuple(sorted((x-x0,y-y0,c) for (x,y),c in zip(coords,colors)))
                if r not in rots: rots.append(r)
                coords=[(-y,x) for x,y in coords]
            sig=(cat,min(rots))
            if sig in sigs: continue
            sigs.add(sig)
            anchors=tuple(tuple((x-ax,y-ay,c) for x,y,c in r) for r in rots for ax,ay,ac in r)
            # Anchor keyed by required color, to avoid unnecessary checks.
            keyed=tuple(tuple(t for t in anchors if (0,0,c) in t) for c in range(3))
            flower.append(Card(f'gamer:{k}:{C[a]}:{C[bcol]}',cat,k,pts,tuple(sorted((a,bcol))),tuple(rots),keyed))
    fairy=[]
    data=s.split('const OBJETIVOS_FADA_MODELOS:',1)[1].split('\n}',1)[0]
    for k,b in re.findall(r'(\d+):\s*\{([^}]+)\}',data):
        k=int(k); m=re.search(r'"pontos":\s*(\d+)',b)
        pts=int(m[1]) if m else int(re.search(r'"pontos_base":\s*(\d+)',b)[1])
        if not m: pts=pts+n if '"formula_soma": true' in b else max(1,pts-n)
        fairy.append(Card(f'fada:{k}:1','fada',k,pts))
    assert len(medium)==6 and len(hard)==9 and len(fairy)==21, (len(medium),len(hard),len(fairy))
    base=tuple(C.index(c) for c in re.findall(r'"(vermelha|amarela|lilas)"',arr('SETUP_FIXO_NOVE_FLORES')))
    return tuple(flower+fairy),base

def matches(card,board,cells):
    """Combinações novas: chaves de conjuntos de casas, como no Godot."""
    found=set()
    for x,y in cells:
        col=board.get((x,y),-1)
        if col<0: continue
        for pat in card.anchors[col]:
            if all(board.get((x+dx,y+dy))==c for dx,dy,c in pat):
                found.add(tuple(sorted((x+dx,y+dy) for dx,dy,c in pat)))
    return found

def partial(card,board,cells):
    # Heurística de planejamento: combinações com uma única casa faltante.
    seen=set()
    for x,y in cells:
        col=board.get((x,y),-1)
        if col<0: continue
        for pat in card.anchors[col]:
            missing=[]
            for dx,dy,c in pat:
                a=(x+dx,y+dy)
                if board.get(a)!=c:
                    missing.append(a)
                    if len(missing)>1: break
            if len(missing)==1:
                seen.add(tuple(sorted((x+dx,y+dy,c) for dx,dy,c in pat)))
    return seen

@dataclass
class Player:
    profile:str; fairies:list=field(default_factory=lambda:[(0,0),(0,0)]); pollen:list=field(default_factory=lambda:[0,0,0]); hand:list=field(default_factory=list); history:list=field(default_factory=list); turns:int=0; last:int=0; moves:int=0; flights:int=0; blind:int=0; collective:int=0; missed:int=0; first:int=0

class Game:
    def __init__(self,n,seed,bonus,profiles,limit):
        self.n=n; self.seed=seed; self.bonus=bonus; self.rng=random.Random(seed); self.limit=limit
        self.cards,base=read_catalog(n); self.used=set(); self.metrics=[]; self.turn=0; self.deck=[29]*3
        perm=list(range(3)); self.rng.shuffle(perm); order=self.rng.choice([tuple(range(9)),(6,3,0,7,4,1,8,5,2)])
        self.board={pos:perm[base[i]] for pos,i in zip(POS,order)}; self.pollen={pos:1 for pos in POS}
        self.players=[Player(p) for p in profiles]; self.open=self.draw(); self.exhausted=0; self.pollen_created=9
        self.provenance={q:[None] for q in self.board}; self.floral_sources={}
        for p in self.players:
            for _ in range(3): p.hand.append(self.deal(p,'medio'))
    def points(self,c): return c.points+(self.bonus if c.category!='fada' else 0)
    def weights(self):
        counts=Counter(self.board.values()); return [1/(1+counts[c]) if self.deck[c]>0 else 0 for c in range(3)]
    def draw(self):
        w=self.weights()
        if not any(w): return None
        c=self.rng.choices(range(3),weights=w,k=1)[0]; self.deck[c]-=1; return c
    def deal(self,p,cat):
        present=[c for c in p.hand if c]
        choices=[c for c in self.cards if c.category==cat and c.id not in self.used and not any(o.kind==c.kind and (o.category=='fada')==(cat=='fada') for o in present) and (cat=='fada' or (not any(o.colors==c.colors for o in present if o.category!='fada') and not matches(c,self.board,self.board)))]
        if not choices: self.exhausted+=1; return None
        c=self.rng.choice(choices); self.used.add(c.id); self.metrics.append({'id':c.id,'categoria':c.category,'tipo':c.kind,'pontos':self.points(c),'entregue_turno':self.turn,'jogador':next(i for i,pl in enumerate(self.players) if pl is p),'concluido_turno':'','turnos_em_mao':'','turnos_proprios_entrega':p.turns,'status':'ativo'}); return c
    def candidates(self):
        moves=[]; empty=set()
        for p in sorted(self.board):
            for d in DIRS:
                q=add(p,d)
                if q not in self.board:
                    empty.add(q)
                    if p!=(0,0): moves.append((p,q))
        allmoves=[(None,q) for q in sorted(empty)]+moves
        # Limite configurável: amostragem uniforme dos deslocamentos e plantios.
        return self.rng.sample(allmoves,self.limit) if self.limit and len(allmoves)>self.limit else allmoves
    def preview(self,pidx,move,col):
        src,dst=move; target=src if src is not None else dst
        b=self.board.copy(); pol=self.pollen.copy(); fs=[list(p.fairies) for p in self.players]; enemy=False
        if src is not None:
            b[dst]=b[src]; pol[dst]=pol[src]
            for i,ff in enumerate(fs):
                for j,a in enumerate(ff):
                    if a==src: ff[j]=dst; enemy|=i!=pidx
        b[target]=col; pol[target]=1
        return b,pol,fs,target,enemy
    def fairy_ok(self,k,b,fs,i,idx,route,gains,counts,enemy,orig):
        if k==65: return enemy
        if idx is None: return False
        a,z=fs[i]; dest=route[-1]; opp=[p for j,ff in enumerate(fs) if j!=i for p in ff]; dx,dy=abs(a[0]-z[0]),abs(a[1]-z[1]); between=line(a,z)[:-1]; intermediates=sum(q in b for q in between)
        if k==10:return sum(x>0 for x in counts)>=3
        if k==14:return all(gains)
        if k in (25,26):return len(counts)>=(4 if k==25 else 5)
        if k==27:return sum(x>0 for x in counts)>=4
        if k in (41,42,43):return a!=z and b[a]==b[z]==k-41
        if k in (44,45):return (dx==0 or dy==0) and intermediates>=(2 if k==44 else 4)
        if k in (46,47):return dx==dy and dx>0 and intermediates>=(2 if k==46 else 3)
        if k==48:return b[a]!=b[z] and max(dx,dy)>=3
        if k==49:
            if max(dx,dy)<4:return False
            return any(min(a[t],z[t])==min(q[t] for q in b) and max(a[t],z[t])==max(q[t] for q in b) and a[t]!=z[t] for t in (0,1))
        if k==61:return bool(between) and all(q in b for q in line(a,z)) and any(q in opp for q in between)
        if k==64:return any(abs(q[0]-dest[0])+abs(q[1]-dest[1])==1 for q in opp)
        if k==66:return enemy
        if k==67:return any(orig[0]==q[0] or orig[1]==q[1] for q in opp) and all(m[0]!=q[0] and m[1]!=q[1] for m in (a,z) for q in opp)
        if k==69:return any(abs(q[0]-dest[0])==abs(q[1]-dest[1])>=3 for q in opp)
        if k==70:
            return any(dest in line(*ff)[:-1] and all(q in b for q in line(*ff)) for j,ff in enumerate(fs) if j!=i)
        raise ValueError(k)
    def plan(self,i,col,move,pre):
        p=self.players[i]; b,pol,fs,target,enemy=self.preview(i,move,col); changed=(move[1],) if move[0] is None else move
        wg,wp,wh=PROFILES[p.profile]; achieved=[]; preparation=0.
        for c in p.hand:
            if not c or c.category=='fada':continue
            new=matches(c,b,changed)-pre[c.id][0]
            if new: achieved.append((c,min(new)))
            else: preparation+=min(3,len(partial(c,b,changed)-pre[c.id][1]))*.25
        best=None
        for idx in [None,0,1]:
            route=() if idx is None else line(fs[i][idx],target)
            if idx is not None and not route:continue
            gains=[0]*3; counts=[]; f=[list(ff) for ff in fs]
            if idx is not None:
                f[i][idx]=target
                for q in route:
                    if q in b: counts.append(pol[q]); gains[b[q]]+=pol[q]
            goals=achieved+[(c,()) for c in p.hand if c and c.category=='fada' and self.fairy_ok(c.kind,b,f,i,idx,route,gains,counts,enemy,fs[i][idx] if idx is not None else None)]
            # Escolhe maior pontuação, desempate pelo slot (como IA do jogo).
            goal=max(goals,key=lambda g:(self.points(g[0]),-p.hand.index(g[0]))) if goals else None
            gain=score([x+y for x,y in zip(p.pollen,gains)])-score(p.pollen)
            # Avanço rumo à meta não é ponto real; não há flor-prêmio.
            utility=wp*gain+wg*(self.points(goal[0])+1.5 if goal else 0)+wh*preparation
            # Incentiva posições futuras úteis sem adivinhar o baralho.
            if idx is not None:utility+=.04*len(route)
            # Ruído pequeno determinístico pela ordem de sorteio dos candidatos (empates).
            option=(utility,move,idx,goal,route,gains,enemy)
            if best is None or utility>best[0]: best=option
        return best
    def take_turn(self,i):
        p=self.players[i]; self.turn+=1; p.turns+=1
        moves=self.candidates(); cells=set(q for move in moves for q in move if q is not None)
        pre={c.id:(matches(c,self.board,cells),partial(c,self.board,cells)) for c in p.hand if c and c.category!='fada'}
        weights=self.weights(); possible=[c for c in range(3) if weights[c]>0 or self.open==c]
        best={}
        for c in possible:
            best[c]=max((self.plan(i,c,m,pre) for m in moves),key=lambda a:a[0])
        # A cor oculta só é sorteada DEPOIS da escolha da fonte.
        expected=sum(weights[c]*best[c][0] for c in range(3) if weights[c])/sum(weights) if sum(weights) else -1e9
        if self.open is not None and best[self.open][0]>=expected:
            c=self.open; self.open=None; p.collective+=1
        else:c=self.draw(); p.blind+=1
        assert c is not None
        _,move,idx,goal,route,gains,enemy=best[c]; src,dst=move
        self.board,self.pollen,fs,target,_=self.preview(i,move,c)
        if src is not None:self.provenance[dst]=self.provenance.pop(src)
        self.provenance[target]=[None]
        pollen_before=score(p.pollen)
        for j,ff in enumerate(fs):self.players[j].fairies=ff
        self.pollen_created+=1
        if src is not None:p.moves+=1
        if idx is not None:
            p.flights+=1; p.fairies[idx]=target
            for q in route:
                if q in self.board:
                    amount=self.pollen[q]
                    if amount:
                        for origin in self.provenance[q]:
                            prev=score(p.pollen);p.pollen[self.board[q]]+=1; marginal=score(p.pollen)-prev
                            if origin is not None:
                                source=self.floral_sources[origin]; key='proprios' if source['jogador']==i else 'rivais'
                                source['polens_'+key]+=1;source['estrelas_'+key]+=marginal
                        self.pollen[q]=0;self.provenance[q]=[]
                    else:self.pollen[q]=1;self.pollen_created+=1;self.provenance[q]=[None]
        if goal:
            card,cells=goal; p.history.append(card); p.last=p.turns
            if len(p.history)==1:p.first=p.turns
            for m in self.metrics:
                if m['id']==card.id:
                    m['concluido_turno']=self.turn;m['turnos_em_mao']=p.turns-m['turnos_proprios_entrega'];m['status']='concluido';m['estrelas_coleta_na_conquista']=score(p.pollen)-pollen_before;break
            if card.category!='fada':
                source={'jogador':i,'tipo':card.kind,'gerados':0,'polens_proprios':0,'polens_rivais':0,'estrelas_proprios':0,'estrelas_rivais':0}
                self.floral_sources[card.id]=source
                for q in cells:
                    if self.pollen[q]<4:self.pollen[q]+=1;self.pollen_created+=1;self.provenance[q].append(card.id);source['gerados']+=1
            slot=p.hand.index(card);p.hand[slot]=None
            if len(p.history)==3:
                for old in p.hand:
                    if old:
                        next(m for m in self.metrics if m['id']==old.id)['status']='descartado_fase'
                p.hand=[]
                for cat in ('dificil','dificil','fada','fada'):p.hand.append(self.deal(p,cat))
            else:p.hand[slot]=self.deal(p,card.category)
        if self.open is None:self.open=self.draw()
        assert all(len(self.provenance[q])==v for q,v in self.pollen.items())
        assert len(self.board)==9+self.turn and len(self.board)==len(self.pollen)
        assert len(self.board)+sum(self.deck)+(self.open is not None)==96
        assert sum(self.pollen.values())+sum(sum(pl.pollen) for pl in self.players)==self.pollen_created
        assert all(0<=v<=4 for v in self.pollen.values()) and all(q in self.board for pl in self.players for q in pl.fairies)
        return bool(goal)
    def run(self):
        i=0; remaining=0; trigger=None; reason='limite_seguranca'
        while self.turn<120:
            if not any(self.deck) and self.open is None:reason='baralho';break
            won=self.take_turn(i)
            if len(self.players[i].history)>=6 and trigger is None:trigger=i
            if remaining:remaining-=1
            elif won:remaining=self.n
            if not remaining and trigger is not None:reason='seis_objetivos';break
            if not any(self.deck) and self.open is None:reason='baralho';break
            i=(i+1)%self.n
        totals=[sum(self.points(c) for c in p.history)+score(p.pollen) for p in self.players]; best=max(totals); winners=[i for i,t in enumerate(totals) if t==best]; maxobj=max(len(p.history) for p in self.players)
        rows=[]
        for i,p in enumerate(self.players):
            fp=sum(self.points(c) for c in p.history if c.category!='fada'); fap=sum(self.points(c) for c in p.history if c.category=='fada'); pol=sum(p.pollen); bp=score(p.pollen)-pol
            rows.append(dict(jogador=i+1,perfil=p.profile,turnos=p.turns,objetivos=len(p.history),florais=sum(c.category!='fada' for c in p.history),fadas=sum(c.category=='fada' for c in p.history),pontos_florais=fp,pontos_fadas=fap,polens=pol,bonus_trincas=bp,pontos_polens=pol+bp,total=totals[i],vermelhos=p.pollen[0],amarelos=p.pollen[1],lilases=p.pollen[2],vitoria_fracionada=1/len(winners) if i in winners else 0,venceu_com_menos_objetivos=int(i in winners and len(p.history)<maxobj),gatilho=int(i==trigger),primeiro_objetivo_turno=p.first or '',deslocamentos=p.moves,voos=p.flights,compras_baralho=p.blind,compras_coletiva=p.collective))
        for m in self.metrics:
            if m['status']=='ativo':m['status']='nao_concluido'
            m.setdefault('estrelas_coleta_na_conquista','')
            source=self.floral_sources.get(m['id'],{})
            for key in ('gerados','polens_proprios','polens_rivais','estrelas_proprios','estrelas_rivais'):m[key]=source.get(key,0)
            m['polens_restantes']=m['gerados']-m['polens_proprios']-m['polens_rivais']
            assert m['polens_restantes']>=0
        return rows,self.metrics,dict(turnos=self.turn,motivo=reason,empate=int(len(winners)>1),slots_sem_reposicao=self.exhausted,gatilho=(trigger+1 if trigger is not None else ''),ganhadores=';'.join(str(i+1) for i in winners))

def simulate(job):
    n,seed,bonus,profiles,limit=job
    g=Game(n,seed,bonus,profiles,limit); players,goals,match=g.run(); meta=dict(jogadores=n,semente=seed,cenario='atual' if bonus==0 else f'florais_mais_{bonus}',bonus_floral=bonus,amostra_jogadas=limit)
    return [{**meta,**p} for p in players],[{**meta,**m,'jogador':m['jogador']+1} for m in goals],{**meta,**match}

def write_csv(path,rows):
    if not rows:return
    with path.open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]),delimiter=';');w.writeheader();w.writerows(rows)

def aggregate(players,matches,goals):
    summary=[]
    for key in sorted({(r['cenario'],r['jogadores']) for r in matches}):
        rs=[r for r in players if (r['cenario'],r['jogadores'])==key]; ms=[r for r in matches if (r['cenario'],r['jogadores'])==key]; count=len(ms); total=sum(r['total'] for r in rs)
        summary.append(dict(cenario=key[0],jogadores=key[1],partidas=count,media_turnos=round(statistics.mean(r['turnos'] for r in ms),2),media_total=round(statistics.mean(r['total'] for r in rs),2),percentual_polens=round(100*sum(r['pontos_polens'] for r in rs)/max(1,total),2),media_objetivos=round(statistics.mean(r['objetivos'] for r in rs),2),vitorias_primeiro_pct=round(100*sum(r['vitoria_fracionada'] for r in rs if r['jogador']==1)/count,2),ganhadores_menos_objetivos_pct=round(100*sum(r['vitoria_fracionada'] for r in rs if r['venceu_com_menos_objetivos'])/count,2),fim_seis_objetivos=sum(r['motivo']=='seis_objetivos' for r in ms),fim_baralho=sum(r['motivo']=='baralho' for r in ms),slots_sem_reposicao=sum(r['slots_sem_reposicao'] for r in ms),empates=sum(r['empate'] for r in ms)))
    perf=[]
    for key in sorted({(r['cenario'],r['jogadores'],r['perfil']) for r in players}):
        rs=[r for r in players if (r['cenario'],r['jogadores'],r['perfil'])==key]
        perf.append(dict(cenario=key[0],jogadores=key[1],perfil=key[2],participacoes=len(rs),vitorias_pct=round(100*sum(r['vitoria_fracionada'] for r in rs)/len(rs),2),media_total=round(statistics.mean(r['total'] for r in rs),2),media_objetivos=round(statistics.mean(r['objetivos'] for r in rs),2),media_pontos_polens=round(statistics.mean(r['pontos_polens'] for r in rs),2)))
    obj=[]
    for key in sorted({(r['cenario'],r['jogadores'],r['categoria'],r['tipo']) for r in goals}):
        rs=[r for r in goals if (r['cenario'],r['jogadores'],r['categoria'],r['tipo'])==key]; done=[r for r in rs if r['status']=='concluido']
        obj.append(dict(cenario=key[0],jogadores=key[1],categoria=key[2],tipo=key[3],pontos=rs[0]['pontos'],entregues=len(rs),concluidos=len(done),taxa_conclusao_pct=round(100*len(done)/len(rs),2),media_turnos_proprios_ate_conquista=round(statistics.mean(r['turnos_em_mao'] for r in done),2) if done else '',descartados_fase=sum(r['status']=='descartado_fase' for r in rs)))
    return summary,perf,obj

def rescore_fixed(players,bonuses):
    """Reapurar partidas do cenário atual mantendo todas as jogadas."""
    grouped=defaultdict(list)
    for r in players:
        if r['bonus_floral']==0:grouped[(r['jogadores'],r['semente'])].append(r)
    out=[]
    for (n,seed),rs in sorted(grouped.items()):
        base={r['jogador'] for r in rs if r['vitoria_fracionada']>0}
        for bonus in bonuses:
            if not bonus:continue
            scores=[r['total']+bonus*r['florais'] for r in rs]; winners={r['jogador'] for r,s in zip(rs,scores) if s==max(scores)}
            out.append(dict(jogadores=n,semente=seed,bonus_floral=bonus,ganhadores_atuais=';'.join(map(str,sorted(base))),ganhadores_recalculados=';'.join(map(str,sorted(winners))),mudou_ganhador=int(base!=winners),percentual_polens=round(100*sum(r['pontos_polens'] for r in rs)/max(1,sum(scores)),2)))
    return out

@lru_cache(maxsize=3)
def seat_patterns(n):
    names=tuple(PROFILES)
    if n<=3:return tuple(itertools.permutations(names,n))
    return tuple(sorted({p for extra in names for p in itertools.permutations(names+(extra,))}))

def seat_profiles(n,j):
    patterns=seat_patterns(n)
    return patterns[j%len(patterns)]

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--partidas',type=int,default=12,help='por quantidade de jogadores e cenário');parser.add_argument('--jogadores',nargs='+',type=int,choices=[2,3,4],default=[2,3,4]);parser.add_argument('--bonus',nargs='+',type=int,default=[0,1],help='bônus experimental por objetivo floral');parser.add_argument('--semente',type=int,default=20261126);parser.add_argument('--amostra-jogadas',type=int,default=36,help='limite de candidatos por turno; 0 = todos');parser.add_argument('--processos',type=int,default=1);parser.add_argument('--saida',type=Path,default=ROOT/'simulador'/'resultados');parser.add_argument('--perfis',choices=['mistos','equilibrados','jardineiros','coletores'],default='mistos');a=parser.parse_args()
    if a.partidas<1 or a.amostra_jogadas<0 or a.processos<1 or min(a.bonus)<0:parser.error('quantidades inválidas')
    jobs=[]; names=list(PROFILES)
    for n in a.jogadores:
        for j in range(a.partidas):
            seed=a.semente+100000*n+j
            # Rodízio de assentos; cada cenário tem as mesmas sementes e perfis.
            ps=seat_profiles(n,j) if a.perfis=='mistos' else (dict(equilibrados='equilibrado',jardineiros='jardineiro',coletores='coletor')[a.perfis],)*n
            for b in a.bonus:jobs.append((n,seed,b,ps,a.amostra_jogadas))
    a.saida.mkdir(parents=True,exist_ok=True); p,g,m=[],[],[]; t=time.monotonic()
    pool=ProcessPoolExecutor(max_workers=a.processos) if a.processos>1 else None
    try:
        for k,(pp,gg,mm) in enumerate(pool.map(simulate,jobs) if pool else map(simulate,jobs),1):
            p.extend(pp);g.extend(gg);m.append(mm)
            if k%max(1,len(jobs)//10)==0 or k==len(jobs):print(f'{k}/{len(jobs)} partidas',flush=True)
    finally:
        if pool:pool.shutdown()
    s,pr,ob=aggregate(p,m,g)
    for name,rows in [('partidas',m),('jogadores',p),('objetivos',g),('resumo',s),('perfis',pr),('frequencia_objetivos',ob),('reapurar_mesmas_jogadas',rescore_fixed(p,a.bonus))]:write_csv(a.saida/(name+'.csv'),rows)
    (a.saida/'metadados.json').write_text(json.dumps({'versao_regras':'v203','sha256_gdscript':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'parametros':vars(a)|{'saida':str(a.saida)},'total_partidas':len(m),'segundos':round(time.monotonic()-t,2),'observacao':'Simulação independente; políticas heurísticas, não IA do Godot. Assentos rotacionados; não é teste humano.'},ensure_ascii=False,indent=2),encoding='utf8')
    for r in s:print(r)

if __name__=='__main__':main()
