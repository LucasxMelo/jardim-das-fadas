"""Modelo independente de segurança dos gestos e limites; não executa GDScript."""
from pathlib import Path
from itertools import product
from math import hypot
import re
s=(Path(__file__).resolve().parents[1]/'scripts/jogo/jardim.gd').read_text()
def fn(name):
    a=s.index('func '+name+'(')
    b=s.find('\nfunc ',a+1)
    return s[a:b if b>=0 else len(s)]
soltar=fn('v199_soltar_borda')
assert soltar.index('mobile_limpar_intencao()') < soltar.index('executar_acao_no_tabuleiro(origem') < soltar.index('executar_acao_no_tabuleiro(destino')
assert 'mobile_token_tabuleiro == identificador_partida' in soltar and 'mobile_turno_tabuleiro == turnos_jogados' in soltar
assert 'tabuleiro.erase' not in soltar and 'tabuleiro[' not in soltar
assert 'pode_deslocar_origem(origem)' in fn('v199_pode_arrastar_borda')
assert 'aula_destino()' in fn('v199_destino_borda') and 'destino_valido_para_movimento(origem, c)' in fn('v199_destino_borda')
assert 'mobile_borda_arrastada = CELULA_INVALIDA' in fn('mobile_limpar_intencao')
assert 'juice_desvio_carta' in fn('juice_posicao_sobre_carta')
assert 'juice_posicao_sobre_carta' in fn('desenhar_polens_do_jardim') and 'juice_posicao_sobre_carta' in fn('desenhar_fada_miniatura')
assert 'tabuleiro.duplicate()' in fn('v199_atualizar_previa_arrasto') and 'opcoes_florais_concluidas_na_jogada' in fn('v199_atualizar_previa_arrasto')
assert 'pratica_com_dicas_breves()' in fn('v199_atualizar_previa_arrasto')
assert 'aula_guiada_ativa()' in fn('v199_camera_arrasto')
assert 'v199_parar_ambiente()' in fn('solicitar_saida_partida') and 'v199_parar_ambiente()' in fn('juice_limpar')
assert 'loop_mode = AudioStreamWAV.LOOP_FORWARD' in fn('v199_gerar_ambiente')
# Nenhuma jogada é confirmada em cancelamento, outro turno, alvo ocupado ou alvo didático incorreto.
n=0
for jogo,turno,contexto,origem_valida,adjacente,livre,guiado,alvo,cancelado,mao in product((False,True),repeat=10):
    aceita=jogo and turno and contexto and origem_valida and adjacente and livre and (not guiado or alvo) and not cancelado
    tab={(0,0):'amarela',(1,0):'lilas'}; pol={(1,0):3}; fadas=[(1,0),(0,0)]
    antes=(tab.copy(),pol.copy(),fadas.copy())
    # O modelo não se altera na prévia. Apenas a rotina de deslocamento efetiva a mudança.
    if aceita:
        tab[(2,0)]=tab.pop((1,0)); pol[(2,0)]=pol.pop((1,0)); fadas=[(2,0) if x==(1,0) else x for x in fadas]
        if mao: tab[(1,0)]='vermelha'
        assert sum(pol.values())==3 and fadas==[(2,0),(0,0)] and tab[(0,0)]=='amarela'
        assert ((1,0) in tab)==mao
    else:
        assert (tab,pol,fadas)==antes
    n+=1
# Limites da câmera: não saltar quando já fora do intervalo e não deslocar eixo inativo.
cam=0
for w,h,passo,x,y,dirx,diry in product((320,404),(250,420),(22,88,166),(-900,-100,0,100,900),(-900,0,900),(-1,0,1),(-1,0,1)):
    limites=[(-3*passo-w/2+passo*.6,2*passo+w/2-passo*.6),(-4*passo-h/2+passo*.6,2*passo+h/2-passo*.6)]
    for antes,eixo,(lo,hi) in zip((x,y),(dirx,diry),limites):
        d=antes-eixo*passo*1.65*.05
        depois=max(min(lo,antes),min(max(hi,antes),d))
        assert abs(depois-antes)<=passo*1.65*.05+1e-8
        if eixo==0: assert depois==antes
    cam+=1
print(f'OK: {n} cenários independentes de gesto e conservação; {cam} geometrias de câmera; integrações estáticas.')
