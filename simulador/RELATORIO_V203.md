# Estudo de balanceamento — v203

Total: 3996 partidas novas sem flor-prêmio. Triagem: 432 (36 por combinação, 24 candidatos); calibração: 1620 (108 por combinação, 36 candidatos); validação: 1944 (216 por combinação, 48 candidatos). As três etapas usam sementes diferentes. Empates fracionados; assentos/perfis rotacionados e sementes pareadas dentro de cada etapa. Os 1080 controles são os cenários atuais das três etapas, não os resultados históricos v201.

## Critério de design

Evitar estratégias dominantes; equilibrado pode ter vantagem moderada, jardineiro e coletor devem permanecer competitivos em 2, 3 e 4 jogadores. A participação dos pólens na pontuação não define o equilíbrio. Uma mesma tabela fixa é preferível para não gamers.

## Validação independente — taxas de vitória por participação

| Cenário | Jogadores | Jardineiro | Coletor | Equilibrado | Pólens na pontuação |
|---|---:|---:|---:|---:|---:|
| atual | 2 | 53.47% | 26.74% | 69.79% | 65.65% |
| atual | 3 | 39.58% | 21.3% | 39.12% | 65.3% |
| atual | 4 | 20.83% | 20.83% | 33.33% | 66.33% |
| menos_1 | 2 | 48.26% | 38.54% | 63.19% | 72.36% |
| menos_1 | 3 | 27.08% | 32.87% | 40.05% | 72.46% |
| menos_1 | 4 | 16.15% | 26.22% | 32.64% | 73.15% |
| seletiva_flor_menos_1 | 2 | 48.96% | 35.76% | 65.28% | 73.06% |
| seletiva_flor_menos_1 | 3 | 35.11% | 25.62% | 39.27% | 72.91% |
| seletiva_flor_menos_1 | 4 | 21.01% | 21.99% | 32.0% | 73.53% |

A tabela seletiva com -1 adicional nos florais é a candidata por modelo: preserva compensações relativas de dificuldade, reduz recompensas fáceis e substitui fórmulas por valores fixos. O cenário menos_1 é um benchmark relevante: no duelo direto jardineiro x coletor foram 50% para cada perfil (72 partidas); na seletiva, 56,9% x 43,1%. A tabela seletiva não elimina diferenças entre todos os perfis e não é superior em todos os critérios. Em 3 jogadores a vantagem do equilibrado é modesta; em 2, ainda é forte contra o coletor. As duas alternativas precisam de teste humano.

## Tabela experimental por objetivo

