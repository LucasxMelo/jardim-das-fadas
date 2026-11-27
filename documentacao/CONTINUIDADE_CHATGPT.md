# Jardim das Fadas — continuidade v177

**Direcionamento vigente — 26/11/2026.** Esta seção é a referência para as próximas alterações. Não retomar automaticamente recursos ou modalidades de versões antigas. A v176 é a base imediata; os ZIPs anteriores conservam o material histórico removido.

## 1. Produto e plataforma

- Prioridade: experiência **mobile first**, com Godot 4.x, renderizador Compatibility e exportação Web/itch.io. Orientação **retrato sempre**, inclusive em PC. Viewport lógico 420 × 920, escala proporcional, interface de toque e janela vertical no desktop.
- **BGA (Board Game Arena): suspenso por enquanto.** Não investir em integração, sincronização, testes ou adaptações BGA nas próximas versões, salvo pedido explícito do usuário. A pasta BGA foi retirada deste projeto ativo; não foi destruída nos ZIPs anteriores.
- Uma única modalidade: a antiga Alternativa/Expandida, apresentada publicamente apenas como **Jardim das Fadas**. Não oferecer Original, Simplificada, Solo, Voo Livre nem pintura de flores. Modos atuais: Aprender, Duelo Local e Contra a Máquina (1 a 3 máquinas, Normal/Difícil).
- Manter foco em fluidez e clareza. Não acrescentar funcionalidades, efeitos ou controles que não tenham finalidade na modalidade vigente. Preferir reutilização de texturas e estilos, layout por mudança de estado, IA cooperativa e evitar cópias desnecessárias. F3 é diagnóstico no PC; os efeitos usam a intensidade normal, sem botão FX durante a partida.

## 2. Interface e interação

- Entrada única no menu inicial. Arte dourada estática (sem movimento das asas, flor ou fundo); manter reflexo no título, iluminação, partículas e transição de botão.
- Identidade profissional de fantasia botânica: tons escuros de madeira, dourado envelhecido, tipografia clara, molduras finas e cantos suavemente arredondados; não prejudicar contraste nem desempenho. Preservar as cores das flores, fadas e pólens.
- Não existe campo permanente “Carta escolhida”. A carta comprada aparece na **terceira posição da faixa de compra**, à direita da carta coletiva, sem moldura vazia. Durante prévia na mesa, a carta não confirmada é semitransparente; só fica opaca ao se acomodar.
- Compra irreversível: coletiva e baralho têm a mesma obrigação de jogar a carta adquirida; não devolver, descartar, substituir ou comprar outra. Cancelar a movimentação de uma flor não desfaz a compra.
- Ao escolher qual fada avançará, **todo o quadrado da flor** é área de toque. Se duas elegíveis ocuparem a mesma carta, escolher a mais próxima do toque. Manter contorno azul indicativo de elegibilidade.
- Sem botões de revisar, voltar/avançar jogadas, alterar som ou novo jogo durante a partida. Fechar por X. Não confundir revisão de jogadas com janela de objetivos conquistados ou paginação do placar (estas permanecem).

## 3. Regras atuais

- Tabuleiro inicial fixo 3×3: três flores de cada cor, central imóvel, duas fadas por jogador e 1 pólen por flor. Máximo 4 pólens por flor. A abertura usa 6 permutações de cores e duas orientações.
- Em cada turno plantar uma carta adjacente ou deslocar uma flor da borda uma casa ortogonal e repor o espaço. Fadas e pólens acompanham a flor deslocada.
- Após plantar/repor, uma fada alinhada em reta ou diagonal pode voar até a nova flor; voo opcional, sem ação independente. Recolhe pólens das flores visitadas; produz um pólen nas vazias. Voo contínuo, sem parar para coletar.
- Mão inicial normal: 3 objetivos Médios (3–4 pontos). Após terceira conquista, 2 objetivos Difíceis (5–7) e 2 de Fada. Rotação de desenhos em 90°, sem espelhamento; apenas um objetivo pontua por jogada. Objetivos florais geram pólens, de Fada concedem escolha da cor da próxima flor. Manter catálogo e diversidade de tipos/cores atuais.
- Cada pólen guardado vale 1 ponto; três da mesma cor valem 5 no total. Sem duplicação de objetivos. Vence a maior pontuação após o encerramento por seis objetivos e rodada de fechamento (ou esgotamento das cartas). No tutorial, seis conquistas encerram sem rodada bônus.

## 4. Tutorial progressivo

- Aprender é uma prática individual, sem oponente. Inicia por demonstrações simples, não por um menu de escolhas.
- Primeiras 3 jogadas: roteiro guiado de plantio e voo reto/diagonal, sem opções que desviem da demonstração. Na quarta, deslocamento guiado com escolha entre coletiva e baralho e liberdade de voar. A partir da quinta, jogadas livres; dicas contextuais, sem imposição do roteiro antigo. Pode decidir fonte de compra, plantio, deslocamento, voo, rotações e recompensas.
- Nas primeiras 3 conquistas, mostrar **um objetivo ativo por vez**. Depois, progressão normal para 2 Difíceis e 2 de Fada. Terminar ao completar 6 objetivos, respeitando o encerramento por esgotamento de cartas previsto nas regras.
- O teste `tests/testar_v146.py` é uma simulação independente do antigo roteiro de referência de 11 jogadas, não um teste de execução do tutorial progressivo completo. Não reintroduzir a obrigatoriedade das jogadas 5–11 por causa desse teste.

### Aperfeiçoamento v176 — aprendizagem progressiva

- Abertura sem janela introdutória: a aprendizagem começa diretamente no jardim preparado. Faixa de instruções identifica as quatro lições: plantar e pontuar, voo reto, voo diagonal, mover e escolher. Nas primeiras três demonstrações apenas o caminho necessário é permitido; a quarta mantém compra e voo livres.
- A partir da quinta jogada a faixa mostra o progresso de 0–6 objetivos e instruções contextuais; três conquistas desbloqueiam a fase avançada. A explicação visual dos pólens permanece após o primeiro objetivo e após o voo reto, sem repetição obrigatória após a segunda conquista.
- Após a compra, na prática livre, o botão **Dica** é facultativo e pode ser ocultado. Procura primeiro um plantio direto e, se não houver, um deslocamento que conclua um objetivo floral ativo; usa o mesmo verificador da partida em cópias do tabuleiro. Mostra um alvo dourado, nunca joga automaticamente, não altera o estoque nem limita escolhas. Sem uma conquista imediata, orienta preparar o objetivo ou coletar pólens. Não promete uma solução para objetivos de fada.
- Na quarta jogada e na fase livre, a faixa prevê coleta e polinização para as fadas elegíveis, identificadas por número. A previsão não altera a mesa. Encerramento distingue seis objetivos conquistados, esgotamento de cartas e encerramento voluntário.
- Testes independentes: abertura e roteiro histórico preservados, 864 primeiras jogadas normais e 9 ramificações de reposição/voo na quarta jogada. Incluídos testes positivos de formação floral, conectividade e conservação de pólens. Não houve execução real no Godot ou teste em dispositivo móvel.

## 5. Game feel e sonoplastia preservados

- Inclinação e acomodação das cartas, desabrochar, efeitos de terra no plantio; fadas/pólens acompanhando a carta. Flores não reagem ao vento das asas.
- Voo com timbre de asas suave derivado da v153 (v165: menos áspero e 2 dB mais baixo que v153), sem ressonância musical nem vibração de beija-flor. Sons de coleta e chegada individual dos pólens mantidos.
- Encerramento: pólens se agrupam em trincas por cor antes do placar; pontos progridem suavemente. Não recuperar a distribuição da modalidade Original.

## 6. Estrutura e limpeza v175

