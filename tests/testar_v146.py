"""Simulação independente dos cenários gravados no GDScript; não executa Godot."""
import re,itertools,json
from pathlib import Path
s=(Path(__file__).resolve().parents[1] / 'scripts/jogo/jardim.gd').read_text(); C=['vermelha','amarela','lilas']; D=[(1,0),(-1,0),(0,1),(0,-1)]
M=[5,11,15,17,19,23]; H=[13,14,21,24,25,26,28,29,30]; A=sorted(M+H);pos=[(i%3-1,i//3-1) for i in range(9)]
patterns={}; types={}; pairs={}; pts={}; seen=set()
for t in A:
 b=re.search(r'^\t'+str(t)+r': \{(.*?)(?=^\t\},|^\t\}|^\t\d+:)',s.split('const MODELOS_OBJETIVO: Dictionary = {',1)[1],re.M|re.S)[1]
 coords=[pos[int(i)-1] for i in re.search(r'"quadrantes":\s*\[([^]]+)\]',b)[1].split(',')]; labs=re.findall(r'"([AB])"',re.search(r'"padrao":\s*\[([^]]+)\]',b)[1]); point=int(re.search(r'"pontos":\s*(\d+)',b)[1]);
 for a,c in itertools.permutations(C,2):
  shapes=[]
  for k in range(4):
   minx=min(x for x,y in coords);miny=min(y for x,y in coords);shape=tuple(sorted((x-minx,y-miny,a if l=='A' else c) for (x,y),l in zip(coords,labs)));shapes.append(shape);coords=[(-y,x) for x,y in coords]
  sig=(t in H,min(shapes));
  if sig in seen:continue
  seen.add(sig);id=f'gamer:{t}:{a}:{c}';patterns[id]=list(set(shapes));types[id]=t;pairs[id]=frozenset([a,c]);pts[id]=point
MED=[k for k in patterns if types[k] in M]; HARD=[k for k in patterns if types[k] in H];idx={c:[] for c in C}
for k,shapes in patterns.items():
 for shape in shapes:
  for x,y,c in shape:idx[c].append((k,tuple((xx-x,yy-y,cc) for xx,yy,cc in shape)))
def matched(b,old,changed):
 out={}
 for x,y in changed:
  for k,shape in idx[b[x,y]]:
   if k in out:continue
   if all(b.get((x+dx,y+dy))==c for dx,dy,c in shape) and not all(old.get((x+dx,y+dy))==c for dx,dy,c in shape):out[k]=[(x+dx,y+dy) for dx,dy,c in shape]
 return out
# O cenário ativo é lido do código, sem importar cartas extras de versões históricas.
base=dict(zip(pos,re.findall(r'"(vermelha|amarela|lilas)"',re.search(r'const AULA_SETUP_NOVE_FLORES: Array = \[(.*?)\]',s,re.S)[1])))
def allmatches(b):return matched(b,{},b)
def options(b,f,owner,kind,carry):
 for x,y in sorted(b):
  for dx,dy in D:
   d=x+dx,y+dy
   if d in b or max(abs(d[0]),abs(d[1]))>3:continue
   if kind!='move':yield None,d
   if (x,y)!=(0,0) and kind!='plant' and (not carry or (x,y) in f[owner*2:owner*2+2]):yield (x,y),d
def paths(f,owner,src,dest,target,flt):
 ff=[dest if src is not None and p==src else p for p in f]
 for i in range(owner*2,owner*2+2):
  x,y=ff[i];dx=target[0]-x;dy=target[1]-y
  if not(dx or dy):continue
  kind='straight' if dx==0 or dy==0 else 'diag' if abs(dx)==abs(dy) else ''
  if kind and (flt is None or flt==kind):
   path=[(x+j*((dx>0)-(dx<0)),y+j*((dy>0)-(dy<0))) for j in range(1,max(abs(dx),abs(dy))+1)]
   yield i,path,ff,kind
 if flt is None:yield -1,[],ff,''
def ler_plano(alt):
 nome='ALTERNATIVA' if alt else 'ORIGINAL'
 bloco=re.search(r'const AULA_'+nome+r': Array = \[(.*?)\n\]',s,re.S)[1]
 passos=[]
 for linha in bloco.strip().splitlines():
  linha=re.sub(r'Vector2i\((-?\d+), (-?\d+)\)',r'[\1,\2]',linha.strip().rstrip(','))
  d=json.loads(linha)
  passos.append(dict(owner=d['dono'],source=d['fonte'],color=d['cor'],src=None if d['origem']==[99999,99999] else d['origem'],dest=d['destino'],fly=d['fada'],flight=d['voo'],goal=d['objetivo'],lesson=d.get('licao','')))
 inicial=json.loads(re.search(r'const AULA_'+nome+r'_INICIAL: Array = (.*)',s)[1])
 repos=re.search(r'const AULA_'+nome+r'_REPOSICOES: Dictionary = (\{.*?\n\})',s,re.S)[1]
 repos=json.loads(re.sub(r'^\s*(\d+):',r'"\1":',repos.replace(',\n}','\n}'),flags=re.M))
 return {'initial':inicial,'steps':passos,'hands':repos}
add=lambda a,b:(a[0]+b[0],a[1]+b[1])
# exact Godot rotation and anchor order
raw={}
for t in A:
 b=re.search(r'^\t'+str(t)+r': \{(.*?)(?=^\t\},|^\t\}|^\t\d+:)',s.split('const MODELOS_OBJETIVO: Dictionary = {',1)[1],re.M|re.S)[1]
 raw[t]=([pos[int(i)-1] for i in re.search(r'"quadrantes":\s*\[([^]]+)\]',b)[1].split(',')],re.findall(r'"([AB])"',re.search(r'"padrao":\s*\[([^]]+)\]',b)[1]))
def exact(id,board,old,changed):
 _,t,a,b=id.split(':');coords,labs=raw[int(t)];colors=[a if l=='A' else b for l in labs]
 for rot in range(4):
  for x,y in changed:
   for ax,ay in coords:
    cells=[(x+dx-ax,y+dy-ay) for dx,dy in coords]
    if all(board.get(p)==c for p,c in zip(cells,colors)) and not any(set(cells)==set(o) for o in old_matches(id,old,changed)):
     return cells
  coords=[(-y,x) for x,y in coords]
 return []
def old_matches(id,board,changed):
 _,t,a,b=id.split(':');coords,labs=raw[int(t)];colors=[a if l=='A' else b for l in labs];result=[]
 for rot in range(4):
  for x,y in changed:
   for ax,ay in coords:
    cells=[(x+dx-ax,y+dy-ay) for dx,dy in coords]
    if all(board.get(p)==c for p,c in zip(cells,colors)):result.append(cells)
  coords=[(-y,x) for x,y in coords]
 return result

if __name__ == "__main__":
    # Replays the public single-player lesson, with no automatic turns or rivals.
    from collections import Counter
    fixture=json.loads((Path(__file__).parent / "roteiro_historico_v146.json").read_text())
    for alt in (True,):
     data=fixture["plan"]; seq=data['steps']; assert len(data['initial'])==1
     hand=data['initial'][0]; b={(x,y):c for x,y,c in fixture["board"]}; p={q:1 for q in b};p[0,1]=2; f=[(0,0),(0,-1)]; stock=dict.fromkeys(C,0); wins=0; reward=False; first_need=None; deck=Counter({c:32 for c in C});deck.subtract(b.values());
     def open_after(i):return next((t['color'] for t in seq[i:] if t['source']=='aberta'),None)
     collective=open_after(0);deck[collective]-=1
     for i,t in enumerate(seq):
      assert t['owner']==0 and t['fly'] in (-1,0,1); assert (t['source']=='premio')==reward
      if t['source']=='aberta':assert t['color']==collective;collective=open_after(i+1);deck[collective]-=1
      else:
       if i==1:assert t['source']=='baralho' and t['color']!=collective, (alt, t['color'], collective)
       deck[t['color']]-=1
      assert all(deck[c]>=0 for c in C)
      old=b.copy();src=tuple(t['src']) if t['src'] else None; dst=tuple(t['dest']);tar=src or dst; assert dst not in b and any(add(dst,d) in b for d in D)
      if src:
       assert src!=(0,0) and src in b and abs(src[0]-dst[0])+abs(src[1]-dst[1])==1
       if t['lesson']=='preparar_coleta':assert src in f
       b[dst]=b[src];p[dst]=p[src];f=[dst if z==src else z for z in f]
      b[tar]=t['color'];p[tar]=1;seen={(0,0)};todo=[(0,0)]
      while todo:
       q=todo.pop()
       for d in D:
        z=add(q,d)
        if z in b and z not in seen:seen.add(z);todo.append(z)
      assert seen==set(b)
      fly=t['fly']; collected=[];poly=[];total=0; maxcol=0; visited=0
      eligible=[a for a,*_ in paths(f,0,None,dst,tar,None) if a>=0]
      if fly>=0:
       opt=[(path,kind) for a,path,_,kind in paths(f,0,None,dst,tar,None) if a==fly]; assert opt and opt[0][1]==t['flight'];f[fly]=tar
       for z in opt[0][0]:
        if z not in b:continue
        visited+=1
        if p[z]:collected.append(b[z]);stock[b[z]]+=p[z];total+=p[z];maxcol=max(maxcol,p[z]);p[z]=0
        else:p[z]=1;poly.append(z)
      if i==0:assert not eligible
      if i==1:assert total==4 and stock['vermelha']==stock['lilas']==2
      if i==2:assert t['flight']=='diag'
      if t['lesson']=='preparar_coleta':assert eligible and fly<0
      if t['lesson']=='coletar':assert total>=4 and not poly and not t['goal']
      if t['lesson']=='polinizar':assert len(poly)==4 and t['flight']=='straight'
      valid={};changed=[tar] if not src else [src,dst]
      for g in hand:
       if g in patterns:
        cs=exact(g,b,old,changed)
        if cs:valid[g]=cs
       elif fly>=0:
        n=int(g.split(':')[1]);a,d=f;dx,dy=d[0]-a[0],d[1]-a[1];inter=sum((a[0]+j*((dx>0)-(dx<0)),a[1]+j*((dy>0)-(dy<0))) in b for j in range(1,max(abs(dx),abs(dy)))) if (dx==0 or dy==0 or abs(dx)==abs(dy)) else -1
        cond={9:maxcol>=4,10:len(collected)>=3,26:visited>=5,41:a!=d and b[a]==b[d]=='vermelha',42:a!=d and b[a]==b[d]=='amarela',43:a!=d and b[a]==b[d]=='lilas',44:(dx==0 or dy==0) and inter>=2}.get(n,False)
        if cond:valid[g]=[]
      assert set(valid)==({t['goal']} if t['goal'] else set()),(alt,i,valid,t['goal'])
      if t['goal']:
       wins+=1
       for q in valid[t['goal']]:p[q]=min(4,p[q]+1)
       if t['goal'] in patterns and wins in (1,2):
        _,typ,a,c=t['goal'].split(':');need=Counter(a if m=='A' else c for m in raw[int(typ)][1])
        if wins==1:first_need=need
        else:assert all(stock[k]>=need[k]+first_need[k] for k in C)
       hand=data['hands'][str(i)]
      reward=t['goal'].startswith('fada:');assert wins<6 or i==len(seq)-1
     assert wins==6 and not reward and sum(t['goal'].startswith('fada:') for t in seq)==(2 if alt else 0)
     print(('Expandida' if alt else 'Original')+f': {len(seq)} jogadas humanas; seis objetivos, coleta, polinização, recompensas e estoque validados.')
    assert 'novo_modo = "aula"' in s and 'if modo_partida in ["aprender", "aprender_novo", "aula"]' in s
    assert 'if not aula_duelo:' in s
    assert len(re.findall(r'^func (\w+)\(',s,re.M))==len(set(re.findall(r'^func (\w+)\(',s,re.M)))
    print('OK: roteiro histórico de 11 jogadas, congelado como referência (não é o tutorial atual).')
