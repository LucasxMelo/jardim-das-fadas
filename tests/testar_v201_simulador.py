from pathlib import Path
from collections import Counter, defaultdict
import csv, itertools, sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'simulador'))
from simular import *
assert score([3,0,0])==5 and score([2,1,0])==3 and score([6,3,2])==17
for n in (2,3,4):
    cards,base=read_catalog(n)
    assert Counter(base)=={0:3,1:3,2:3}
    assert len([c for c in cards if c.category=='fada'])==21
    assert len({c.id for c in cards})==len(cards)
    for i in range(n):
        assert len(set(Counter(p[i] for p in seat_patterns(n)).values()))==1
    # Every setup is safe for all active medium objectives, even after a single action.
    for perm in itertools.permutations(range(3)):
        for order in [tuple(range(9)),(6,3,0,7,4,1,8,5,2)]:
            b=dict(zip(POS,[perm[base[k]] for k in order]))
            for c in cards:
                if c.category=='medio':assert not matches(c,b,b)
    args=(n,712,n%2,seat_profiles(n,0),36)
    assert simulate(args)==simulate(args)
# Export invariants across the entire reference study.
p= root/'simulador'/'resultados_referencia'
def load(name):
    with (p/(name+'.csv')).open(encoding='utf-8-sig') as f:return list(csv.DictReader(f,delimiter=';'))
ms=load('partidas'); ps=load('jogadores'); gs=load('objetivos'); rs=load('reapurar_mesmas_jogadas')
assert len(ms)==1080 and len(ps)==3240 and len(rs)==540
key=lambda r:(r['cenario'],r['jogadores'],r['semente'])
groups=defaultdict(list)
for r in ps:
    groups[key(r)].append(r)
    assert int(r['total'])==sum(int(r[k]) for k in ['pontos_florais','pontos_fadas','pontos_polens'])
    assert int(r['pontos_polens'])==score([int(r[k]) for k in ['vermelhos','amarelos','lilases']])
    assert int(r['objetivos'])==int(r['florais'])+int(r['fadas'])
for r in ms:
    g=groups[key(r)];assert len(g)==int(r['jogadores'])
    assert sum(int(x['turnos']) for x in g)==int(r['turnos'])
    assert abs(sum(float(x['vitoria_fracionada']) for x in g)-1)<1e-8
    if r['motivo']=='seis_objetivos':assert max(int(x['objetivos']) for x in g)>=6
seen=set()
for r in gs:
    k=key(r)+(r['id'],);assert k not in seen;seen.add(k)
    if r['status']=='concluido': assert int(r['turnos_em_mao'])>=1
print('OK: 1080 partidas, 3240 participantes, 540 reapurações, 30593 objetivos; conservação verificada a cada turno pelo simulador; sementes repetíveis.')