- `scenes/principal.tscn` usa `scripts/jogo/jardim.gd` diretamente. Os antigos scripts auxiliares duplicados não faziam parte da cadeia de carregamento e foram retirados.
- Removidos ramos condicionais comprovadamente desativados, funções sem referências na cadeia de callbacks, controles ocultos de som/solo/revisão e gravação de snapshots de partidas; catálogo antigo de objetivos pequenos não é mais construído na inicialização. Histórico de objetivos e pontuação permanecem.
- Retirados o fundo paisagem, BGA e testes/documentação históricos incompatíveis com a modalidade atual. A v174 original fica como arquivo de referência histórica.
- Permanecem alguns identificadores e rotinas compartilhadas com nomes legados (por exemplo `gamer:` nos IDs de objetivos), bem como guardas residuais. Não alterar IDs ou excluir dados partilhados por mera busca textual. Uma limpeza integral exige testes reais de todas as rotas e do motor.
- Validação nesta versão: verificações estáticas de referências de recursos e callbacks, simulação independente de 864 primeiras jogadas e do roteiro didático de referência de 11 jogadas. Godot não está disponível no ambiente de edição; não houve execução do motor, exportação Web ou medição de FPS real. Priorizar teste de abertura, compras, toque, tutorial livre, duelo, IA e placar no Godot/itch.io antes de remover as guardas restantes.

## 7. v177 — Primeira etapa de player feel e juice

- Compra confirmada ao soltar sobre a fonte inicialmente pressionada; arrastar para fora antes da soltura não compra. Depois de confirmada, a compra continua irreversível. Áreas de toque incluem os rótulos.
- Pressionar casa válida com flor na mão permite arrastar a prévia até outra casa válida antes de confirmar. Soltar fora cancela só a intenção de plantar. Arrasto iniciado fora de casa válida continua movendo a câmera. Pinça cancela intenções; toques para escolha de fada exigem consistência entre pressão e soltura.
- Prévia de rota e contagem de pólens na escolha de fada, destaque de casas disponíveis, resposta visual da fonte de compra e da mão, constelação dourada para objetivos florais concluídos.
- Cabeçalho de partida: remover texto Aprender e controles FX/som. Preservar botão Aprender no menu inicial, X para sair, sonoplastia e intensidade normal de efeitos.
- Simulações independentes de setup, roteiro histórico e tutorial v176 aprovadas. Sem execução Godot: validar gestos, compra de reposição, aparência e efeitos no celular antes de considerar a etapa concluída.


## 8. v178 — Estrela prateada como linguagem oficial de vitória

- Adotar uma **estrela prateada de 5 pontas** como ícone oficial dos pontos de vitória do jogo. Sempre que possível, trocar a linguagem textual de “pontos”/“pts” na interface jogável por linguagem em **estrelas**, mantendo clareza para o jogador.
- Cartas de objetivo florais e de fada devem exibir seu valor com a estrela prateada no cabeçalho. Placar lateral, escolhas de objetivo, tela final e mensagens de conquista também devem usar a mesma convenção visual.
- O tutorial precisa ensinar explicitamente essa linguagem logo no início: a estrela prateada representa a vitória; objetivos e pólens rendem estrelas.
- Textos explicativos, tela “Entenda as Estrelas” e painéis de pontuação final devem reforçar a regra atual da modalidade: cada pólen vale 1 estrela; cada trinca da mesma cor vale 5 estrelas no total.
- A mudança é de comunicação visual/verbal; não altera regras de pontuação, progressão, IA, estrutura dos objetivos nem fluxos já aprovados da v177.


## 9. v179 — Abertura direta e organização inferior

- Entregar sempre o projeto completo em ZIP nas próximas atualizações, não apenas o script.
- Na capa animada: dois botões reais, Aprender e Jogar. Aprender abre diretamente a prática guiada; Jogar abre Duelo Local e Contra a Máquina. Removidos Entrar, a tela intermediária da versão e o texto de características também na seleção de modalidades. Voltar retorna à capa animada.
- Painel inferior esquerdo ocupa duas colunas de objetivos, com posições fixas: 1 objetivo na primeira posição; 3 em 2+1; 4 em 2×2. O painel reserva espaço para os pólens guardados e mantém a janela de conquistas. À direita, a carta de flor comprada ocupa o canto inferior, sem moldura vazia. Compra, plantio, rotação e efeitos usam os mesmos retângulos atualizados.
- Mantidas as regras, o tutorial progressivo, a orientação retrato e o símbolo de vitória da v178. Validação independente de geometria em 18 cenários e testes Python anteriores; não houve execução no Godot.


## v180 — Faixa de texto única e novo desenho das flores

- Uma única caixa fixa, acima do jardim, compartilhada pelo tutorial e pelas partidas. No tutorial contém lição atual, orientações, Dica e Continuar quando necessário. Nas partidas, contém a vez pela cor das fadas e a ação atual, por exemplo “Pegue uma flor” ou “Jogue na mesa, ou mova uma flor”.
- Explicações didáticas de estrelas, pólens e desbloqueio dos objetivos de fada permanecem na faixa, sem janela sobre o jardim. A previsão de voo mostra a trajetória no tabuleiro e a contagem na mesma faixa.
- Três flores redesenhadas com oito pétalas alongadas e arredondadas, sobreposição, relevo suave e miolo branco. As mesmas texturas são usadas durante compra, prévia e animação de crescimento, preservando cores, regras e sonoplastia.
- Testes independentes de setup, roteiro histórico e tutorial aprovados. Sem execução do motor Godot neste ambiente; validar aparência, interação e animações no dispositivo.


## v181 — Fontes de compra abaixo do jardim

- Ordem vertical fixa: faixa única de texto, jardim, baralho e carta coletiva, zona inferior de objetivos e flor na mão. Mantidos baralho à esquerda e coletiva à direita, tamanhos e espaçamentos, grade de objetivos 2×2 e mão no canto inferior direito.
- Retângulos de desenho, toque, destaques do tutorial e animações de compra/reposição usam a nova posição. Nenhuma regra foi alterada.

## v182 — Limpeza dos avisos GDScript

- Conversão explícita do cálculo de centralização da janela; remoção de variáveis locais sem uso, prefixos em parâmetros de funções residuais e renomeação de variáveis locais que sombreavam atributos. Não desativar os avisos globais do GDScript. Nenhuma alteração de regras, tutorial, recursos ou layout.


## v183 — Saída da partida

- Substituir o X superior por ícone vetorial de porta e seta na coluna inferior direita, acima da flor na mão, com área de toque de 48 × 48 no viewport de referência. Liberar a antiga faixa superior.
- O toque só abre a janela na soltura sobre o ícone. A janela escurece a mesa e oferece Cancelar (foco inicial) e Sair. Cancelar mantém a partida, incluindo carta já adquirida; Sair confirma o encerramento voluntário e apresenta o placar, preservando o fluxo anterior.
- Pausar a árvore e os temporizadores de jogo, e impedir avanço de corrotinas que aguardam quadros, enquanto a janela estiver aberta. Não alterar o encerramento automático pelas regras.
- Testes independentes e geometria de 18 combinações aprovados; execução real da janela, retomada das animações e IA ainda precisam ser verificadas no Godot.


## v184 — Faixa de três cartas e placar interativo

