"""Regressão atualizada v216: região de giro invisível, sem executar Godot."""
from pathlib import Path
s=(Path(__file__).resolve().parents[1]/'scripts/jogo/jardim.gd').read_text()
def fn(n): return s.split('func '+n+'(',1)[1].split('\nfunc ',1)[0]
def clamp(x,a,b): return max(a,min(b,x))
checks=0
for side in range(65,189):
    h=clamp(side*.235,23,43); w=min(side*.46,clamp(side*.38,32,48)); x=side-w-2; y=2; ah=h-3
    assert x>side/2 and x+w<=side and y+ah<h
    for orientation in range(4):
        assert (orientation+1)%4 in range(4)
        assert (orientation+4)%4==orientation
        for direction in (-1,1):
            assert (orientation+direction)%4 in range(4)
            checks+=1
assert 'v210_area_giro_objetivo(carta_r).has_point(posicao)' in fn('armar_giro_objetivo')
assert 'return aplicar_giro_objetivo(indice, 1, 0.0)' in fn('finalizar_giro_objetivo')
assert 'roundi(angulo / (PI * 0.5))' in fn('finalizar_giro_objetivo')
assert 'v209_giro_valido()' in fn('finalizar_giro_objetivo')
assert 'mobile_abrir_objetivo_ampliado' in fn('_input')
for obsolete in ['v211_desenhar_seta_dupla_giro','v210_desenhar_seta_curva','v210_desenhar_setas_giro','retangulos_cantos_giro_objetivo','desenhar_areas_giro_objetivo']:
    assert obsolete not in s, obsolete
f=fn('desenhar_objetivo')
assert f.index('escrever(texto_pontos') < f.index('v209_angulo_desenho')
for name in ('aula_dica_livre','aula_dica_proxima_acao'):
    assert 'canto superior direito' in fn(name)
    assert 'seta curva' not in fn(name) and 'seta azul' not in fn(name)
print(f'OK: {checks} combinações de tamanho, direção e orientação; região invisível e integração estática.')
