"""Modelo independente do compromisso de compra; verificações estáticas dos pontos de integração."""
from pathlib import Path
from itertools import product
s=(Path(__file__).resolve().parents[1]/'scripts/jogo/jardim.gd').read_text()
start=s.index('func mobile_soltar_coletiva_arrastada(')
end=s.index('func mobile_soltar_compra(',start)
soltar=s[start:end]
assert soltar.count('escolher_carta(true, true)')==1
assert soltar.index('mobile_limpar_intencao()') < soltar.index('escolher_carta(true, true)') < soltar.index('executar_acao_no_tabuleiro(')
assert 'mobile_pode_prever_plantio(casa)' in soltar and 'feel_retorno = ' in soltar
assert 'mobile_arrastando_coletiva = false' in s[s.index('func mobile_limpar_intencao'):s.index('func _notification')]
assert 'c == aula_destino()' in s[s.index('func mobile_pode_prever_plantio'):s.index('func mobile_area_fonte')]
assert 'if arrasto_direto:' in s[s.index('func escolher_carta'):s.index('func colocar_carta')]
assert 'event.position.distance_to(mobile_inicio_compra) > 11.0' in s
assert 'if mobile_arrastando_coletiva:' in s[s.index('func mobile_soltar_compra'):s.index('func _input')]
n=0
for mesmo_turno, mesmo_jogo, livre, fonte, gesto_cancelado, legal, tutorial, alvo in product([False,True], repeat=8):
    confirma=mesmo_turno and mesmo_jogo and livre and fonte and not gesto_cancelado
    planta=confirma and legal and (not tutorial or alvo)
    coletiva=0 if confirma else int(fonte)
    mao=int(confirma and not planta)
    mesa=int(planta)
    assert coletiva+mao+mesa==int(fonte)
    assert not planta or confirma
    if gesto_cancelado or not mesmo_turno or not mesmo_jogo: assert mao==mesa==0
    if tutorial and not alvo: assert mesa==0
    if confirma and not planta: assert mao==1 and coletiva==0
    n+=1
print(f'OK: {n} combinações independentes de compra/soltura; verificações estáticas de integração.')
