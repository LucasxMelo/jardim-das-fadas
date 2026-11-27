from pathlib import Path
import math, sys
root=Path(__file__).resolve().parents[1]
s=(root/'scripts/jogo/jardim.gd').read_text()
for obsolete in ['escolha_estrategica','flores_premio','premio_flor','"premio"','flor de recompensa']:
    assert obsolete not in s, obsolete
# A única rota de voo não dispara/reinicia o canal de áudio em cada coleta.
flight=s.split('func movimentar_fada_passo_a_passo(',1)[1].split('\nfunc ',1)[0]
assert flight.count('"viajar"')==1 and flight.count('parar_audio_voo()')==1
assert 'for passo in range(numero_passos):' in flight
assert flight.index('parar_audio_voo()')>flight.index('"pousar"')
loop=s.split('func gerar_loop_asas_continuas()',1)[1].split('\nfunc ',1)[0]
assert '2 * TAXA_AMOSTRAGEM_AUDIO' in loop and 't * 8.0' in loop
assert 'AudioStreamWAV.LOOP_FORWARD' in loop and 'wav.loop_end = quantidade' in loop
assert '(ruido_filtrado * 0.68 + fibra * 0.38)' in loop
# Modelo independente do envelope: 16 pulsos, espaçamento regular e emenda contínua.
def envelope(t):
    phase=t*8; beat=math.floor(phase); d=phase%1-.5
    strong,near=(.93,.76) if beat%2==0 else (.76,.93)
    g=lambda d:math.exp(-2*(d/.39)**2)
    return .1+.85*(strong*g(d)+near*(g(d-1)+g(d+1)))
assert abs(envelope(0)-envelope(2))<1e-10
assert abs(envelope(2-1/22050)-envelope(0))<.001
for i in range(16):
    a=i/8; center=a+.0625
    assert envelope(center)>envelope(a)*3 and envelope(center)>envelope(a+.125)*3
# Simulações atuais: toda jogada consome uma carta por uma das duas fontes.
sys.path.insert(0,str(root/'simulador'))
from simular import simulate,seat_profiles
fairy_goals=0
for n in (2,3,4):
    for bonus in (0,1):
        players,_,match=simulate((n,2026026+n,bonus,seat_profiles(n,0),36))
        for p in players:
            assert p['compras_baralho']+p['compras_coletiva']==p['turnos']
            assert p['pontos_fadas']>=0 and 'premios' not in p
            fairy_goals+=p['fadas']
assert fairy_goals>0
print(f'OK: 16 batidas regulares, emenda do envelope, 6 partidas atuais e {fairy_goals} objetivos de fada sem flor-prêmio.')
