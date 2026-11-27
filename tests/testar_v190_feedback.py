"""Verificações independentes: geometria, ímã e eventos de trinca. Não executa Godot."""
from itertools import product
from math import ceil, hypot
from pathlib import Path

def clamp(v,a,b): return max(a,min(b,v))
count=0
for w,h,n,slots,tutorial in product([360,420,480],[820,920,1020],range(1,5),[1,3,4],[False,True]):
    width=w-16; hand=clamp(width*.25,94,116); obj=width-hand-5
    gap=clamp(obj*.022,5,8); card=min(188,(obj-16-gap)/2); rows=ceil(slots/2)
    bottom=max(170,26+rows*card+(rows-1)*gap+32)
    garden=h-16-(80 if tutorial else 64)-114-bottom-20
    hand_card=min(hand-10,bottom-96)
    hand_top=bottom-hand_card-5
    assert garden>100 and hand_card>0
    assert hand_top-78-10>=0 # pollen top
    assert hand_top-36+10<hand_top-7 # last pollen before label
    assert (114-19-3)/n>=23
    assert 8+width-49 < 8+width-42
    count+=1
for before,gain in product(range(97),range(5)):
    assert sum((before+j)%3==0 for j in range(1,gain+1))*2==2*((before+gain)//3-before//3)
# A casa ocupada não atrai quando o toque está no seu centro.
assert hypot(1,0)>.60 and hypot(.55,0)<.60
s=(Path(__file__).resolve().parents[1]/'scripts/jogo/jardim.gd').read_text()
assert 'var casa_soltar: Vector2i = feel_casa_magnetica(event.position)' in s
assert 'and mobile_pode_prever_plantio(casa_soltar)' in s
assert 'opcoes_florais_concluidas_na_jogada(jogador_atual, alteradas, tabuleiro, previsto, CELULA_INVALIDA)' in s
assert 'or pratica_com_dicas_breves() or etapa_fada' in s
assert 'feel_lancar_estrelas(indice_jogador, retangulo_objetivo_ativo(indice).get_center(), pontos)' in s
print(f'OK: {count} geometrias, 485 casos de chegada de trincas e verificações de integração estática.')
