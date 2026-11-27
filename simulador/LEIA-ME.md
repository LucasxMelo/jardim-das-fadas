# Simulador de balanceamento — Jardim das Fadas v207

Ferramenta experimental independente da interface Godot. A v202 remove a flor-prêmio tanto do jogo quanto do simulador; Os cenários alternativos continuam restritos ao simulador; a candidata focal da v205 foi oficializada na v207. Os CSVs em `resultados_referencia/` são históricos da v201 (com flor-prêmio); execute novas partidas para comparar a regra atual.

## Executar

Instale Python 3.10 ou superior. Nenhum pacote externo é necessário. No Windows, dê dois cliques em `executar_simulador.bat` (1080 partidas). Ou abra o terminal na pasta raiz do projeto:

```bash
python simulador/simular.py --partidas 180 --jogadores 2 3 4 --bonus 0 1 --processos 4
```

`--partidas` é o número de partidas por quantidade de jogadores e por tabela. Assim, 180 × 3 × 2 = 1080 partidas. Para 6.000 partidas: `--partidas 1000`. Para avaliar também +2 e +3, use `--bonus 0 1 2 3`. `--semente 20261126` garante repetibilidade no mesmo ambiente. `--amostra-jogadas 36` é o limite de candidatos avaliados por turno; `--amostra-jogadas 0` avalia todos. `--perfis equilibrados` usa agentes da mesma política para estudar vantagem de assento; `mistos` (padrão) alterna todas as permutações pertinentes de perfis; `jardineiros` e `coletores` também são possíveis. `--saida caminho` muda a pasta de exportação. Use sementes novas e amostra exaustiva para análise de sensibilidade.

## Como funciona

- Importa os modelos florais ativos, pontos, fórmulas de fada e setup diretamente de `scripts/jogo/jardim.gd`; deduplica rotações sem espelhamento. O bônus experimental não muda a categoria Médio/Difícil.
- Reproduz a reserva de 32 flores por cor (9 no setup), sorteio de cor inversamente proporcional à frequência no jardim, coletiva e compra oculta. O agente compara a coletiva à utilidade esperada do baralho **antes** de sortear a cor oculta. Depois da compra, escolhe plantio ou deslocamento. No deslocamento, pólens e todas as fadas acompanham a flor, e a nova carta ocupa sua origem.
- A cada turno, testa voo reto/diagonal até a nova flor, podendo atravessar casas vazias, recolher os pólens das flores visitadas ou produzir 1 quando vazias. O voo não coleta na origem. Objetivos florais só pontuam novas combinações; os 21 tipos de objetivo de fada são verificados. Uma conquista por turno. Objetivo floral gera 1 pólen em cada flor do desenho (limite 4); objetivo de fada concede somente as estrelas indicadas.
- Respeita os três objetivos médios e a fase posterior (dois difíceis e dois de fada), sem repetir tipo/classe ou par de cores na mão floral e sem distribuir carta floral já formada. Não recicla IDs; registra a falta de opções elegíveis, sem preencher à força.
- Reproduz o ciclo de rodada bônus após conquista fora de uma rodada bônus; a partida termina após alguém atingir seis objetivos e a rodada bônus acabar, ou por esgotamento do baralho e coletiva. Pontuação: 1 por pólen e +2 por trinca da mesma cor (5 pontos pela trinca); empate sem desempate por objetivos.
- Estratégias: jardineiro (peso maior para objetivo e preparação), coletor (peso maior para coleta e trincas), equilibrado (pesos iguais para ganhos imediatos). A escolha entre objetivos simultaneamente concluídos privilegia a maior pontuação, como a IA do jogo. Empates de planos dependem da ordem dos candidatos. Em combinações florais simultâneas da mesma carta, escolhe deterministicamente o menor conjunto de coordenadas; a ordem de descoberta no GDScript pode divergir.

## Arquivos CSV (separador ponto e vírgula, UTF-8 com BOM)

`partidas.csv`: quantidade de turnos totais, motivo do encerramento, empate, ganhadores, gatilho e falta de reposição de cartas.

`jogadores.csv`: assento, perfil, pontuação por fonte, reservas por cor, objetivos por classe, turnos, compras, voos, deslocamentos, vitórias. Empates dividem 1 vitória entre ganhadores para as taxas.

`objetivos.csv`: ID, classe, tipo, valor, entrega, conclusão, descarte de fase e tempo em turnos próprios. `frequencia_objetivos.csv` agrega por tipo, número de jogadores e cenário. A taxa usa todos os objetivos entregues, inclusive descartados; a média de turnos considera apenas os concluídos (viés de sobrevivência).

`resumo.csv` e `perfis.csv`: estatísticas agregadas por cenário/número de jogadores e perfil. Participação dos pólens = soma de pontos dos pólens / soma de pontos totais; não é a média dos percentuais individuais. `reapurar_mesmas_jogadas.csv`: reaplica o bônus a cada partida da tabela atual SEM alterar ações; separa o efeito aritmético do efeito comportamental da nova simulação. `metadados.json`: parâmetros e hash do GDScript de origem.

## Limitações

Não é o motor Godot, nem a IA oficial, nem um teste com seres humanos. É uma implementação independente das regras, com políticas heurísticas e busca parcial configurável. O estado do jogo não é alterado por prévias; políticas não antecipam a carta sorteada. Sementes e perfis são pareados entre tabelas, mas as sequências podem divergir conforme as ações mudam. Não valida tempo de partida real, diversão, dificuldade percebida nem equivalência exata com cada escolha da IA oficial. As faltas de reposição detectadas devem ser confirmadas no motor; são uma hipótese de auditoria, não um bug comprovado no jogo. A simulação tem um limite de segurança de 120 turnos; partidas assim encerradas são identificadas. Resultados históricos da v201 (com flor-prêmio) são 1080 partidas com 36 candidatos por turno, 180 por configuração, e 540 reapurações sem alterar jogadas. Não confundir com 1080 pares independentes. Não usar como prova de equilíbrio definitivo.

## Calibração v203 por tipo de objetivo

Execute `python simulador/calibrar.py --partidas 108 --processos 4`. Consulte `RELATORIO_V203.md` e `proposta_por_objetivo_v203.csv`. Três lotes novos: `resultados_v203_uniforme`, `resultados_v203_calibracao`, `resultados_v203_validacao`. Cada lote possui metadados e CSVs. Os valores são exclusivos da simulação; não alteram o catálogo oficial. As duas primeiras etapas foram executadas antes de remover uma constante Solo sem uso, por isso o hash de origem difere do pacote final, sem alteração do catálogo ou das regras competitivas.

## v205 — externalidades dos objetivos florais

Use `python simulador/calibrar_v205.py --partidas 108 --amostra-jogadas 48 --processos 4 --cenarios controle focal moderada seletiva --semente 205901` para novas partidas (altere `--saida` para não sobrescrever resultados existentes). A comparação preserva fórmulas e exclui dois modelos de fada. As tabelas da v203 são históricas; não comparar diretamente sem considerar essas diferenças. Consulte `RELATORIO_V205.md` e `proposta_por_objetivo_v205.csv`.


## v207 — tabela focal oficial

O catálogo do jogo agora usa exatamente a proposta da v205. `simular.py --bonus 0` utiliza a tabela oficial, sem bônus extra. `calibrar_v205.py` mantém o controle pré-v207 e as variantes anteriores, inclusive `focal` (agora equivalente à tabela oficial). Os arquivos de resultados anteriores não foram recalculados. Não confundir novas execuções com resultados históricos.
