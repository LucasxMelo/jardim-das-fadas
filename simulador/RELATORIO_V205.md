# Jardim das Fadas — v205 | Externalidades dos objetivos e balanceamento

## Decisões oficiais
- Retirados do catálogo e dos verificadores Flor Preciosa (9) e Pouso Contestado (63). Restam 15 modelos florais e 21 de fada.
- Fórmulas dos sete objetivos de adversários mantidas: X−N, exceto Quebra de Alinhamento (X+N); cartas na partida mostram apenas o total calculado.
- Pontuação oficial restante e regras preservadas. Nenhuma tabela experimental aplicada ao jogo.

## Método
432 partidas de triagem (36 por cenário e N, 36 candidatos de jogada), mais 1.296 de segunda rodada (108 por cenário e N, 48 candidatos); sementes 205101 e 205901, acrescidas de N×100000 e índice. 1.728 partidas no total. Perfis mistos com assentos contrabalanceados. A alternativa focal foi formulada após a triagem, e testada na segunda rodada; não é uma validação independente posterior à sua seleção. O simulador usa agentes heurísticos, não a IA oficial nem seres humanos. As restrições de reposição continuam em vigor.

A origem de cada pólen gerado por um objetivo floral é registrada, acompanhando a flor quando deslocada. Atribuição FIFO por flor: no instante da coleta, cada pólen recebe seu valor marginal (1 ou 3 quando completa a trinca). Não é uma estimativa causal de quanto mudaria a pontuação sem aquela conquista. As estrelas obtidas por vários rivais são somadas; não pertencem todas a um único rival. As estrelas de coleta no turno de uma conquista são calculadas separadamente, antes de gerar os pólens daquele objetivo.

## Resultados (controle, segunda rodada)
| Jogadores | Pólens gerados | Recolhidos pelo autor | Recolhidos por rivais | Restantes | Estrelas marginais para rivais | Coleta na conquista floral | Coleta na conquista de fada |
|---|---:|---:|---:|---:|---:|---:|---:|
|2|4,10|1,14|1,73|1,23|2,91|3,42|5,90|
|3|4,10|0,70|2,37|1,04|3,94|3,74|6,17|
|4|4,11|0,49|2,72|0,90|4,48|3,98|6,81|

As conquistas florais geram benefícios comuns substanciais, particularmente com mais adversários; conquistas de fada costumam coincidir com coleta maior. O aumento uniforme de todos os florais (+1) na triagem reduziu a competitividade do coletor (12,5%, 18,06%, 16,67% por N); a compensação uniforme não é recomendada.

## Taxas de vitória por participação (segunda rodada, 108 partidas por célula)
| Cenário | N | Jardineiro | Coletor | Equilibrado |
|---|---:|---:|---:|---:|
|controle|2|56.94%|21.53%|71.53%|
|controle|3|32.41%|28.24%|39.35%|
|controle|4|25.69%|18.06%|31.25%|
|focal|2|51.39%|27.08%|71.53%|
|focal|3|31.33%|29.01%|39.66%|
|focal|4|21.53%|21.64%|31.83%|
|moderada|2|49.31%|29.17%|71.53%|
|moderada|3|27.78%|28.7%|43.52%|
|moderada|4|20.02%|22.45%|32.52%|
|seletiva|2|53.47%|27.08%|69.44%|
|seletiva|3|24.07%|29.63%|46.3%|
|seletiva|4|19.44%|18.75%|36.81%|

A candidata focal mantém a vantagem moderada do equilibrado em mesas de três e quatro, e maior no duelo, enquanto aproxima os especialistas. A moderada também merece atenção: melhora o duelo em comparação à focal, mas aumenta a vantagem do equilibrado em três jogadores. A seletiva é mais agressiva. Não há evidência de que as diferenças sejam definitivas.