- Na faixa abaixo do jardim, da esquerda para a direita: baralho, carta coletiva, sua carta. As três posições usam o mesmo tamanho e alinhamento. A mão não é uma nova fonte de compra. As animações usam os retângulos atualizados.
- Remover o botão de objetivos concluídos da mesa e seu acionamento por toque; preservar histórico interno para regras e apuração. A animação de arquivamento passa a dirigir-se à barra do jogador que conquistou o objetivo.
- Manter a grade de objetivos em duas colunas. A antiga coluna da mão passa a exibir o placar com barras, cores das fadas e valores em estrelas prateadas; atualização durante toda a partida, inclusive no tutorial. A soma parcial inclui objetivos concluídos, pólens guardados e bônus de trincas já formadas, sem contar pólens ainda no jardim.
- Tocar numa barra seleciona o jogador para detalhar sua pontuação no próprio painel, sem abrir janela nem interferir na jogada. A seleção inicial é Brancas. Escala compartilhada por todos os jogadores e preenchimento animado.
- Ícone de saída fica abaixo do placar, separado das barras; manter confirmação com Cancelar e Sair. Atualizar dicas e regras de interface.
- Validação: simulações independentes e geometria de layout, sem execução no motor Godot.


## v185 — Player feel e juice: coleta, voo e placar

- Vibração discreta nas ações efetivamente aceitas de jogadores humanos (compra, deslocamento, plantio, voo, coleta e conquista), apenas em plataforma móvel compatível e com intervalo mínimo. Não há controle extra na partida; a disponibilidade depende do aparelho, plataforma e navegador.
- A chegada dos pólens usa motivo pentatônico suave, com sequência contínua ao longo do voo, sem mudar a sonoplastia das asas nem o ritmo lógico da coleta.
- A previsão de voo calcula estrelas provenientes da coleta incluindo os bônus adicionais por trincas da mesma cor, em cópia da reserva. Marcadores mostram quantidade a recolher ou sinal + nas flores vazias. Não promete pontuação de objetivos de fada nem muda o jardim.
- Ao ganhar estrelas, a barra recebe brilho, realce e estrela vetorial de cinco pontas; o bônus por trincas tem realce adicional. O total numérico é exato e imediato; preenchimento e escala comum animam-se suavemente. A faixa única informa os ganhos recentes durante a coleta e a conquista.
- Mantidas a interface v184, a compra irreversível, a confirmação de saída, o tutorial progressivo e as regras. Testes Python independentes, sem execução do motor ou aferição de vibração.

## v186 — Placar compacto e disponibilidade das fontes

- Placar em tempo real apresenta apenas nomes, barras animadas e total de estrelas. Retirar detalhamento de objetivos, pólens e trincas e seleção por toque; destaque indica a vez atual. Manter explicação no resultado final e cálculo intacto.
- Após comprar do baralho, reduzir a opacidade visual do baralho e da coletiva; após comprar da coletiva, reduzir apenas a do baralho, mantendo o espaço da coletiva vazio até a reposição. Após flor de prêmio, ambas as fontes ficam semitransparentes. A carta adquirida permanece normal.
- Usar a origem da compra, preservada até o fim do turno, para a disponibilidade visual e bloquear nova compra mesmo após o plantio. Manter as animações de compra e reposição. Retornar à opacidade normal no turno seguinte.


## v187 — Organização mobile, manipulação e atmosfera

- Preservar orientação retrato e ordem vertical aprovada: faixa única de instruções, jardim, baralho/coletiva/mão e zona inferior com objetivos 2×2, reserva por cor, placar e saída. A zona de objetivos ocupa aproximadamente 58% da largura disponível; o placar ocupa o restante. No viewport 420×920, com 3–4 objetivos e partida comum, o jardim tem 435,6 pixels lógicos (47,3% da altura). Tutorial mantém faixa fixa de 80 px para suas instruções; partidas comuns, 64 px.
- Compactar a faixa de compra e suas legendas sem alterar ordem, animações ou irreversibilidade; a carta da mão tem leve elevação visual. Preservar transparência de fontes indisponíveis da v186. Plantar por toque ou por arrastar a carta da mão: prévia translúcida, soltura em célula válida confirma, soltura inválida cancela apenas o gesto. Pinça cancela a intenção e não devolve carta. Tutorial mantém o alvo obrigatório e as mesmas etapas de progressão.
- Objetivos: grade 2×2, valores em estrelas prateadas mais destacados, texto de fada ajustado ao espaço. Toque no corpo da carta abre consulta ampliada; toque novamente ou Escape fecha. Não executar jogada durante a consulta. Área de toque do ícone de giro ampliada dentro da própria carta; continua girando apenas a apresentação.
- Reserva de pólens: três símbolos de cor com contadores, inclusive zero; efeitos de coleta continuam chegando à cor correspondente e o contador aparece atualizado conforme chegam. Placar com números maiores, barra preta contornada e somente totais, sem detalhamento durante partida. Reduzir bordas externas dos painéis e manter contornos funcionais das cartas e comandos. Saída discreta com confirmação preservada.
- Enquadramento inteligente: quando a geometria do jardim ou da área muda, ajustar suavemente centro e zoom para mostrar o conjunto com margem de expansão, sem aumentar automaticamente o zoom. Gesto manual interrompe o ajuste e tem prioridade por cinco segundos; não mover a câmera durante gestos, celebrações e voo. Preservar enquadramento especial das demonstrações e dicas solicitadas.
- Rastro dourado mais luminoso e gradual no voo, com partículas limitadas e recortadas à área útil; movimento ambiental suave e independente das flores em repouso (variação de escala de 0,8%, sem mudar posição lógica). Sem adicionar objetos, ações, pontuação ou dependências externas.
- Tutorial ensina o arrasto e a consulta ampliada no mesmo espaço de instruções. Não reintroduzir detalhamento do placar nem janelas de revisão.
- Validação: scripts Python existentes aprovados (setup, roteiro, tutorial, cálculo de estrelas); novo teste independente `tests/testar_v187_layout.py` cobre 153 combinações de geometria e 432 cálculos de enquadramento. Não houve execução ou compilação no Godot, teste em celular, nem aferição de FPS. Confirmar especialmente gestos de toque/pinça, ampliação, leitura de objetivos de fada, enquadramento em jardins grandes e legibilidade dos contadores antes de considerar a ergonomia definitiva.


## v188 — Compra e placar na mesma faixa; mão no canto inferior direito

- Adotar a segunda organização visual aprovada: manter a orientação retrato e evitar criar uma nova faixa superior para o placar. A hierarquia passa a ser: faixa única de instruções, jardim, faixa compartilhada de **placar + fontes de compra**, e zona inferior com **objetivos à esquerda** e **carta da mão à direita**.
- Integrar o placar e as fontes de compra numa mesma faixa horizontal abaixo do jardim. O placar permanece em tempo real, com barras e total de estrelas; baralho e carta coletiva ficam à direita, lado a lado. A compra continua irreversível e as transparências de indisponibilidade da v186 permanecem válidas.
- A carta da mão deixa de ficar ao lado das fontes de compra e passa para o **canto inferior direito**, em coluna própria, reforçando visualmente a ideia de posse do jogador. Preservar a elevação visual da mão, o arrasto direto para o jardim, a animação de compra da fonte até a mão e o espaço vazio quando nenhuma carta foi adquirida.
- Objetivos continuam em grade 2×2 na área inferior esquerda, com consulta ampliada e ícone de rotação com área de toque ampliada. Os agrupamentos de pólens por cor e quantidade continuam na mesma área.
- Reposicionar o ícone de saída para a coluna inferior direita, abaixo da mão, preservando a confirmação com Cancelar e Sair.
- Atualizar os textos explicativos de interface para refletir a nova organização. Regras, tutorial, pontuação, placar simplificado, efeitos de voo/rastro e movimentos ambientais permanecem inalterados.
- Validação realizada apenas com os testes Python independentes já existentes; ainda não houve compilação nem verificação visual no editor Godot.


## v189 — Polens acima da mão e saída no topo

