"""Simulação independente da abertura e das alternativas da quarta jogada.
Não executa o Godot. Usa o catálogo/roteiro extraídos pelo teste de referência.
"""
from testar_v146 import C, D, add, base, ler_plano, exact, paths, old_matches, s
from collections import Counter
import re

def connected(b):
    visited={(0,0)}; pending=[(0,0)]
    while pending:
        p=pending.pop()
        for d in D:
            q=add(p,d)
            if q in b and q not in visited:
                visited.add(q); pending.append(q)
    return visited==set(b)

def fly(b,p,f,idx,target):
    if idx<0: return (0,0)
    choices=[route for i,route,_,_ in paths(f,0,None,target,target,None) if i==idx]
    assert choices
    collected=produced=0
    for cell in choices[0]:
        if cell not in b: continue
        if p[cell]: collected+=p[cell];p[cell]=0
        else: p[cell]=1;produced+=1
    f[idx]=target
    return collected,produced

data=ler_plano(True); b=base.copy(); p={q:1 for q in b}
f=[tuple(map(int, pair)) for pair in re.findall(r'Vector2i\((-?\d+), (-?\d+)\)',s.split('const AULA_FADAS_INICIAIS:',1)[1].splitlines()[0])]
assert len(b)==9 and Counter(b.values())==Counter(dict.fromkeys(C,3))
assert len(f)==2 and all(cell in b for cell in f)
assert len(data['steps'])==4 and len(data['initial'][0])==1
first=data['initial'][0][0]; second=data['hands']['0'][0]
assert not old_matches(first,b,list(b))
assert not old_matches(second,{**b,(0,-2):"lilas"},list(b)+[(0,-2)])
assert 'AULA_SETUP_EXTRA' not in s
assert 'for cor in AULA_SETUP_NOVE_FLORES:' in s
assert 'AULA_FADAS_INICIAIS[numero] if aula_duelo' in s
assert 'polens_por_casa[Vector2i(0, 1)] = 2' not in s
assert data['steps'][0]['dest']==[0,-2] and data['steps'][0]['source']=='aberta'
assert data['steps'][0]['color']=='lilas' and data['steps'][0]['goal']==first
assert data['steps'][1]['source']==data['steps'][2]['source']=='baralho'
assert data['steps'][1]['color']!=data['steps'][3]['color']
for i,step in enumerate(data['steps'][:3]):
    old=b.copy();target=tuple(step['dest'])
    assert target not in b and any(add(target,d) in b for d in D)
    b[target]=step['color'];p[target]=1
    eligible=[(idx,route,kind) for idx,route,_,kind in paths(f,0,None,target,target,None) if idx>=0]
    if i==0:
        assert not eligible
    else:
        route=next(route for idx,route,kind in eligible if idx==step['fly'] and kind==step['flight'])
        if i==1:
            assert Counter({c:sum(p[z] for z in route if b.get(z)==c) for c in C})==Counter({'vermelha':2,'lilas':2,'amarela':0})
        assert not exact(second,b,old,[target])
    collected,produced=fly(b,p,f,step['fly'],target)
    if i==1: assert (collected,produced)==(4,0)
    if i==2: assert (collected,produced)==(2,1)
    if step['goal']:
        cells=exact(step['goal'],b,old,[target]);assert set(cells)=={(0,-2),(0,-1),(-1,-1),(1,-1)}
        for cell in cells:p[cell]=min(4,p[cell]+1)
    assert connected(b)
assert connected(b)
# Every possible color from the fourth purchase, both fly/no fly branches.
step=data['steps'][3];origin=tuple(step['src']);destination=tuple(step['dest']);branches=0
assert origin in b and origin in f and destination not in b and abs(origin[0]-destination[0])+abs(origin[1]-destination[1])==1
for color in C:
    bb=b.copy();pp=p.copy();ff=f.copy();bb[destination]=bb[origin];pp[destination]=pp[origin];bb[origin]=color;pp[origin]=1
    ff=[destination if x==origin else x for x in ff]
    assert connected(bb)
    for idx,route,_,_ in paths(ff,0,None,destination,origin,None):
        branch_p=pp.copy();branch_f=ff.copy();before=sum(branch_p.values())
        collected,produced=fly(bb,branch_p,branch_f,idx,origin)
        assert sum(branch_p.values())==before-collected+produced
        assert all(0<=v<=4 for v in branch_p.values())
        assert branch_f==ff if idx<0 else branch_f[idx]==origin
        branches+=1
# Independently check that direct/move hint candidates do not mutate live board.
old_b=b.copy(); old_p=p.copy(); old_f=f.copy(); goal=data['hands']['0'][0]; direct=move=0
for color in C:
    for src in b:
        for d in D:
            dst=add(src,d)
            if dst in b: continue
            new=b.copy();new[dst]=color
            if exact(goal,new,b,[dst]): direct+=1;assert connected(new)
            if src==(0,0): continue
            new=b.copy();new[dst]=b[src];new[src]=color
            if exact(goal,new,b,[src,dst]):move+=1;assert connected(new)
assert (b,p,f)==(old_b,old_p,old_f)
print(f'v176: {branches} ramificações da quarta jogada (3 cores, voos legais e recusa); conservação dos pólens e conexão OK.')
print(f'Busca de dica: {direct} plantios e {move} deslocamentos compatíveis no cenário estudado, sem mutação da mesa.')

# Caso positivo da abertura: primeira flor lilás resolve o objetivo didático.
primeira=data['steps'][0]; origem0=tuple(primeira['dest']); estado0=base.copy(); estado0[origem0]=primeira['color']
assert exact(primeira['goal'],estado0,base,[origem0])
# Caso positivo na prática: depois da quarta reposição vermelha, existe deslocamento pontuável.
board=b.copy();board[destination]=board[origin];board[origin]='vermelha';found=0
for color in C:
    for src in board:
        if src==(0,0): continue
        for d in D:
            dst=add(src,d)
            if dst in board: continue
            after=board.copy();after[dst]=board[src];after[src]=color
            if exact(goal,after,board,[src,dst]):
                assert connected(after);found+=1
assert found>0
print(f'Casos positivos: plantio inicial e {found} deslocamentos após a quarta reposição vermelha.')

# Enquadramento inicial real da v191/v192, no viewport lógico do projeto.
# A largura era limitada pelo cenário antigo de sete colunas.
import json
from pathlib import Path
fixture=json.loads((Path(__file__).parent/'roteiro_historico_v146.json').read_text())
previous={(x,y) for x,y,_ in fixture['board']} | {tuple(fixture['plan']['steps'][0]['dest'])}
current=set(base) | {tuple(data['steps'][0]['dest'])}
width,height=420-16,920-16-80-114-20
obj=width-min(116,max(94,width*.25))-5
card=(obj-16-min(8,max(5,obj*.022)))/2
garden=height-max(170,26+card+32)
nominal=min(88,(garden-12)/3.5,(width-20)/4)
def fitted(cells):
    sx=max(x for x,y in cells)-min(x for x,y in cells)+1.4
    sy=max(y for x,y in cells)-min(y for x,y in cells)+1.4
    return nominal*min(1,(width-20)/(sx*nominal),(garden-16)/(sy*nominal))
assert fitted(current)==88 and fitted(current)>fitted(previous)
print(f'Enquadramento nominal inicial: {fitted(previous):.1f} → {fitted(current):.1f} pixels lógicos por carta.')
