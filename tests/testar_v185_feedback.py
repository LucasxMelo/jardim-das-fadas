"""Verificação independente da aritmética de feedback, não executa GDScript."""
from itertools import product
from pathlib import Path

def bonus(antes, ganho):
    return 2 * ((antes + ganho)//3 - antes//3)

def total(reserva):
    return sum(n+2*(n//3) for n in reserva.values())

casos=0
for valores in product(range(9), repeat=3):
    inicial=dict(zip('val', valores))
    for ganhos in product(range(5), repeat=3):
        copia=inicial.copy()
        incremento=0
        for cor, n in zip('val', ganhos):
            incremento+=n+bonus(copia[cor], n)
            copia[cor]+=n
        assert incremento==total(copia)-total(inicial)
        assert tuple(inicial.values())==valores
        casos+=1
s=(Path(__file__).resolve().parents[1]/'scripts/jogo/jardim.gd').read_text()
assert 'juice_bonus_trincas(primeiro_polen, quantidade)' in s
assert 'reserva: Dictionary = jogadores[dono]["polens"].duplicate()' in s
assert 'bonus += juice_bonus_trincas(antes, quantidade)' in s
assert 'juice_registrar_ganho(indice_jogador, pontos, 0)' in s
print(f'OK: {casos} combinações independentes de reserva e coleta; previsão e ganho equivalentes, reserva preservada.')