- Na coluna inferior direita, acima da carta do jogador, mostrar o texto **"Sua Carta"**.
- Usar o espaço acima desse rótulo para exibir quantos pólens de cada cor o jogador possui, mantendo a linguagem por cor e quantidade já aprovada.
- Remover o ícone de saída da região inferior e reposicioná-lo no **canto superior direito**, na mesma faixa vertical da caixa única de texto/instruções.
- Preservar as regras, o tutorial, o placar na faixa abaixo do jardim, a compra irreversível, os objetivos 2×2 e o arrasto da carta da mão para o jardim.
- Ajustar a área útil do texto/instruções para não ficar por baixo do ícone de saída.
- Validação apenas com testes Python independentes; ainda falta conferir a aparência no Godot.


## v190 — Materialidade, voo e recompensas

- Preservar layout da v189: instruções e saída no topo; jardim; placar e compra compartilhados; objetivos à esquerda; contadores de pólens, Sua Carta e flor à direita. Corrigir sobreposição da saída com Dica/Continuar, empilhar os três contadores acima do rótulo e compactar linhas do placar para quatro jogadores.
- Arrasto da mão: inclinação limitada e suavizada, sombra de elevação, atração magnética a célula válida próxima e retorno animado em soltura inválida. Compra continua irreversível; validação de célula e restrições do tutorial são as mesmas. O plantio parte da posição visual arrastada.
- Fadas: inclinação na direção do destino, prontidão das asas, ajuste de decolagem/pouso, rastro proporcional à coleta e movimentos discretos em repouso. Reação visual da grama no plantio.
- Trincas: efeito de três partículas ao chegar o terceiro pólen e estrelas prateadas representando bônus; objetivos enviam estrelas ao placar em trajetória curva. Não alterar crédito real de pontos ou estoque. Destaque de turno dissolve entre jogadores.
- Objetivos florais: realçar os que podem ser concluídos por plantio direto com a flor na mão, usando o verificador real em cópias; cache por estado. No tutorial, preservar dicas opcionais em vez de revelar automaticamente. Não antecipar objetivos de fada nem prometer deslocamentos.
- Resultado: brilho prateado nas melhores pontuações e partículas de estrela no encerramento pelas regras; sem celebração nova ao sair voluntariamente. Durações da compra ligeiramente menores; decolagem e pouso de 250 ms na intensidade normal, retorno inválido de 240 ms; recompensas não bloqueiam a jogada.
- Validação: testes Python de setup, roteiro, tutorial, 91.125 combinações de pontuação e novo modelo independente de geometria/chegada de trincas; motor Godot indisponível. Confirmar compilação, aparência e sensação real no celular antes de considerar efeitos finalizados.


## v191 — Placar à direita e apresentação progressiva dos objetivos

- Na faixa abaixo do jardim, ordenar baralho, carta coletiva e placar da esquerda para a direita. Preservar largura das zonas, mão no canto inferior direito, reserva de pólens e saída no topo.
- No modo Aprender, mostrar apenas um objetivo ativo, centralizado, até completar a segunda conquista. Após a reposição da segunda carta concluída, mostrar a terceira meta centralizada na linha superior e duas cartas médias ilustrativas na linha inferior, com aparência de 32% de opacidade.
- As duas prévias ficam fora da mão pontuável, sem rotação/consulta nem efeitos de jogo; exemplificam a organização de uma mão de três objetivos sem modificar o sorteio ou as regras da aula. Priorizar tipos e pares de cores distintos do objetivo ativo e exemplos ainda não formados no jardim. A terceira conquista mantém a transição original para dois Difíceis e dois de Fada, todos normais, descartando as prévias. A compra e as escolhas de jogada livre permanecem inalteradas.
- Preservar efeitos da v190, animações de arquivo e estrelas dirigidas ao placar em sua nova posição.
- Todos os testes Python anteriores passaram, bem como `tests/testar_v191_tutorial_visual.py` (108 geometrias e integração estática). Não houve compilação nem execução no Godot.


## v192 — Abertura compacta do tutorial

- O modo Aprender começa exclusivamente com o quadrado 3×3 de nove flores, três de cada cor e um pólen em cada flor. Remover as seis flores extras e o pólen adicional do cenário anterior; a distribuição normal das partidas competitivas não muda. Disposição didática da esquerda para a direita, de cima para baixo: vermelha/lilás/vermelha; lilás/amarela/vermelha; lilás/amarela/amarela. Fadas nas duas flores dos cantos inferiores.
- Manter o mesmo objetivo inicial `gamer:11:lilas:vermelha` (três estrelas): o jogador compra a coletiva lilás e a planta em (0,-2), imediatamente acima da flor central da primeira fileira. A cruz incompleta forma-se com as duas vermelhas laterais e as duas lilases verticais. Nenhuma fada está alinhada com o primeiro plantio.
- O cenário reduzido permite que o enquadramento guiado inicial use o tamanho nominal máximo de 88 pixels lógicos por carta no viewport 420×920 (antes, cerca de 51,9). Preservar a câmera e o layout aprovado.
- Replanejar a sequência: segundo turno, compra do baralho lilás e plantio em (-1,-2), com voo reto da fada que começa no canto inferior esquerdo; recolhe quatro pólens (dois vermelhos e dois lilases, utilizando os pólens produzidos pelo primeiro objetivo). Terceiro turno, compra lilás e plantio em (-2,-2), voo diagonal da outra fada, coleta dois pólens e produz um. Quarto turno, mover a flor (-2,-2) para (-2,-1), com compra e voo de livre escolha. A partir do quinto turno, prática livre e dicas opcionais, mantendo a progressão de objetivos da v191 e as regras.
- Roteiro ativo limitado às quatro jogadas guiadas; o antigo roteiro de 11 jogadas permanece apenas como referência congelada de teste, não como sequência de execução. Testes independentes do roteiro atual, nove ramificações da quarta jogada, quatro deslocamentos pontuáveis após reposição vermelha, enquadramento e testes anteriores aprovados. Não houve compilação nem execução no motor Godot.


## v193 — Legibilidade das flores nos objetivos

- Nas representações dos objetivos florais, utilizar o miolo da mesma cor das pétalas (vermelha, amarela ou lilás), facilitando a leitura em tamanho reduzido. Aplicar também à consulta ampliada e às demais representações que usam o mesmo desenho de objetivo.
- Manter as ilustrações das flores do jardim, das fontes de compra e da mão com miolo branco. Usar três texturas específicas para objetivos, preservando a silhueta, transparência e cores das pétalas. Não alterar regras, layout nem tutorial da v192.
- Validação estática das texturas e testes Python independentes; execução visual no Godot pendente.


## v194 — Enquadramento proporcional da abertura

- Corrigir a escala não uniforme da arte inicial de 941×1672 no viewport 420×920. Usar escala uniforme de contenção, sem cortar ou deformar a pintura, centralizando-a sobre o fundo escuro existente. No viewport padrão, a arte ocupa cerca de 420×746,3 px, em vez de 420×920 px.
- Os botões Aprender e Jogar são posicionados relativamente ao mesmo retângulo da ilustração, preservando a moldura inferior e a animação de entrada. O fallback estático usa exatamente o mesmo enquadramento. O shader, a orientação retrato, a resolução lógica, as regras, a interface de partida e o tutorial permanecem inalterados.
- Verificação de geometria independente e testes de regras; execução no Godot ainda pendente.


## v195 — Tutorial sem botão Continuar