## Proposta focal (não oficial) — por modelo
| Classe | Tipo | Objetivo | Atual | Proposta | Conclusão (controle) | Estrelas de coleta na conquista |
|---|---:|---|---:|---:|---:|---:|
|medio|5|A: 5,6 / B: 8,9|3|3|56.8%|3.77|
|medio|11|A: 2,5 / B: 4,6|3|3|48.8%|4.2|
|medio|15|A: 4,7 / B: 6,9|4|4|44.0%|3.85|
|medio|17|A: 2,5 / B: 7,9|4|4|55.1%|3.77|
|medio|19|A: 2,8 / B: 7,9|4|4|64.0%|3.74|
|medio|23|A: 4,6 / B: 7,9|4|4|66.1%|3.1|
|dificil|13|A: 1,3 / B: 7,9|6|6|36.7%|3.84|
|dificil|14|A: 1,3,8 / B: 5|5|6|28.5%|4.16|
|dificil|21|A: 1,9 / B: 6,8|5|5|40.4%|5|
|dificil|24|A: 3,7 / B: 5,9|5|5|27.1%|4.42|
|dificil|25|A: 1,3,5 / B: 4,6|6|7|19.6%|3.34|
|dificil|26|A: 1,3 / B: 4,5,6|6|7|22.0%|4.02|
|dificil|28|A: 4,5 / B: 2,6,8|7|7|29.6%|3.37|
|dificil|29|A: 3,7,9 / B: 6,8|7|7|31.3%|3.2|
|dificil|30|A: 3,5,7 / B: 6,8|7|7|37.2%|3.53|
|fada|10|Três Flores|3|3|42.9%|8.29|
|fada|14|Três Cores|4|3|45.8%|8.78|
|fada|25|Quatro Flores|5|4|72.8%|8.01|
|fada|26|Cinco Flores|7|5|77.5%|7.4|
|fada|27|Coleta em Quatro Flores|6|4|60.7%|9.03|
|fada|41|Duas Vermelhas|5|5|29.1%|7.43|
|fada|42|Duas Amarelas|5|5|27.0%|8.13|
|fada|43|Duas Lilases|5|5|33.3%|6.5|
|fada|44|Reta Distante|5|5|40.2%|5.12|
|fada|45|Reta Longa|8|7|40.2%|3.02|
|fada|46|Diagonal Distante|6|6|38.6%|4.33|
|fada|47|Diagonal Longa|8|8|24.6%|3.21|
|fada|48|Cores Distantes|5|4|65.5%|7.36|
|fada|49|Extremidades|7|7|54.3%|4.43|
|fada|61|Cerco|7/6/5|7/6/5|33.9%|4.24|
|fada|64|Aproximação Estratégica|4/3/2|4/3/2|33.6%|7.9|
|fada|65|Deslocamento Forçado|4/3/2|4/3/2|25.9%|5.91|
|fada|66|Manobra Combinada|6/5/4|6/5/4|45.0%|4.44|
|fada|67|Quebra de Alinhamento|6/7/8|6/7/8|42.0%|4.67|
|fada|69|Confronto Diagonal|5/4/3|5/4/3|37.3%|6.45|
|fada|70|Interposição|7/6/5|7/6/5|27.0%|4.7|

Para valores variáveis, a ordem é 2/3/4 jogadores. A proposta aumenta os difíceis 14, 25 e 26 (+1), preserva os seis médios e reduz seis objetivos de fada ligados a coleta ou voos frequentemente vantajosos. Diagonal Longa e outros posicionamentos com menor coleta não recebem redução generalizada. Manter 1 estrela/pólen, 5 por trinca.

## Limites e próximos testes
A frequência é condicionada à entrega, tempo disponível e heurística, não mede dificuldade absoluta. As cartas não foram randomizadas isoladamente por valor. A amostragem de jogadas limita a procura estratégica; 108 partidas por célula ainda deixam incerteza nas taxas. O controle da segunda rodada registrou 5, 46 e 121 falhas de reposição em 108 partidas por N; na focal, 4, 48 e 118. Isso pode afetar o equilíbrio. Recomenda-se resolver esse problema antes de oficializar a pontuação e testar a focal contra a moderada com sementes adicionais e partidas físicas. Não houve compilação no Godot.
