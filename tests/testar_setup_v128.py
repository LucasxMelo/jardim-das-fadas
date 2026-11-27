"""Validação estática/exaustiva da abertura: 12 desenhos, objetivos médios e primeira jogada."""
from pathlib import Path
from itertools import permutations
import re
root=Path(__file__).resolve().parents[1]
s=(root/'scripts/jogo/jardim.gd').read_text()
base=re.findall(r'"(vermelha|amarela|lilas)"',re.search(r'const SETUP_FIXO_NOVE_FLORES: Array = \[(.*?)\]',s,re.S)[1])
assert re.search(r'var indices: Array\[int\] = \[0, 1, 2, 3, 4, 5, 6, 7, 8\]\s+if girar:\s+indices\.assign\(',s)
indices=[int(x) for x in re.search(r'indices\.assign\(\[([^]]+)\]\)',s)[1].split(',')]
assert indices==[6,3,0,7,4,1,8,5,2]
assert 'sorteador.randi_range(0, 1) == 1' in s
colors=sorted(set(base)); assert len(base)==9 and len(colors)==3
pos=[(i%3-1,i//3-1) for i in range(9)]
variants=set(); dirs=[(1,0),(-1,0),(0,1),(0,-1)]
for perm in permutations(colors):
 m=dict(zip(colors,perm))
 for order in [range(9),indices]:
  board=tuple(m[base[i]] for i in order);variants.add(board)
  assert all(board.count(c)==3 for c in colors)
  assert (board[0]==board[4]==board[8]) != (board[2]==board[4]==board[6])
assert len(variants)==12
safe=[int(i) for i in re.search(r'const TIPOS_MEDIOS_ABERTURA_SEGURA: Array = \[([^]]+)\]',s)[1].split(',')]
patterns=[]
for t in safe:
 b=re.search(r'^\t'+str(t)+r': \{(.*?)(?=^\t\},|^\t\}|^\t\d+:)',s,re.M|re.S)[1]
 coords=[pos[int(i)-1] for i in re.search(r'"quadrantes":\s*\[([^]]+)\]',b)[1].split(',')]
 labels=re.findall(r'"([AB])"',re.search(r'"padrao":\s*\[([^]]+)\]',b)[1])
 for _ in range(4):
  x0,y0=coords[0];patterns.append((t,[(x-x0,y-y0) for x,y in coords],labels));coords=[(-y,x) for x,y in coords]
def check(board):
 for t,coords,labels in patterns:
  for x,y in board:
   seen=[board.get((x+dx,y+dy)) for dx,dy in coords]
   if None in seen:continue
   a={c for c,l in zip(seen,labels) if l=='A'};b={c for c,l in zip(seen,labels) if l=='B'}
   assert not(len(a)==len(b)==1 and a!=b),(t,board)
for variant in variants:
 board=dict(zip(pos,variant));check(board)
 outside={(x+dx,y+dy) for x,y in board for dx,dy in dirs}-{*board}
 count=0
 for dest in outside:
  for c in colors:check(dict(board,**{}) | {dest:c});count+=1
 for src in board:
  if src==(0,0):continue
  for dx,dy in dirs:
   dest=(src[0]+dx,src[1]+dy)
   if dest in board:continue
   for c in colors:check(board | {dest:board[src],src:c});count+=1
 assert count==72
print('OK: 12 setups; 864 primeiras jogadas; 6 modelos médios em todas as rotações.')