- Remover os botões de confirmação dos avisos pedagógicos. Na mesma faixa de instruções, a explicação de pólens após a primeira conquista dura 3,8 s; a explicação da pontuação após o voo reto, 4,0 s; a apresentação dos objetivos de fada na fase avançada, 4,5 s. Estes tempos de leitura são independentes da intensidade de animação. Uma barra fina decrescente informa a passagem automática.
- As corrotinas existentes retomam a celebração, a reposição e a progressão após o aviso, sem toque nem teclado. Não modificar objetivos, setup de nove flores, regras ou roteiro de quatro jogadas guiadas. Durante os avisos, consumir os gestos sem executar ações acidentais. Preservar a saída com confirmação, interrompendo a contagem durante a pausa e retomando após Cancelar; invalidar avisos antigos ao encerrar ou reiniciar.
- Retirar também os controles antigos de continuar/desafio ao terminar a orientação, já substituídos pela transição automática à prática livre. O tutorial continua até seis conquistas. Manter Dica/Ocultar como consulta opcional e todos os efeitos da v190, a progressão da v191, o miolo colorido dos objetivos e a abertura proporcional da v194.
- Validação: sete testes Python anteriores e `tests/testar_v195_tutorial_automatico.py` (24 combinações de tempo/pausa e integração estática) aprovados. Sem compilação ou execução real no Godot; verificar legibilidade e ritmo em celular.


## v196 — Respiro acima de Sua Carta

- Elevar o grupo dos três contadores de pólens em 10 px lógicos, preservando os 21 px entre centros, as cores, os valores e o rótulo Sua Carta. As animações de coleta e trincas usam o mesmo centro atualizado. Reservar 10 px adicionais de espaço mínimo no painel da mão, reduzindo sua carta apenas se necessário em layouts compactos. Preservar regras, tutorial e demais componentes.
- Conferência geométrica independente; sem execução no motor Godot.


## v197 — Som contínuo das asas

- Substituir a amostra de 0,4 s com três batidas separadas por textura de ar de 2 s, sintetizada em memória com ruído filtrado circularmente e modulação discreta de asas. Sem envelope de ataque e saída a cada repetição; as frequências de modulação fecham ciclos inteiros.
- Manter um único canal de voo em loop durante decolagem, percurso e pouso, tanto no Godot nativo como na ponte Web Audio. Retirar a redução de volume a cada coleta de pólen e preservar as notas de coleta em canais independentes. A variação de altura é suave, e o volume diminui somente ao pousar. Não alterar a duração ou a lógica de voo, regras, layout ou tutorial.
- Validação: oito testes Python anteriores e verificação estática do loop e envelope aprovados. Não houve execução no Godot nem escuta no jogo; verificar timbre e volume em aparelho real.


## v198 — Arrasto direto da carta coletiva

- Permitir levantar a carta coletiva com gesto de arrasto (limiar de 11 px lógicos), aproveitando a inclinação, sombra, magnetismo e prévia da v190. Toque curto mantém a compra convencional para a mão; o baralho continua a exigir a compra e a revelação.
- Durante o gesto, não modificar o estado da partida. Confirmar a compra irreversível uma única vez na soltura, com os mesmos validadores e tokens da partida/turno. Soltar numa casa válida executa o plantio normal sem animação intermediária para a mão; a animação de plantio parte da posição e tamanho visuais do arrasto. Soltar em área inválida leva a carta à mão com retorno animado, sem desfazer a compra. Pinça/cancelamento de toque/perda de foco antes da confirmação cancela somente a intenção.
- Nas lições guiadas de plantio, mostrar o alvo permitido ao disponibilizar a coletiva e manter a restrição ao destino didático. Nas lições de deslocamento, manter o fluxo original de compra/reposição; não permitir arrastar para substituir outra flor. Atualizar a orientação inicial e o texto de compra.
- Layout v197, regras, objetivos, voo, áudio e demais efeitos preservados.
- Validação: oito testes anteriores e `tests/testar_v198_arrasto_coletiva.py` (256 combinações independentes de compromisso/soltura e integração estática). Não houve compilação ou execução no Godot; verificar em celular e desktop arrasto, magnetismo, multitouch, tempo de animação e leitura das instruções.


## v199 — Manipulação direta do jardim, câmera e atmosfera

- Base: v198. Não mudar layout, pontuação, compra irreversível, limite de objetivos por jogada, condições de voo, reposição automática, regras do deslocamento, IA ou progressão didática.
- Arrastar uma flor da borda com um dedo ou mouse após superar 11 px lógicos de movimento; manter o toque seguido de destino como alternativa e o arrasto do fundo livre como navegação de câmera. A flor central nunca se move. Mostrar destinos ortogonais vazios, encaixe magnético e inclinação/sombra da carta. Fadas e pólens acompanham a carta pelo mesmo referencial visual durante a prévia e o encaixe. Só ao soltar em destino válido e no mesmo turno/partida acionar o fluxo existente de seleção + deslocamento; soltura inválida, pinça, Escape ou perda de foco cancelam o gesto sem movimentar a flor. Não mudar o segundo obrigatório de reposição. A animação após a soltura parte da posição visual arrastada e dura 0,30 s na intensidade normal; preservar a duração anterior do deslocamento por toque.
- Enquadramento: durante o arrasto da mão, coletiva ou flor da borda, aproximar do limite da área do jardim move a câmera gradualmente, proporcionalmente à proximidade, com velocidade limitada e sem alterar o zoom. Preservar controle manual e não mover a câmera automaticamente nas primeiras etapas guiadas.
- Sonoplastia: loop original de 8 s de vento suave e chamados distantes, independente do canal de voo, com volume baixo e redução adicional durante voos. O loop começa apenas na partida, encerra ao sair/pausar/perder foco e respeita áudio_ativo; Web usa o desbloqueio já existente e canal próprio no AudioContext. Não há mídia externa nem mudança no som contínuo de asas da v197.
- Prévia de combinação: avaliar somente a posição candidata do arrasto usando cópia do tabuleiro e o verificador floral já existente, com cache por turno, origem, destino e cor; contornos dourados nas casas da combinação e na carta de objetivo. No deslocamento, avaliar a combinação apenas se a cor de reposição já for conhecida. Não revelar objetivos extras no tutorial: os destaques e dicas já aprovados permanecem. A prévia não contabiliza estrelas ou cria pólens.
- Atmosfera: pétalas oscilam suavemente perto da fada em trânsito, com retorno gradual ao repouso; grama recebe traços direcionais discretos perto da carta arrastada, limitados a nove casas vizinhas e três traços por casa. Manter texturas e sprites existentes.
- Desempenho: reaproveitar textura de grama também em cartas opacas pequenas, cache das prévias durante arrasto, limitação local de efeitos ambientais, consulta Web de ambiente no máximo 5 vezes/s; manter redesenho contínuo durante gestos e frequência reduzida em repouso. Não prometer ganho de FPS medido sem execução.
- Validação: os nove scripts Python anteriores passaram. `tests/testar_v199_arrasto_borda.py` verifica 1.024 cenários independentes de gesto e conservação, 1.620 geometrias de câmera e integração estática das rotinas. Sintaxe da ponte JavaScript conferida com Node.js. Sem execução/compilação do GDScript no Godot ou teste real de toque, áudio e FPS. Conferir especialmente arrasto em zoom máximo, cancelamento por pinça, limites do jardim, o quarto turno guiado, volume e Web/iOS.


## v200 — Tipografia e composição das telas secundárias

