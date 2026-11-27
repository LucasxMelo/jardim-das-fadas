"""Modelos independentes e verificações de integração estática; não executa Godot."""
from pathlib import Path
from math import pi, sin, cos, floor, isclose
from itertools import product
from PIL import Image, ImageChops
import re
root=Path(__file__).resolve().parents[1]
s=(root/'scripts/jogo/jardim.gd').read_text()
def fn(name):
    return s.split('func '+name+'(',1)[1].split('\nfunc ',1)[0]
# Gesto acumula incremento angular sem saltar na fronteira ±pi; encaixa nos dois sentidos.
def wrap(a):return (a+pi)%(2*pi)-pi
def snap(a):return (1 if a>=0 else -1)*floor(abs(a)/(pi/2)+.5)
num=0
for start,delta,steps in product(range(-180,180,15),range(-360,361,15),[1,4,12]):
    prev=start*pi/180; acc=0
    for k in range(1,steps+1):
        cur=wrap((start+delta*k/steps)*pi/180)
        acc=max(-2*pi,min(2*pi,acc+wrap(cur-prev)));prev=cur
    if abs(delta)/steps>=180:continue
    assert isclose(acc,delta*pi/180,abs_tol=1e-9)
    n=snap(acc);res=acc-n*pi/2
    assert abs(res)<=pi/4+1e-9
    num+=1
assert 'passos' in fn('aplicar_giro_objetivo') and 'posmod(' in fn('aplicar_giro_objetivo')
assert 'v209_giro_valido()' in fn('finalizar_giro_objetivo') and 'aplicar_giro_objetivo' in fn('finalizar_giro_objetivo') and 'mobile_abrir_objetivo_ampliado' in fn('_input')
assert 'mobile_objetivo_giro_indice = -1' in fn('mobile_limpar_intencao')
assert 'v209_angulo_desenho' in fn('desenhar_objetivo') and 'v209_geometrias' in fn('desenhar_objetivo')
assert fn('desenhar_objetivo').index('escrever(texto_pontos') < fn('desenhar_objetivo').index('v209_angulo_desenho')
# Cache de fronteira: deduplicar não muda o conjunto de destinos permitidos.
dirs=[(0,1),(1,0),(0,-1),(-1,0)]
for bits in range(1,512):
    board={(i%3,i//3) for i in range(9) if bits>>i&1}
    old={(x+dx,y+dy) for x,y in board for dx,dy in dirs if (x+dx,y+dy) not in board}
    new=[];seen=set()
    for x,y in board:
        for dx,dy in dirs:
            c=x+dx,y+dy
            if c not in seen and c not in board:seen.add(c);new.append(c)
    assert set(new)==old and len(new)==len(old)
    # fatias processam todos os candidatos exatamente uma vez.
    for chunk in [1,2,5,20]:
        out=[];cursor=0
        while cursor<len(new):out.extend(new[cursor:cursor+chunk]);cursor+=chunk
        assert out==new
assert 'Time.get_ticks_usec() - inicio' in fn('feel_atualizar_previsao') and 'tabuleiro.duplicate()' in fn('feel_atualizar_previsao')
assert 'pratica_com_dicas_breves()' in fn('feel_atualizar_previsao')
assert 'opcoes_florais_concluidas_na_jogada' in fn('feel_atualizar_previsao')
assert 'pode_colocar(c)' in fn('v209_casas_candidatas')
assert 'v209_retorno_borda' in fn('juice_desvio_carta') and 'v209_retorno_borda' in fn('juice_inclinacao_carta') and 'v209_retorno_borda' in fn('juice_escala_carta')
assert fn('v199_soltar_borda').index('if not valido:')<fn('v199_soltar_borda').index('executar_acao_no_tabuleiro')
# Máscaras pré-geradas são pixel a pixel idênticas ao algoritmo original.
for cor in ['preta','branca','cinza','marrom']:
    im=Image.open(root/f'assets/fadas/fada_{cor}.png').convert('RGBA')
    a=im.getchannel('A').point(lambda v:v if v>=24 else 0)
    mask=Image.open(root/f'assets/cache_visual/halo_fada_{cor}.png').convert('RGBA')
    assert mask.size==im.size and not ImageChops.difference(a,mask.getchannel('A')).getbbox()
    assert all(mask.getchannel(c).getextrema()==(255,255) for c in 'RGB')
    assert f'preload("res://assets/cache_visual/halo_fada_{cor}.png")' in s
# Política de qualidade só muda detalhe visual e tamanho da fatia; renderer/threads adequados à Web.
assert 'OS.has_feature("web")' in fn('v209_atualizar_qualidade') and 'mobile_tem_toque()' in fn('v209_atualizar_qualidade')
assert 'v209_lento >= 2' in fn('v209_atualizar_qualidade') and 'v209_rapido >= 8' in fn('v209_atualizar_qualidade')
assert 'draw_texture_rect_region' in fn('desenhar_carta')
assert 'variant/thread_support=false' in (root/'export_presets.cfg').read_text()
assert 'simulador/*' in (root/'export_presets.cfg').read_text()
assert 'gl_compatibility' in (root/'project.godot').read_text()
assert 'run/max_fps=60' in (root/'project.godot').read_text()
print(f'OK: {num} trajetórias angulares; 511 fronteiras × 4 fatias; 892080 pixels de máscaras; cache, encaixe, retorno e preset Web.')
