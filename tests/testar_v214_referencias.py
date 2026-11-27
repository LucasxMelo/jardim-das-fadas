"""Regressão estática: nomes dos estados e funções de interação declarados.
Não substitui o compilador Godot.
"""
from pathlib import Path
import re
s = (Path(__file__).resolve().parents[1] / 'scripts/jogo/jardim.gd').read_text(encoding='utf-8')
assert re.search(r'^var feel_previsao_ids: Dictionary\s*=\s*\{\}', s, re.M)
f = s.split('func v209_desenhar_encaixe()', 1)[1].split('\nfunc ', 1)[0]
assert 'not feel_previsao_ids.is_empty()' in f
assert not re.search(r'\bfeel_previa_ids\b', s)
# Remover strings e comentários, incluindo strings multilinha do áudio web.
limpo = re.sub(r'"""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\'|"(?:\\.|[^"\\\n])*"|\'(?:\\.|[^\'\\\n])*\'|#[^\n]*', ' ', s)
nomes = set(re.findall(r'\b(?:feel_|v20[0-9]_|v21[0-9]_|mobile_|juice_|aula_|perf_)[a-zA-Z_0-9]+\b', limpo))
declarados = set(re.findall(r'\b(?:var|const|func|signal)\s+(\w+)', limpo))
assert nomes <= declarados, sorted(nomes - declarados)
print(f'OK: referência de encaixe corrigida; {len(nomes)} identificadores de interação conferidos por declaração textual.')