- Aumentar a hierarquia tipográfica para evitar textos pequenos e excesso de espaço vazio, mantendo a identidade marrom/dourada e estrelas prateadas. Não modificar a arte proporcional da abertura, as regras, a pontuação, o layout da partida, o tutorial ou os gestos da v199.
- Painéis de resultado, explicação, regras e catálogo utilizam até 860 pixels lógicos de altura (antes 620); o desenho e os controles compartilham a mesma geometria. No viewport padrão 420×920, resultado com título de até 34 px, nomes de até 24 px, estrelas totais de até 37 px, linhas de apuração de até 21 px e contadores de pólens de até 20 px. Valores e rótulos alinhados em lados opostos. Preservar grupos visuais de trincas quando houver espaço, sem sacrificar leitura.
- Manter paginação de dois jogadores por página em telas altas e um por página nas baixas; setas maiores em linha independente do título. Botões de resultado com até 56 px de altura e fontes de 22 px no viewport padrão.
- Apuração dos pólens com cabeçalho de até 33 px, rótulos de cor e quantidade de até 24 px, bônus por cor de até 19 px e total de até 38 px; grupos de pólens centralizados. Preservar duração e cálculo da animação existente.
- Explicação da pontuação organizada em seções com texto de até 22 px e espaçamento entre linhas, mantendo rolagem e botão fixo. Manual de regras com fonte de até 21 px. Menus de modo, participantes e dificuldade com títulos maiores, subtítulos e botões de até 64 px, fontes de até 23 px.
- Aumentar legibilidade dos diálogos de saída, escolha de objetivo e prêmio; manter confirmação de saída e os mesmos callbacks. Ampliar títulos e indicação de fechamento da consulta de objetivo.
- Validação: dez scripts independentes anteriores e novo teste geométrico `tests/testar_v200_tipografia.py` aprovados (546 combinações de resultado/paginação e 63 geometrias de apuração). Funções de apuração, término, regras de entrada, layout da partida e compra conferidas como idênticas à v199. Não houve compilação ou execução no Godot; verificar fontes, quebra de linhas, tamanho mínimo dos Controls e composição no celular antes da publicação.


## v201 — Simulador de partidas e auditoria de balanceamento

- Preservar integralmente o código, as regras, o layout e a pontuação pública da v200. O simulador Python independente importa o catálogo ativo do GDScript e compara a tabela atual com bônus experimental de +1 exclusivamente para objetivos florais, mantendo as categorias fixas e a regra de pólens (1 por unidade, 5 por trinca). Não alterar a tabela pública antes de análise e aprovação.
- Simular partidas de 2, 3 e 4 participantes, perfis jardineiro, coletor e equilibrado, assentos permutados, sementes pareadas e busca configurável. Não confundir políticas heurísticas do simulador com a IA do Godot. Manter a compra oculta sem acesso antecipado à cor, deslocamento com transporte das peças, voo, apuração de objetivos, geração de pólen, prêmio e rodada bônus conforme regras vigentes.
- Resultados de referência: 1080 partidas, 180 por combinação de número de jogadores e tabela, 3240 participantes, 30593 objetivos distribuídos, 540 reapurações das mesmas jogadas. Pólens responderam por 65,68% das estrelas na tabela atual e 61,29% com +1 nos florais (razão entre somas). Alterar somente os valores nas partidas já realizadas modificou o conjunto de ganhadores em 59 de 540. Todas as partidas do lote chegaram ao gatilho de seis objetivos.
- Em quatro jogadores houve pelo menos uma reposição sem candidato elegível em 131/180 partidas atuais e 138/180 com +1. Registrar como alerta de auditoria, ainda não confirmado no motor. Próxima investigação: comparar capacidade dos catálogos e filtros de tipos/cores/IDs/combinações já formadas; rodar políticas homogêneas para vantagem de assento, amostra de candidatos exaustiva e outras sementes.
- Testes: 11 scripts anteriores e `tests/testar_v201_simulador.py` aprovados; conservação das flores e pólens a cada turno, integridade dos resultados e repetibilidade verificadas. Sem execução do Godot, sem teste de pessoas reais; hipóteses e limitações descritas em `simulador/LEIA-ME.md`.


## v202 — Acessibilidade para não gamers e voo com batidas contínuas

- Diretriz vigente e permanente: tornar o Jardim das Fadas amigável para não gamers, reduzir carga cognitiva, escolhas redundantes, interrupções e etapas de confirmação desnecessárias; preservar a profundidade estratégica. Priorizar manipulação direta, informação clara, aprendizagem progressiva e feedback perceptível. Não acrescentar regras nem escolhas especiais sem necessidade.
- Objetivo de fada concede apenas suas estrelas; não concede flor-prêmio, não permite escolher cor livre nem pula a compra normal. Retirar a janela, o estado, a seleção pela IA, a origem especial de compra, os efeitos exclusivos e os textos associados. Manter pontos, reposição de objetivos, métricas, coleta, voos, limite de objetivos e rodada de encerramento.
- Recuperar o foley de asas batendo da v196 (ruído filtrado e fibras), sem voltar às sequências de três batidas com pausa. Loop circular de 2 s, 16 batidas regulares com intensidades alternadas, filtro aquecido circularmente e caudas sobrepostas. Canal único de voo do início ao fim, rampas de decolagem/pouso e notas de coleta sobrepostas; sem reinício por casa. Manter o tempo de voo, as demais animações, a sonoplastia ambiental e o layout. Timbre final depende de escuta em dispositivo real.
- Simulador independente acompanha a nova regra, com conservação estrita das 96 cartas. Os 1080 resultados da v201 são históricos e não sustentam conclusões sobre o novo equilíbrio; novas simulações serão necessárias antes de recalibrar os pontos.

Validação v202: 12 scripts anteriores e `tests/testar_v202_regras_audio.py` aprovados. O novo teste cobre a cadência e a emenda do envelope e seis partidas independentes, com 20 objetivos de fada sem flor-prêmio e uma compra normal por turno. Não houve compilação ou audição no Godot.


## v203 — Solo suspenso e equilíbrio estratégico

- Remover temporariamente a modalidade Solo, incluindo suas metas, recordes, constantes, condição de término e caminhos residuais; Aprender continua individual e progressivo, Duelo Local e Contra a Máquina (2–4 participantes) preservados.
- Diretriz permanente: nenhuma estratégia rígida deve ser claramente dominante. Formar objetivos ou coletar pólens são caminhos competitivos; o perfil equilibrado deve, idealmente, apresentar uma vantagem moderada por saber aproveitar as melhores oportunidades de cada jogada. Equilibrar 2, 3 e 4 jogadores sem exigir uma divisão aritmética de 50/50 das estrelas. Manter a simplicidade para não gamers, preferindo valores inteiros fixos e evitando fórmulas e exceções se os testes permitirem.
- Preservar 1 estrela por pólen e 5 por trinca da mesma cor (3 básicas + 2 bônus). Não aplicar a tabela de pontos oficialmente até aprovação. Separar categoria Médio/Difícil do valor em estrelas antes de aplicar novos pontos; revisar tutorial, manual e IA.
- Simulador: eliminar o incentivo heurístico residual de 0,8 aos objetivos de fada, pois não há flor-prêmio. 3.996 partidas novas, com sementes distintas entre etapas: 432 de triagem, 1.620 de calibração, 1.944 de validação. A tabela seletiva com redução adicional de uma estrela nos florais e valores fixos para fadas preservou a liderança do equilibrado na validação de 2, 3 e 4 participantes; redução uniforme de 1 estrela é benchmark relevante. A tabela completa por modelo, resultados CSV e limites estão em `simulador/RELATORIO_V203.md` e `simulador/proposta_por_objetivo_v203.csv`. Não tratar resultados como equilíbrio definitivo.
- Investigar Pouso contestado (tipo 63): nenhuma conclusão em 369 entregas no controle; o fluxo normal de voo termina em flor nova sem inimiga, portanto recomendação de suspensão/reformulação separada, ainda não implementada. Flor Preciosa (9): 17/375 conclusões. Reposição sem opção elegível em 257/360 partidas de quatro participantes no controle. Confirmar no motor e resolver antes de fechar catálogo físico.
- Validação: os 13 scripts independentes anteriores passaram (assertion histórica do modo Solo atualizada). Sem execução do Godot. Não foi alterado layout, tutorial nem pontuação jogável.


## v204 — Tutorial no ritmo do jogador e saída dentro da mesa

