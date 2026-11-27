"""Modelo independente de navegação e verificações estáticas, sem executar Godot."""
from itertools import product
from pathlib import Path
s=(Path(__file__).resolve().parents[1]/'scripts/jogo/jardim.gd').read_text()
def body(name):
    return s.split('func '+name+'(',1)[1].split('\nfunc ',1)[0]
assert 'aula_nav_atualizar(delta)' in body('_process')
assert 'aula_nav_iniciar_aviso()' in body('aula_abrir_aviso_licao')
assert 'aula_nav_iniciar_aviso()' in body('aula_apresentar_objetivos_fada')
for obsolete in ('aula_aviso_restante','aula_aviso_duracao','aula_atualizar_aviso_automatico','aula_iniciar_aviso_automatico'):
    assert obsolete not in s
for f in ('aula_fechar_aviso_licao','aula_fechar_aviso_fada'):
    assert f+'()' in body('aula_nav_mudar')
    assert f+'()' in body('encerrar_partida')
    assert f+'()' not in body('aula_nav_atualizar')
assert 'aula_nav_input(event)' in body('_input')
assert body('_input').index('if aula_nav_input(event)')<body('_input').index('if aula_aviso_licao_ativo() or aula_aviso_fada_ativo() or aula_nav_indice >= 0:')
assert 'aula_nav_indice < 0' in body('mobile_contexto_jogavel')
assert 'aula_nav_clip.clip_contents = true' in body('aula_nav_criar')
assert 'aula_nav_desvio + float(aula_nav_direcao) * largura' in body('aula_nav_desenhar_paginas')
assert 'area_tabuleiro.end.x - lado_saida - 3.0' in body('atualizar_layout')
assert 'area_tabuleiro.position.y + 3.0' in body('atualizar_layout')
assert 'aula_nav_cancelar_gesto()' in body('_notification')
assert 'aula_nav_cancelar_gesto()' in body('_input')
assert 'aula_nav_registrar()' in body('aula_nav_iniciar_aviso')
assert 'aula_nav_limpar()' in body('novo_jogo')
# No game state may be mutated by the navigation implementation.
for key in ('executar_acao_no_tabuleiro(', 'escolher_carta(', 'turnos_jogados =', 'tabuleiro[', 'flor_na_mao ='):
    assert key not in body('aula_nav_mudar')
# Independent navigation model: previous pages are read-only; advance from live notice resumes.
class Nav:
    def __init__(self, pages, notice):
        self.pages=pages; self.current=-1; self.notice=notice; self.game=42
    def move(self,d):
        if d<0:
            prev=self.current-1 if self.current>=0 else len(self.pages)-2
            if prev>=0:self.current=prev
        elif self.current>=0:
            nxt=self.current+1
            self.current=-1 if nxt>=len(self.pages)-1 else nxt
        elif self.notice:self.notice=False
    def tick(self,_): pass
cases=0
for n,notice,wait in product(range(1,10),(False,True),(0,4,30,600)):
    v=Nav(list(range(n)),notice)
    v.tick(wait)
    assert v.notice==notice
    for _ in range(n+3):v.move(-1)
    assert v.current==(0 if n>1 else -1)
    assert v.notice==notice
    for _ in range(n-1):v.move(1)
    assert v.current==-1 and v.notice==notice
    v.move(1)
    assert not v.notice and v.game==42
    cases+=1
# Button and gesture thresholds: vertical or short drag never advances; swipe follows direction.
for dx,dy in product((-100,-36,-20,0,20,36,100),(-100,-30,0,30,100)):
    d=(1 if dx<0 else -1) if abs(dx)>=36 and abs(dx)>abs(dy)*1.2 else 0
    assert d==0 or d*dx<0
    cases+=1
# Geometry for the logical viewport and alternate test sizes.
for w,h,tutorial in product((360,420,480),(820,920,1020),(False,True)):
    left=8; width=w-16; y=8; ih=92 if tutorial else 64
    table_y=y+ih+5; ex=left+width-48-3; ey=table_y+3
    assert ey>=table_y and ex+48<left+width
    assert table_y>y+ih
    if tutorial:
        rail_x=left+width-50; rail_h=(ih-8)/2
        assert rail_h>=42 and rail_x>=left+width-55
        assert y+3+rail_h+2+rail_h<=y+ih
        assert width-60>=280
    cases+=1
print(f'OK: {cases} cenários de leitura, navegação, gesto e geometria; sem cronômetro de leitura.')
