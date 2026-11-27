# Jardim das Fadas — v216

Projeto Godot 4.x completo, focado em mobile e orientação retrato também no desktop. Modalidade única (antiga Alternativa/Expandida).

Abra `project.godot` no editor Godot e execute a cena principal. O preset Web usa Compatibility. A integração BGA está suspensa e não faz parte deste pacote.

O direcionamento vigente, regras e decisões de continuidade estão em `documentacao/CONTINUIDADE_CHATGPT.md`.

Testes em Python (simulações independentes, sem executar o motor):

- `python tests/testar_setup_v128.py`
- `python tests/testar_v146.py` (roteiro histórico congelado em `tests/roteiro_historico_v146.json`; não representa o tutorial atual)

- `python tests/testar_v176_tutorial.py` (ramificações da quarta jogada e exemplos de busca de dica)

A execução do jogo no Godot e a medição de desempenho ainda precisam ser conferidas.

A v178 adota a estrela prateada de 5 pontas como linguagem oficial de pontos de vitória: cartas, placares, tela final, dicas e tutorial foram ajustados para ensinar e reforçar esse símbolo, preservando as melhorias de toque, plantio e previsão de voo da v177.

A v179 remove o menu intermediário e apresenta Aprender e Jogar diretamente na capa animada. Objetivos em duas colunas e flor na mão ao lado direito.

A v180 unifica instruções e indicador de vez em uma faixa acima do jardim, com lições e previsão de voo no mesmo espaço. Novas ilustrações das três flores, preservando o miolo branco e o desenho durante as animações.

A v181 posiciona baralho e coletiva entre o jardim e a área de objetivos e mão, mantendo a faixa de texto acima do jardim.

A v182 corrige as causas dos dez avisos GDScript reportados na v181, sem alterar regras ou layout. Validação no editor ainda necessária.

A v183 desloca a saída para a coluna inferior direita, acima da flor na mão, substituindo X por porta com seta. Soltar sobre o ícone abre a confirmação; Cancelar retoma a partida e Sair encerra e mostra o placar. A árvore, os temporizadores e as esperas por quadro são pausados durante a confirmação. As simulações independentes e a geometria de 18 combinações passaram; testar a janela e a pausa no Godot.

A v184 retira o botão Objetivos concluídos, organiza Baralho, Carta coletiva e Sua carta em três posições na faixa de compra, e apresenta placar de estrelas animado e interativo na coluna inferior direita. Toque em uma barra para ver estrelas de objetivos, pólens e bônus de trincas; a saída permanece isolada abaixo do placar.


A v185 aprimora o feedback mobile: vibração breve em dispositivos compatíveis, motivo musical na coleta, previsão de estrelas e bônus de trincas no voo, indicadores de rota, brilho prateado no placar e transição suave da escala das barras. Os valores reais e as regras permanecem intactos.

A v186 simplifica o placar durante a partida: somente totais de estrelas e barras, sem consulta da composição. Fontes de compra ficam semitransparentes após a confirmação: baralho e coletiva após compra do baralho, apenas baralho após compra da coletiva (que sai do espaço de origem). Ao terminar a jogada, as fontes retornam ao estado normal. A explicação da pontuação final permanece.


A v187 reorganiza a interface mobile: jardim com 47,3% da altura de referência nas partidas comuns, instruções e compra compactas, grade 2×2 de objetivos, arrasto da flor, consulta ampliada por toque, giro com área sensível maior, contadores de pólens por cor, placar legível, câmera com enquadramento suave, rastro mágico e movimento ambiental discreto. Mantidas as regras, o tutorial progressivo, a confirmação de saída e a transparência das fontes.

Teste adicional: `python tests/testar_v187_layout.py` (153 geometrias e 432 cálculos de enquadramento independentes). A execução do Godot e a experiência real no dispositivo ainda precisam ser verificadas.


A v188 reorganiza a interface mobile para separar melhor compra e posse: placar e fontes de compra compartilham a mesma faixa abaixo do jardim, enquanto a carta da mão passa ao canto inferior direito. Mantêm-se o tutorial, o arrasto para plantar, a grade 2×2 de objetivos, os efeitos de player feel/juice e as regras já aprovadas.


A v189 reposiciona o ícone de saída para o canto superior direito, usa a coluna da mão para mostrar primeiro os pólens por cor, depois o rótulo "Sua Carta" e, abaixo, a carta do jogador. As regras, o tutorial e a organização geral da v188 permanecem.


A v190 aprimora a manipulação de cartas, voo, recompensas, transição de turno e resultado; preserva as regras e o layout de zonas da v189. Teste adicional: `python tests/testar_v190_feedback.py`. Sem execução no motor Godot.


A v191 coloca o placar à direita das fontes de compra. No tutorial, um único objetivo permanece visível até a segunda conquista; depois, o objetivo ativo fica centralizado acima de dois exemplos semitransparentes, exclusivamente didáticos. A terceira conquista libera a fase avançada normalmente. Teste independente adicional: `python tests/testar_v191_tutorial_visual.py`.