- Posicionar o ícone de porta com seta no canto superior direito **dentro da área marrom do tabuleiro**, com área de toque de 48 px lógicos; a caixa de instruções volta a ocupar toda a largura. Manter confirmação de saída com Cancelar/Sair, acionamento na soltura e comportamento de apuração. O botão sobrepõe apenas o canto da mesa; câmera continua navegável.
- Remover os cronômetros de leitura da v195, seus tempos e barras. As três explicações antes temporizadas (pólens gerados pelo objetivo, pontuação dos pólens e apresentação dos objetivos de fada) permanecem abertas indefinidamente até avanço explícito.
- Na faixa do tutorial, duas setas na lateral direita (voltar e avançar), com áreas de toque independentes. Arrastar horizontalmente para a esquerda equivale a avançar; para a direita, voltar. A página acompanha o gesto, e a mudança por toque ou arrasto desliza a mensagem anterior e a nova em 0,25 s, com recorte no espaço textual. Gestos curtos ou predominantemente verticais não mudam página. Cancelar por multitouch/perda de foco; não encaminhar o gesto à mesa.
- Histórico local de até 120 instruções estáveis já apresentadas; revisão é somente leitura (não desfaz compras, voos, plantios, pontos nem objetivos). Ações obrigatórias não podem ser puladas: a seta de avanço fica indisponível na página atual quando a próxima etapa depende de jogar. Ao voltar à página atual de uma explicação pendente, é necessário avançar uma vez para concluir sua leitura. A dica opcional e a previsão de voo permanecem disponíveis no contexto atual.
- Faixa de tutorial com 92 px lógicos (antes 80), para preservar legibilidade e permitir setas com 42×46 px; partidas comuns mantêm 64 px. Preservar restante do layout, regras, tabela oficial de pontos, simulador e objetivos de balanceamento da v203.
- Validação: 12 scripts independentes anteriores + `tests/testar_v204_tutorial_navegavel.py` (125 cenários); substitui o teste obsoleto do cronômetro v195. Sem motor Godot disponível: compilação, gesto touch em dispositivo real, recorte dos textos e fluidez da transição ainda precisam de validação.

## v205 — Compensação das externalidades e equilíbrio situacional

- Remover definitivamente Flor Preciosa (9) e Pouso Contestado (63), inclusive do simulador e dos verificadores de objetivos. Restam 21 modelos de fada; 15 florais mantidos.
- Preservar fórmulas por quantidade de jogadores para interação com adversários; durante a partida, mostrar somente o valor de estrelas já calculado, não a expressão. Não converter para valores fixos. Manter 1 estrela por pólen e 5 por trinca.
- A vantagem do jogador equilibrado é desejável em todas as configurações (2, 3 e 4); uma vantagem maior em duelos é aceitável. Nenhuma estratégia fixa deve ser claramente dominante. O jogador deve decidir conforme a mesa, com baixa carga cognitiva para não gamers.
- Considerar explicitamente a externalidade dos objetivos florais: acrescentam pólens compartilhados, eventualmente apropriados por adversários. Objetivos de fada, em contrapartida, frequentemente coincidem com coleta que já dá estrelas ao próprio jogador. Compensar essa assimetria no valor dos objetivos, mas não elevar todos indiscriminadamente. Avaliar vitórias por perfil, não impor divisão 50/50 da pontuação.
- O simulador v205 rastreia a origem dos pólens produzidos por objetivos, a coleta própria e rival, o estoque restante e estrelas marginais por coleta (FIFO), incluindo a coleta no mesmo turno de cada conquista. 432 partidas de triagem e 1.296 na segunda rodada. Ver `simulador/RELATORIO_V205.md`, `proposta_por_objetivo_v205.csv` e resultados CSV. Candidata focal: +1 nos florais difíceis 14, 25 e 26; fada 14→3, 25→4, 26→5, 27→4, 45→7, 48→4. Fórmulas e outros valores inalterados. A proposta ainda NÃO é oficial, deve ser aprovada e confirmada em testes futuros.
- Os objetivos removidos e o texto das cartas/regras foram atualizados no jogo. Preservar v204 (tutorial navegável, interface, player feel/juice). Testes Python independentes aprovados; não houve compilação Godot. A reposição insuficiente de objetivos ainda é um risco, especialmente em quatro jogadores.


## v206 — Objetivos mais legíveis e rotação por gesto

- Nas cartas de objetivos florais, aumentar um pouco a saturação visual das flores para melhorar a leitura em tamanhos reduzidos.
- Quando um objetivo floral tiver estruturas separadas, desenhar também molduras quadradas neutras, em marrom, para sugerir as cartas intermediárias cuja cor não importa.
- Remover o ícone de girar objetivo. A rotação agora deve ser feita tocando em qualquer um dos quatro cantos da carta e arrastando em um gesto de giro.
- Ensinar explicitamente esse novo gesto no tutorial.
- Independentemente da orientação visual do objetivo, manter sempre a estrela prateada e o número de pontos no canto superior esquerdo da carta.
- Preservar regras, layout geral, simulador e demais sistemas.
- Validação ainda pendente no Godot; a alteração foi aplicada por inspeção estática do código.


## v207 — Oficialização da recalibragem focal (aprovação do autor)

- Aplicar exatamente a coluna proposta de `simulador/proposta_por_objetivo_v205.csv` aos 36 modelos ativos. Florais difíceis: tipo 14 (A:1,3,8 / B:5) 5→6; tipo 25 (A:1,3,5 / B:4,6) 6→7; tipo 26 (A:1,3 / B:4,5,6) 6→7. Todos os médios e demais difíceis mantidos.
- Fadas: Três Cores 4→3; Quatro Flores 5→4; Cinco Flores 7→5; Coleta em Quatro Flores 6→4; Reta Longa 8→7; Cores Distantes 5→4. Demais fadas preservadas, inclusive fórmulas de adversários e exibição apenas do valor calculado. Flor Preciosa e Pouso Contestado continuam excluídos.
- Preservar 1 estrela por pólen e 5 por trinca, geração de pólens pelos objetivos florais, nenhuma flor-prêmio, regras de fim e tutorial. Categorias Médio/Difícil pelo tipo ativo, não pelo valor numérico (etiquetas internas legadas 46 e 78). As faixas atuais continuam 3–4 e 5–7.
- Simulador padrão importa automaticamente os valores oficiais. Calibradores históricos mantêm a referência anterior à v207, evitando aplicar duas vezes os ajustes; CSVs e relatórios v205 permanecem históricos. A aprovação torna oficial a candidata focal, mas não constitui validação humana do balanceamento. Reposição insuficiente continua como investigação separada.
- Preservar integralmente a interface e os gestos v206. Teste `tests/testar_v207_pontuacao.py` confere todos os modelos ativos e fórmulas em 2, 3 e 4 jogadores, comparando controle histórico e proposta.

- Validação v207: 15 scripts Python independentes aprovados após atualizar a referência obsoleta do teste v191 ao gesto de rotação introduzido na v206. Sem compilação no Godot.


## v208 — Passe de acabamento visual profissional

- Identificados alguns pontos que faziam o jogo parecer menos profissional: painéis muito chapados, profundidade visual discreta, barras e botões com pouco relevo e algumas áreas funcionais com aparência excessivamente utilitária.
- Aplicado um passe de polimento visual no sistema de UI, sem mudar regras nem a organização da tela: paineis ganharam bordas mais refinadas, brilho superior sutil, base mais escura e sombras mais elegantes.
- Botões arredondados receberam melhor contraste, sensação de materialidade e estados de hover/pressão mais ricos.
- Placar lateral, faixa de compra e área de objetivos passaram a usar molduras mais nobres e linhas divisórias suaves.
- Barras do placar ganharam fundo mais elegante e brilho sutil no preenchimento.
- Cartões do resultado final receberam maior presença visual e acabamento melhor, especialmente para o vencedor.
- Diretriz permanente reforçada: buscar aspecto de produto comercial de alto nível, priorizando legibilidade, consistência e sensação de acabamento.