| Categoria | Tipo | Desenho/nome | Atual (2/3/4) | Proposta | Conclusão no controle |
|---|---:|---|---|---:|---:|
| medio | 5 | 5/6 A · 8/9 B | 3/3/3 | 2 | 51.8% (972/1876) |
| medio | 11 | 2/5 A · 4/6 B | 3/3/3 | 2 | 50.6% (1588/3139) |
| medio | 15 | 4/7 A · 6/9 B | 4/4/4 | 3 | 41.7% (838/2008) |
| medio | 17 | 2/5 A · 7/9 B | 4/4/4 | 3 | 52.0% (1647/3166) |
| medio | 19 | 2/8 A · 7/9 B | 4/4/4 | 2 | 66.3% (2117/3194) |
| medio | 23 | 4/6 A · 7/9 B | 4/4/4 | 2 | 69.6% (1236/1775) |
| dificil | 13 | 1/3 A · 7/9 B | 6/6/6 | 5 | 46.9% (206/439) |
| dificil | 14 | 1/3/8 A · 5 B | 5/5/5 | 5 | 31.5% (223/707) |
| dificil | 21 | 1/9 A · 6/8 B | 5/5/5 | 4 | 33.2% (235/708) |
| dificil | 24 | 3/7 A · 5/9 B | 5/5/5 | 4 | 30.8% (257/835) |
| dificil | 25 | 1/3/5 A · 4/6 B | 6/6/6 | 6 | 24.8% (210/846) |
| dificil | 26 | 1/3 A · 4/5/6 B | 6/6/6 | 6 | 23.5% (217/925) |
| dificil | 28 | 4/5 A · 2/6/8 B | 7/7/7 | 6 | 30.9% (288/933) |
| dificil | 29 | 3/7/9 A · 6/8 B | 7/7/7 | 5 | 32.7% (271/829) |
| dificil | 30 | 3/5/7 A · 6/8 B | 7/7/7 | 6 | 34.0% (272/799) |
| fada | 9 | FLOR PRECIOSA | 3/3/3 | 5 | 4.5% (17/375) |
| fada | 10 | TRÊS FLORES | 3/3/3 | 3 | 55.1% (194/352) |
| fada | 14 | TRÊS CORES | 4/4/4 | 3 | 56.1% (189/337) |
| fada | 25 | QUATRO FLORES | 5/5/5 | 3 | 74.8% (249/333) |
| fada | 26 | CINCO FLORES | 7/7/7 | 5 | 80.3% (297/370) |
| fada | 27 | COLETA EM QUATRO FLORES | 6/6/6 | 5 | 67.7% (235/347) |
| fada | 41 | DUAS VERMELHAS | 5/5/5 | 5 | 30.7% (124/404) |
| fada | 42 | DUAS AMARELAS | 5/5/5 | 5 | 27.1% (97/358) |
| fada | 43 | DUAS LILASES | 5/5/5 | 5 | 28.7% (105/366) |
| fada | 44 | RETA DISTANTE | 5/5/5 | 5 | 41.0% (143/349) |
| fada | 45 | RETA LONGA | 8/8/8 | 7 | 46.5% (174/374) |
| fada | 46 | DIAGONAL DISTANTE | 6/6/6 | 7 | 34.8% (123/353) |
| fada | 47 | DIAGONAL LONGA | 8/8/8 | 8 | 24.1% (83/344) |
| fada | 48 | CORES DISTANTES | 5/5/5 | 3 | 74.1% (260/351) |
| fada | 49 | EXTREMIDADES | 7/7/7 | 7 | 46.5% (167/359) |
| fada | 61 | CERCO | 7/6/5 | 6 | 36.8% (130/353) |
| fada | 63 | POUSO CONTESTADO | 4/3/2 | 3 | 0.0% (0/369) |
| fada | 64 | APROXIMAÇÃO ESTRATÉGICA | 4/3/2 | 3 | 45.5% (156/343) |
| fada | 65 | DESLOCAMENTO FORÇADO | 4/3/2 | 3 | 26.7% (100/374) |
| fada | 66 | MANOBRA COMBINADA | 6/5/4 | 5 | 45.2% (159/352) |
| fada | 67 | QUEBRA DE ALINHAMENTO | 6/7/8 | 7 | 44.0% (164/373) |
| fada | 69 | CONFRONTO DIAGONAL | 5/4/3 | 4 | 44.3% (155/350) |
| fada | 70 | INTERPOSIÇÃO | 7/6/5 | 7 | 24.9% (92/369) |

Taxa de conclusão = entregues que foram concluídos antes do fim/descarte, não probabilidade intrínseca de uma jogada nem medida direta de dificuldade. Valores fixos das fadas são testados como pacote; nenhum efeito individual foi isolado. A carta 63 esteve em todas as tabelas, inclusive a seletiva com 3 estrelas. Recomenda-se suspender/reformular separadamente: o voo sempre termina em uma nova flor (plantio ou reposição da origem, depois de transportar as fadas), logo pousar numa flor ocupada por inimiga é incompatível com o fluxo competitivo normal; 0/369 nos controles. Flor Preciosa: apenas 17/375; testar 5, investigar raridade e eventual simplificação.

## Gargalo de reposição

| Jogadores | Partidas afetadas/360 |
|---|---:|
| 2 | 14/360 (3.9%) |
| 3 | 108/360 (30.0%) |
| 4 | 257/360 (71.4%) |

A reposição é uma possível fonte de viés importante, especialmente com quatro jogadores. Não confundir indicação da simulação com ocorrência comprovada no motor. Deve ser auditada antes de concluir equilíbrio.

## Limites e próximo teste

Agentes heurísticos, não IA oficial nem pessoas; o perfil equilibrado pesa ganhos imediatos igualmente, com incentivo de 1,5 à conclusão (progresso à condição de término), e usa preparação floral. Removido o incentivo residual de 0,8 para objetivos de fada (flor-prêmio abolida). As buscas amostram jogadas e as ações/aleatoriedade podem divergir entre tabelas. Não se infere causalidade de um valor isolado a partir da taxa de conclusão. A v203 mantém a tabela oficial, regras e tutorial. Ao aprovar uma nova tabela, separar classificação por tipo de valor em estrelas nos filtros de sorteio e revisar valores fixos do tutorial, manual, catálogo, IA e apuração. Testar retirada do 63, disponibilidade de objetivos, políticas alternativas, pares de perfis, assento e partidas com pessoas não gamers antes de imprimir.