A v192 inicia o Aprender com apenas nove cartas (três por cor e um pólen em cada uma). O mesmo objetivo inicial é concluído plantando a coletiva lilás imediatamente acima da flor central da primeira fileira. Os voos reto e diagonal e o deslocamento guiado foram replanejados para o cenário compacto. O teste `testar_v176_tutorial.py` verifica a nova sequência, incluindo o enquadramento inicial. As partidas comuns e a progressão visual da v191 permanecem.


A v193 utiliza flores com miolo da própria cor apenas nas representações dos objetivos florais, inclusive quando ampliados. As flores do jardim e das cartas de compra mantêm o miolo branco.


A v194 corrige o alongamento vertical da abertura: a arte animada mantém a proporção original, centralizada, e os botões Aprender e Jogar acompanham seu enquadramento. A área de jogo continua em retrato 420×920.


A v195 elimina o botão Continuar do tutorial: os três avisos de lição permanecem na faixa de instruções por 3,8 s, 4,0 s e 4,5 s, respectivamente, com barra discreta de leitura e retomada automática. Mantém as dicas opcionais, as regras e as etapas guiadas. Teste adicional: `python tests/testar_v204_tutorial_navegavel.py`.


A v196 eleva os três contadores de pólens em 10 pixels lógicos, mantendo o espaçamento entre eles e o rótulo “Sua Carta” na posição original. Em painéis muito compactos, reserva espaço suficiente acima da mão.


A v197 torna contínuo o som do voo das fadas: textura de ar com vibração suave em loop circular de 2 s, sem reinício nem redução de volume a cada coleta. Decolagem, pouso e sons dos pólens preservados.


A v198 permite arrastar a coletiva diretamente para uma casa válida do jardim, mantendo o toque curto para comprar e levar à mão. Compra confirmada na soltura; se a casa for inválida, a flor vai para a mão, sem devolver à coletiva. A pinça antes da confirmação cancela a intenção.


A v199 acrescenta o arrasto de flores da borda com transporte visual de fadas e pólens, câmera de borda durante arrastos, ambiente sonoro independente, previsão local de combinações florais, reação de pétalas e grama e otimizações de desenho. A prévia não altera a mesa. As regras, o layout e a progressão do tutorial são preservados. Teste independente adicional: `python tests/testar_v199_arrasto_borda.py`.


A v200 revisa a tipografia e a composição das telas de encerramento, apuração dos pólens, explicação das estrelas, regras e menus secundários. Usa painel de resultado com até 860 pixels lógicos, totais de até 37 px, nomes de até 24 px e linhas de detalhamento de até 21 px, além de botões maiores e contadores por cor. Preserva a pontuação e a interface da partida. Teste independente adicional: `python tests/testar_v200_tipografia.py`.


A v201 adiciona o simulador de balanceamento independente da interface, na pasta `simulador/`, mantendo o GDScript da v200 inalterado. Consulte `simulador/LEIA-ME.md`, execute `simulador/executar_simulador.bat` no Windows ou use Python 3.10+. Os resultados de referência de 1080 partidas estão em `simulador/resultados_referencia/`.


A v202 recupera o timbre de asas batendo da v196, com cadência regular ao longo de todo o voo, e elimina a flor-prêmio por objetivo de fada. O simulador segue a nova regra, mas os CSVs de referência de 1080 partidas pertencem à v201 (com flor-prêmio) e não representam a regra atual. Nova diretriz: tornar o jogo acolhedor para não gamers, reduzir carga cognitiva e decisões redundantes, preservar profundidade estratégica.


A v203 suspende o modo Solo e registra a diretriz de equilíbrio estratégico. O jogo mantém a pontuação oficial; os 3.996 jogos simulados, a tabela experimental por tipo e o relatório estão na pasta `simulador`.


A v204 transfere o ícone de saída para o canto superior direito dentro da mesa marrom. O tutorial passa a ter navegação por setas ou arrasto horizontal da faixa de mensagens, com transição deslizante e sem tempo limite de leitura. Voltar revisa mensagens já apresentadas, sem desfazer jogadas; avançar não pula ações obrigatórias. A faixa do tutorial ganha 12 pixels lógicos de altura. Testes independentes aprovados; conferir compilação, recorte e gestos no Godot e em celular.


A v207 oficializa integralmente a tabela focal proposta na v205: três florais difíceis aumentam em uma estrela, seis objetivos de fada têm redução e os demais valores e fórmulas permanecem. O simulador padrão lê o catálogo oficial; a calibração histórica v205 usa os valores de controle anteriores.


## v209 — Fluidez mobile e publicação Web (Itch.io)

