"""Geometria e integração estática independentes; não executa o motor Godot."""
from itertools import product
from pathlib import Path
from math import ceil
import re

def clamp(x,a,b): return max(a,min(b,x))
def overlap(a,b): return a[0]<b[0]+b[2] and b[0]<a[0]+a[2] and a[1]<b[1]+b[3] and b[1]<a[1]+a[3]
count=0
for w,h,n,slots in product([360,420,480],[820,920,1020],range(1,5),[1,3,4]):
    width=w-16; hand=clamp(width*.25,94,116); obj=width-hand-5
    gap=clamp(obj*.022,5,8); card=min(188,(obj-16-gap)/2); rows=ceil(slots/2)
    bottom=max(170,26+rows*card+(rows-1)*gap+32)
    garden=h-16-80-114-bottom-20
    score=clamp(width*.34,126,154); buy=width-score-5
    assert garden>100 and buy>100 and (114-19-3)/n>=23
    y=8+80+5+garden+5; buy_r=(8,y,buy,114); score_r=(8+buy+5,y,score,114)
    assert not overlap(buy_r,score_r) and score_r[0]+score_r[2]==w-8
    oy=y+114+5; left=8+(obj-2*card-gap)/2
    if slots in [1,3]:
        cards=[(8+(obj-card)/2,oy+26,card,card)]
        if slots==3: cards.extend([(left,oy+26+card+gap,card,card),(left+card+gap,oy+26+card+gap,card,card)])
    else: cards=[(left+i%2*(card+gap),oy+26+i//2*(card+gap),card,card) for i in range(4)]
    for i,r in enumerate(cards):
        assert r[0]>=8 and r[0]+r[2]<=8+obj and r[1]+r[3]<=oy+bottom
        assert all(not overlap(r,other) for other in cards[:i])
    if slots==3: assert cards[1][1]==cards[2][1]>cards[0][1]+card
    count+=1
s=(Path(__file__).resolve().parents[1]/'scripts/jogo/jardim.gd').read_text()
assert 'const AULA_ALTERNATIVA_INICIAL: Array = [["gamer:11:lilas:vermelha"]]' in s
assert 'area_historico = Rect2(area_compra.end.x + intervalo, topo_faixa' in s
assert 'return 3 if not aula_previa_objetivos(jogador_atual).is_empty() else 1' in s
assert '== 2:\n\t\taula_preparar_previa_objetivos(indice_jogador)' in s
assert 'dados["aula_previa_objetivos"] = exemplos' in s
assert 'draw_rect(r_previa.grow(3.0), Color("302722", 0.68))' in s
assert 'jogador.erase("aula_previa_objetivos")' in s
for name in ['melhor_objetivo_da_jogada','opcoes_florais_concluidas_na_jogada','armar_giro_objetivo','objetivo_aceita_giro','aplicar_giro_objetivo','finalizar_giro_objetivo']:
    body=s.split('func '+name+'(',1)[1].split('\nfunc ',1)[0]
    assert 'aula_previa_objetivos' not in body
print(f'OK: {count} combinações de geometria; prévias exclusivamente visuais, fases e placar conferidos estaticamente.')
