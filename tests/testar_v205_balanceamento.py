from pathlib import Path
import sys,csv
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'simulador'))
from simular import read_catalog
from calibrar_v205 import Calibration, FADA_FOCAL, pontos_controle
from simular import seat_profiles
for n in (2,3,4):
    cards,_=read_catalog(n);fa={c.kind:c for c in cards if c.category=='fada'}
    assert len(fa)==21 and 9 not in fa and 63 not in fa
    expected={61:9-n,64:6-n,65:6-n,66:8-n,67:4+n,69:7-n,70:9-n}
    g=Calibration(n,205,'focal',seat_profiles(n,0),12)
    assert all(fa[k].points==v==g.points(fa[k]) for k,v in expected.items())
    assert all(g.points(c)==pontos_controle(c)+int(c.kind in (14,25,26))==c.points for c in cards if c.category!='fada')
    assert all(g.points(c)==FADA_FOCAL.get(c.kind,pontos_controle(c))==c.points for c in fa.values())
for path,count in [('resultados_v205',432),('resultados_v205_validacao',1296)]:
    def load(f):
        with (root/'simulador'/path/(f+'.csv')).open(encoding='utf-8-sig') as stream:return list(csv.DictReader(stream,delimiter=';'))
    games=load('partidas');goals=load('objetivos');assert len(games)==count
    for m in goals:
        q=[int(m[k]) for k in ('gerados','polens_proprios','polens_rivais','polens_restantes')]
        assert min(q)>=0 and q[0]==sum(q[1:])
        assert not q[0] if m['categoria']=='fada' else int(m['tipo']) in (5,11,15,17,19,23,13,14,21,24,25,26,28,29,30)
        if m['categoria']=='fada':assert int(m['tipo']) not in (9,63)
print('OK: 21 modelos de fada, fórmulas em 2/3/4 jogadores, tabelas candidatas e rastreamento dos pólens nas 1.728 partidas.')
