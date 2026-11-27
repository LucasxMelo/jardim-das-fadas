from pathlib import Path
import csv,sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'simulador'))
from simular import read_catalog, Game, score, seat_profiles
from calibrar_v205 import Calibration, pontos_controle
with (root/'simulador/proposta_por_objetivo_v205.csv').open(encoding='utf-8-sig') as f:
    rows=list(csv.DictReader(f,delimiter=';'))
assert len(rows)==36
for n in (2,3,4):
    cards,_=read_catalog(n)
    oficial=Game(n,207,0,seat_profiles(n,0),12)
    controle=Calibration(n,207,'controle',seat_profiles(n,0),12)
    focal=Calibration(n,207,'focal',seat_profiles(n,0),12)
    lookup={(r['categoria'],int(r['tipo'])):r for r in rows}
    assert {(c.category,c.kind) for c in cards}==set(lookup)
    for c in cards:
        row=lookup[c.category,c.kind]
        def value(k):
            parts=row[k].split('/')
            return int(parts[n-2] if len(parts)>1 else parts[0])
        assert c.points==value('proposta')==oficial.points(c)==focal.points(c),(n,c)
        assert controle.points(c)==pontos_controle(c)==value('atual'),(n,c)
    assert 9 not in {c.kind for c in cards if c.category=='fada'}
    assert 63 not in {c.kind for c in cards if c.category=='fada'}
assert score([1,0,0])==1 and score([3,0,0])==5 and score([6,0,0])==10
s=(root/'scripts/jogo/jardim.gd').read_text()
assert 'if faixa_pontos == 46 and int(objetivo["tipo"]) not in TIPOS_MEDIOS_ABERTURA_SEGURA:' in s
assert 'if faixa_pontos == 78 and int(objetivo["tipo"]) not in TIPOS_DIFICEIS_ATIVOS:' in s
print('OK: 36 modelos × 3 quantidades de jogadores; catálogo oficial, fórmulas, controle histórico e candidata focal sincronizados.')