## v209 — Player Feel / Player Juice e prioridade Web mobile

- Diretriz: distribuição inicialmente via Itch.io, sobretudo em celulares. Priorizar resposta imediata, leitura e estabilidade em lugar de excesso de partículas e animações decorativas. Manter o mesmo jogo, tutorial navegável, layout retrato, acessibilidade a não gamers e valores oficiais v207.
- Giro de objetivos: gesto angular contínuo a partir de qualquer canto, nos dois sentidos; encaixe na orientação de 90° mais próxima na soltura, com animação residual suave; tocar brevemente inclusive no canto abre consulta. Desenho e molduras neutras acompanham o giro; estrela/pontos permanecem fixos no topo esquerdo. Sem círculos de giro permanentes; só realce de cantos durante gesto e lição. Validar token, turno e ID; cancelar no multitouch, perda de foco ou Escape.
- Encaixe de cartas: cantos destacados em destino válido (dourado quando há conclusão prevista), vibração discreta quando disponível, com limite de frequência. Flor de borda solta em local inválido volta em 0,22 s sem mutação de mesa; fadas/pólens seguem o referencial visual da carta. Compras irreversíveis e verificadores oficiais mantidos. Nenhuma informação de solução adicional em tutorial.
- Web mobile inicia em modo leve adaptativo. Reduz brisa decorativa em repouso, quantidade de partículas/rastro, uma camada de poeira da abertura e frequência de redesenhos em espera. Usa histerese de 2 amostras abaixo de 42 FPS e 8 a partir de 56 FPS; restaurar qualidade se houver margem. A meta é 60 FPS, não uma garantia. Animações de interação seguem por frame; relógios, áudio contínuo e regras intactos.
- Cache de destinos por estado da mesa; fila incremental de prévia global de objetivos, com limites cooperativos de 1,2/2,4 ms por fatia (um candidato pode ultrapassar o orçamento); chave inclui partida, turno, jogador, flor, tabuleiro e mão de objetivos. Prévia local continua pelos validadores existentes. IA conserva todas as alternativas, mas cede frames a cada 1,8/3,5 ms entre planos. Caches de desenhos por tipo/orientação e medidas de texto limitadas a 512 entradas. Textura de grama reutilizada com UV proporcional no recorte/transparência. Máscaras de halo (4 × 420 × 531) pré-geradas, equivalentes ao canal alfa original, evitando 892.080 iterações de pixels na abertura. Refinamento de bordas e sombras da v208, com chave de cache incluindo espessura.
- Preset Web: Compatibility, single-thread, extensões desativadas, exportar index.html em release; excluir testes, documentação e simulador da distribuição Web. Projeto completo mantém tudo para desenvolvimento. Guia de Itch.io em LEIA-ME.md. Não confundir ZIP fonte com ZIP Web exportado.
- Validação: 16 scripts Python independentes aprovados, incluindo novo teste de 2.904 trajetórias angulares, 511 fronteiras × 4 fatias, 892.080 pixels de máscaras e inspeção de integração. Sem Godot instalado; não houve compilação, execução Web real, perfil de desempenho nem teste em dispositivo. Testar em Chrome Android e Safari iOS antes de publicar.


## v210 — Comando discreto de giro dos objetivos

- Substitui a diretriz anterior de giro pelos quatro cantos: apenas a região superior direita das cartas de objetivos florais aciona a rotação. Duas setas curvas discretas, uma terminando à esquerda (anti-horária), outra para baixo (horária). Sem círculos nem caixas nos cantos, inclusive durante a lição e o gesto.
- Toque em uma seta gira 90° no respectivo sentido, com animação; arrasto a partir da região conserva o giro contínuo v209. Toque no restante da carta consulta o objetivo; pontuação e estrela prateada permanecem no topo esquerdo, com espaço reservado às setas. Fadas e cartas não interativas não recebem setas.
- Tutorial e regras explicativas ensinam o novo comando; realce azul apenas nas setas quando necessário. Nenhuma alteração de regras, valores, layout geral ou configuração Web.
- Testes geométricos independentes e integração estática; execução no Godot ainda pendente.


## v211 — Seta de rotação com duas pontas

- Substituir as duas setas separadas por um único traço curvo, aberto, com uma ponta orientada à esquerda e outra para baixo, no canto superior direito. Manter o tom discreto e o realce azul didático.
- Preservar toque na metade esquerda/direita para giro anti-horário/horário, arrasto angular, área de consulta, pontuação fixa, regras e otimizações Web mobile. Atualizar instruções para o símbolo singular.
- Validação geométrica independente e inspeção estática; sem execução no Godot.


## v212 — Seta circular de referência

- Adotar o formato da seta dupla da referência enviada pelo autor, girada 180°: arco circular (não elíptico), pontas à esquerda e para baixo, extremidades arredondadas. Manter o bege da v211 e realce azul didático.
- Seta sempre no canto superior direito; estrela prateada e pontuação sempre no canto superior esquerdo, inclusive durante o arrasto e a animação de encaixe. Apenas a geometria do objetivo gira. Preservar toque e arrasto, tutorial, regras e otimizações Web mobile.
- Teste geométrico independente atualizado; aparência e execução no Godot pendentes.


## v213 — Ações diretas, sem botões redundantes

- Eliminar os botões Jogar uma Flor e Mover Flor e Jogar, inclusive sua criação e seus rótulos de etapas. Não reintroduzir esses controles: comprar, plantar e deslocar diretamente nas cartas e no jardim. Preservar seleção automática de ação, compras irreversíveis, tutorial e Cancelar quando aplicável. Manter geometria geral, placar, regras e perfil Web mobile.
- Validação estática e testes independentes, sem execução no motor.

## v214 — Correção do identificador de previsão

- Erro reportado pelo autor: identificador `feel_previa_ids` não declarado em `v209_desenhar_encaixe`. Corrigido para `feel_previsao_ids`, já declarado e atualizado pelos validadores de previsão. Não criar um segundo estado paralelo.
- Novo teste estático de regressão verifica a referência e a existência textual das declarações de identificadores dos subsistemas de interação. Não equivale à compilação Godot.
- Preservar v213: ações diretas sem os botões Jogar uma Flor e Mover Flor e Jogar, regras, tutorial, símbolo de rotação e configurações Web.


## v215 — Seta curvada no formato da referência

- Adotar na carta de objetivo o formato exato da seta curvada de referência aprovada: uma única seta grossa, curvada, com início horizontal à esquerda e ponta no trecho final descendo para a direita, sem rotações adicionais.
- Preservar a mesma cor bege já usada no símbolo de rotação.
- Manter a seta sempre fixa no canto superior direito do cabeçalho e a estrela com pontuação sempre no canto superior esquerdo, independentemente da rotação do desenho floral.
- O gesto e o toque para girar continuam restritos à região superior direita da carta.


## v216 — Rotação sem elemento visual

- Diretriz vigente, substituindo v210–v215: remover toda seta, círculo ou indicador visual de rotação da carta, inclusive no tutorial e durante o gesto. Manter o cabeçalho limpo.
- A região superior direita permanece interativa, sem desenho: cada toque gira 90° no sentido horário; o arrasto angular existente continua nos dois sentidos. A consulta ampliada permanece no restante da carta.
- Ensinar explicitamente por mensagens do tutorial e das regras. Estrela e pontos permanecem no topo esquerdo; somente o desenho gira. Preservar realces gerais de objetivo, regras, layout e otimizações Web.
- Validação independente em Python, sem execução no Godot.