- Rotação contínua por arrasto de canto em ambos os sentidos, com encaixe em múltiplos de 90°, consulta por toque breve inclusive no canto, e pontuação sempre fixa no topo esquerdo. Gesto cancelado em perda de foco, multitouch ou Escape. Molduras neutras acompanham a rotação.
- Feedback magnético nos destinos válidos (verde-claro; dourado quando há combinação), vibração breve quando suportada e retorno animado da flor de borda com seus componentes quando solta em destino inválido. Sem alterar a confirmação oficial da jogada.
- Perfil leve inicial em celulares Web e adaptação por FPS: após 2 amostras de 1 s abaixo de 42 FPS, reduzir detalhes decorativos; após 8 amostras a partir de 56 FPS, restaurá-los. Não alterar regras, velocidades de voo, sons, alvos de toque, pontuação ou legibilidade. O FPS real não foi medido.
- Caches limitados de geometria, textos e destinos; busca global de objetivos em fatias de aproximadamente 1,2/2,4 ms (limite cooperativo, verificado entre candidatos); orçamento da IA de 1,8/3,5 ms entre planos; textura de grama em uma operação mesmo quando recortada ou translúcida; quatro máscaras alfa de fadas pré-geradas.
- Preset Web mantém Compatibility, sem threads e sem extensões; limite de 60 FPS, orientação retrato e escala canvas_items preservados. O ZIP do projeto inclui simulador, testes e documentação para continuidade, mas o preset exclui essas pastas na exportação.

### Publicar no Itch.io

1. No editor Godot 4.x (4.3 ou posterior, usando templates de exportação da mesma versão do editor), abra `project.godot`. Instale os templates Web, se necessário.
2. Em Projeto > Exportar > Web, mantenha Thread Support desativado e exporte em modo release (sem debug) para uma pasta vazia, usando o nome `index.html`. O preset sugere `../Jardim_Web/index.html`; crie a pasta antes ou escolha outra pasta vazia.
3. Compacte **o conteúdo dessa pasta exportada** (index.html, .wasm, .pck, .js e demais arquivos produzidos pela Godot) em um ZIP com index.html na raiz. Não envie o ZIP do projeto-fonte como jogo HTML.
4. No Itch.io, selecione HTML como tipo de projeto, envie o ZIP da exportação, marque o arquivo como executável no navegador e habilite a opção Mobile friendly se disponível. Use proporção retrato 420:920 para a apresentação em desktop e permita tela cheia. Teste tanto o iframe quanto a tela cheia em aparelhos reais.
5. Valide no Chrome Android e no Safari iOS: iniciar tutorial, áudio após primeiro toque, compra por toque/arrasto, giro horário/anti-horário, pinça, retorno inválido, voo longo, troca de vez, máquina (2–4 jogadores), retomada após minimizar e tela final. F3 em desktop mostra métricas de depuração; compare v208/v209 no mesmo dispositivo e condições. Meta de teste: 60 FPS quando possível, sem travamentos perceptíveis; não é garantia de desempenho.

Referência: https://docs.godotengine.org/pt-br/4.x/tutorials/export/exporting_for_web.html

Validação v209: 16 scripts Python independentes passaram. O novo `tests/testar_v209_web_mobile.py` utiliza Pillow para comparar os 892.080 pixels de máscaras pré-geradas e modelos independentes para 2.904 trajetórias angulares e 511 fronteiras × 4 tamanhos de fatia. Sem binário Godot neste ambiente; compilação, exportação executável, perfil real de CPU/GPU, latência e FPS não foram verificados. A exportação HTML final deve ser feita no editor.


### v210 — Setas de rotação

Somente o canto superior direito dos objetivos florais inicia a rotação: toque na seta esquerda (anti-horária) ou na seta para baixo (horária), ou arraste a partir delas. O corpo da carta abre a consulta ampliada. Sem círculos nos cantos, inclusive na aula. Estrelas fixas no topo esquerdo.


### v211 — Seta curva única

As duas setas do cabeçalho foram unidas em um só arco aberto, com ponta à esquerda e ponta para baixo. Cada metade conserva seu sentido de toque; o gesto angular e a consulta permanecem iguais.


### v212 — Seta circular de referência

Arco circular com duas pontas arredondadas, inspirado na referência enviada e orientado 180° em relação a ela (esquerda e baixo). Mesmo bege discreto da v211. Seta no topo direito e estrela/pontos no topo esquerdo permanecem fixos durante o giro. Interações preservadas. Validação geométrica independente; sem execução Godot.


A v213 remove da criação e atualização da interface os botões Jogar uma Flor e Mover Flor e Jogar. As ações são diretas nas cartas e no jardim; Cancelar permanece quando aplicável.

## v214 — Correção de compilação reportada

Corrigida a referência `feel_previa_ids` para `feel_previsao_ids` no desenho do encaixe magnético. Preservadas todas as alterações da v213. Novo teste estático `python tests/testar_v214_referencias.py`. A conferência no compilador Godot permanece pendente.


### v216 — Giro sem símbolo

Toque no canto superior direito do objetivo floral para girar 90° no sentido horário; arraste a partir desse canto para girar nos dois sentidos. A região é invisível. Toque no restante da carta para ampliar. Tutorial atualizado; pontuação fixa no topo esquerdo.
