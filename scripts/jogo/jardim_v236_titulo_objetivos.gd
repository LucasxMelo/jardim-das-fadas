extends Node2D
# Jardim das Fadas v233 — retrato mais compacto, com jardim menos alto.
# Controlador autônomo da cena principal.
const FUNDO_MENU_RETRATO: Texture2D = preload("res://assets/menu/tela_inicial_retrato.png")
# Setup 3x3: seis permutações de cores e duas orientações.
# Substitua scripts/jogo/jardim.gd pelo conteúdo deste arquivo.
# Mantém as texturas em res://assets/ existentes no projeto original.



# ==== MÓDULO: dados/catalogos.gd ====
# Dados imutáveis das regras, objetivos florais e objetivos de fada.

const PERFIS_MAQUINA: Dictionary = {
	"medio": {"alternativa": 0.06, "margem": 3.0, "risco_baralho": 0.0},
	"dificil": {"alternativa": 0.0, "margem": 0.0, "risco_baralho": 0.0}
}
# Objetivos de Fada da Expandida: somente coleta, percursos, posicionamento
# e interação com fadas inimigas. A mecânica de produzir pólens nas flores
# permanece; não existem objetivos que exijam polinizar.
const OBJETIVOS_FADA_MODELOS: Dictionary = {
	# Coleta e voo: o pólen recolhido também vale pontos no encerramento.

	10: {"titulo": "TRÊS FLORES", "descricao": "Recolha pólen de 3 flores no mesmo voo.", "pontos": 3},
	14: {"titulo": "TRÊS CORES", "descricao": "Recolha as 3 cores no mesmo voo.", "pontos": 3},
	25: {"titulo": "QUATRO FLORES", "descricao": "Passe por 4 flores no mesmo voo.", "pontos": 4},
	26: {"titulo": "CINCO FLORES", "descricao": "Passe por 5 flores no mesmo voo.", "pontos": 5},
	27: {"titulo": "COLETA EM QUATRO FLORES", "descricao": "Recolha pólen de 4 flores diferentes no mesmo voo.", "pontos": 4},
	# Posicionamento: basta um voo do jogador na jogada da conquista;
	# NUNCA exigir histórico de voos das duas fadas desde o recebimento.
	41: {"titulo": "DUAS VERMELHAS", "descricao": "Voe e termine a vez com suas 2 fadas em flores vermelhas distintas.", "pontos": 5},
	42: {"titulo": "DUAS AMARELAS", "descricao": "Voe e termine a vez com suas 2 fadas em flores amarelas distintas.", "pontos": 5},
	43: {"titulo": "DUAS LILASES", "descricao": "Voe e termine a vez com suas 2 fadas em flores lilases distintas.", "pontos": 5},
	44: {"titulo": "RETA DISTANTE", "descricao": "Voe e termine a vez com suas fadas em linha reta, separadas por pelo menos 2 cartas.", "pontos": 5},
	45: {"titulo": "RETA LONGA", "descricao": "Voe e termine a vez com suas fadas em linha reta, separadas por pelo menos 4 cartas.", "pontos": 7},
	46: {"titulo": "DIAGONAL DISTANTE", "descricao": "Voe e termine a vez com suas fadas em diagonal, separadas por pelo menos 2 cartas.", "pontos": 6},
	47: {"titulo": "DIAGONAL LONGA", "descricao": "Voe e termine a vez com suas fadas em diagonal, separadas por pelo menos 3 cartas.", "pontos": 8},
	48: {"titulo": "CORES DISTANTES", "descricao": "Voe e termine a vez com suas fadas em flores de cores diferentes, distantes pelo menos 3 casas.", "pontos": 4},
	49: {"titulo": "EXTREMIDADES", "descricao": "Voe e termine a vez com suas fadas em bordas opostas do jardim, distantes pelo menos 4 casas.", "pontos": 7},
	# Adversarios: X - Nº jogadores; Quebra: X + Nº jogadores.
	# Proibidos nos tutoriais, por filtro no sorteio.
	61: {"titulo": "CERCO", "descricao": "Voe e termine a vez com uma fada inimiga entre suas duas fadas em linha reta ou diagonal contínua de flores.", "pontos_base": 9},

	64: {"titulo": "APROXIMAÇÃO ESTRATÉGICA", "descricao": "Voe e termine a vez numa flor vizinha, em linha reta, à de uma fada inimiga.", "pontos_base": 6},
	65: {"titulo": "DESLOCAMENTO FORÇADO", "descricao": "Mova uma carta de flor levando junto uma fada inimiga.", "pontos_base": 6},
	66: {"titulo": "MANOBRA COMBINADA", "descricao": "Mova uma carta levando uma fada inimiga e voe com sua fada na mesma vez.", "pontos_base": 8},
	67: {"titulo": "QUEBRA DE ALINHAMENTO", "descricao": "Voe e termine a vez sem se alinhar a inimigas, saindo de uma linha ou coluna antes compartilhada.", "pontos_base": 4, "formula_soma": true},
	69: {"titulo": "CONFRONTO DIAGONAL", "descricao": "Voe e termine a vez em diagonal com uma fada inimiga, a pelo menos 3 casas.", "pontos_base": 7},
	70: {"titulo": "INTERPOSIÇÃO", "descricao": "Voe e termine a vez entre as duas fadas de um adversário, em linha reta ou diagonal contínua de flores.", "pontos_base": 9}
}

# v104: únicos Médios que não podem ser concluídos pelo primeiro jogador
# em uma única jogada no setup fixo (plantio ou deslocamento, com todas as cores).
# O tipo 23 vale 4 em ambas as versões e está disponível entre os Médios.
const TIPOS_MEDIOS_ABERTURA_SEGURA: Array = [5, 11, 15, 17, 19, 23]
const TIPOS_DIFICEIS_ATIVOS: Array = [13, 14, 21, 24, 25, 26, 28, 29, 30]
# Molde de posições: sorteiam-se a correspondência V/A/L e a orientação 0°/90°.
const SETUP_FIXO_NOVE_FLORES: Array = [
	"vermelha", "amarela", "lilas",
	"amarela", "lilas", "vermelha",
	"lilas", "vermelha", "amarela"
]

# Modelos florais compartilhados pelas três modalidades.
const MODELOS_OBJETIVO: Dictionary = {
	1: {
		"quadrantes": [4, 5, 6],
		"padrao": ["A", "B", "A"],
		"pontos": 2,
		"tamanho": "pequeno",
		"rotacionar": true,
		"espelhar": false
	},
	2: {
		"quadrantes": [2, 4, 5],
		"padrao": ["A", "A", "B"],
		"pontos": 2,
		"tamanho": "pequeno",
		"rotacionar": true,
		"espelhar": false
	},
	3: {
		# Quadrantes 3 e 7 na cor A; quadrante 5 na cor B.
		"quadrantes": [3, 5, 7],
		"padrao": ["A", "B", "A"],
		"pontos": 3,
		"tamanho": "pequeno",
		"rotacionar": true,
		"espelhar": false
	},
	4: {
		# Quadrantes 5 e 9 na cor A; quadrantes 6 e 8 na cor B.
		"quadrantes": [5, 6, 8, 9],
		"padrao": ["A", "B", "B", "A"],
		"pontos": 4,
		"tamanho": "grande",
		"rotacionar": true,
		"espelhar": false
	},
	5: {
		# Quadrantes 5 e 6 na cor A; quadrantes 8 e 9 na cor B.
		"quadrantes": [5, 6, 8, 9],
		"padrao": ["A", "A", "B", "B"],
		"pontos": 3, # v104: objetivo tipo 5 passa a Médio (4 pontos).
		"tamanho": "grande",
		"rotacionar": true,
		"espelhar": false
	},
	6: {
		# Quadrantes 4 e 6 na cor A; quadrante 8 na cor B.
		"quadrantes": [4, 6, 8],
		"padrao": ["A", "A", "B"],
		"pontos": 3,
		"tamanho": "pequeno",
		"rotacionar": true,
		"espelhar": false
	},
	8: {
		# Cruz de quatro flores bicolores; passa à faixa dificil
		# para manter um bom estoque nessa faixa depois de excluir o tipo 7.
		"quadrantes": [2, 4, 6, 8],
		"padrao": ["A", "A", "B", "B"],
		"pontos": 4,
		"tamanho": "grande",
		"rotacionar": true,
		"espelhar": false
	},
	# Objetivos Grandes compartilhados: sete formatos adicionais; equivalentes
	# por rotacao geram apenas uma carta no catalogo.
	11: { # Cruz incompleta: 2/5 A e 4/6 B
		"quadrantes": [2, 5, 4, 6], "padrao": ["A", "A", "B", "B"],
		"pontos": 3, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	12: { # Quadrado 3+1
		"quadrantes": [1, 2, 4, 5], "padrao": ["A", "A", "A", "B"],
		"pontos": 3, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	15: { # Duas colunas separadas: 4 e 7 A; 6 e 9 B
		"quadrantes": [4, 7, 6, 9], "padrao": ["A", "A", "B", "B"],
		"pontos": 4, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	17: { # Centro superior e medio A; cantos inferiores 7 e 9 B
		"quadrantes": [2, 5, 7, 9], "padrao": ["A", "A", "B", "B"],
		"pontos": 4, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	18: { # Cruz incompleta 3+1: topo e laterais A; centro B.
		# Representa também o antigo desenho 5/7/9 A e 8 B,
		# equivalente por translação; não criar uma carta repetida.
		"quadrantes": [2, 4, 5, 6], "padrao": ["A", "A", "B", "A"],
		"pontos": 5, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	19: { # 2/8 X; 7/9 Y
		"quadrantes": [2, 8, 7, 9], "padrao": ["A", "A", "B", "B"],
		"pontos": 4, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	20: { # 3 e 7 em A; 6 e 8 em B.
		"quadrantes": [3, 7, 6, 8], "padrao": ["A", "A", "B", "B"],
		"pontos": 5, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},

	13: { # Quatro cantos: X 1/3; Y 7/9. Difícil somente na Original.
		"quadrantes": [1, 3, 7, 9], "padrao": ["A", "A", "B", "B"],
		"pontos": 6, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	14: { # X 1/3/8; Y 5. Desenho original 3+1 restaurado na v109.
		"quadrantes": [1, 3, 8, 5], "padrao": ["A", "A", "A", "B"],
		"pontos": 6, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	21: { # X 1/9; Y 6/8. Difícil somente na Original.
		"quadrantes": [1, 9, 6, 8], "padrao": ["A", "A", "B", "B"],
		"pontos": 5, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	22: { # X 1/6/8; Y 9. Difícil somente na Original.
		"quadrantes": [1, 6, 8, 9], "padrao": ["A", "A", "A", "B"],
		"pontos": 8, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	24: { # X 3/7; Y 5/9. Difícil somente na Original.
		"quadrantes": [3, 7, 5, 9], "padrao": ["A", "A", "B", "B"],
		"pontos": 5, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},

	# v110: novos Difíceis de CINCO flores; posições relativas, rotação permitida.
	25: { # Candidato A: X 1,3,5; Y 4,6.
		"quadrantes": [1, 3, 5, 4, 6], "padrao": ["A", "A", "A", "B", "B"],
		"pontos": 7, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	26: { # Arco Bicolor: X 1,3; Y 4,5,6.
		"quadrantes": [1, 3, 4, 5, 6], "padrao": ["A", "A", "B", "B", "B"],
		"pontos": 7, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	27: { # Cinco Pontas: X 1,5,9; Y 3,7.
		"quadrantes": [1, 5, 9, 3, 7], "padrao": ["A", "A", "A", "B", "B"],
		"pontos": 8, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},

	# v112 — três novos Difíceis de cinco flores; rotação permitida, sem espelho.
	28: { # Cruz Bicolor: X 4, 5; Y 2, 6, 8.
		"quadrantes": [4, 5, 2, 6, 8], "padrao": ["A", "A", "B", "B", "B"],
		"pontos": 7, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	29: { # Cantos e Laterais: X 3, 7, 9; Y 6, 8.
		"quadrantes": [3, 7, 9, 6, 8], "padrao": ["A", "A", "A", "B", "B"],
		"pontos": 7, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	30: { # Diagonal e Laterais: X 3, 5, 7; Y 6, 8.
		"quadrantes": [3, 5, 7, 6, 8], "padrao": ["A", "A", "A", "B", "B"],
		"pontos": 7, "tamanho": "grande", "rotacionar": true, "espelhar": false
	},
	23: { # X 4/6; Y 7/9. 6 pontos em ambas as versões; Médio seguro (v108).
		"quadrantes": [4, 6, 7, 9], "padrao": ["A", "A", "B", "B"],
		"pontos": 4, "tamanho": "grande", "rotacionar": true, "espelhar": false
	}
}



# ==== MÓDULO: dados/estado.gd ====
## Estado e constantes partilhados pelas camadas do jogo.
# Alterações de regras devem ser feitas conscientemente; os nomes públicos foram preservados.


const APRENDER_MAX_JOGADAS: int = 8
# Normal/Difícil identificam apenas os níveis da Máquina.
# As cartas de objetivo são Pequenas (3 flores) ou Grandes (4 ou 5 flores).
const DUELO_META_OBJETIVOS: int = 6

# v217: Aprender é um duelo didático contra as Pretas. O motor competitivo
# permanece o mesmo; somente a abertura é protegida e as dicas são graduais.
# v133: orientação visual obrigatória antes da segunda conquista humana.
const AULA_TURNO_ROTACAO: int = 5
const AULA_TURNOS_GUIADOS: int = 4
const AULA_TURNOS_DEMONSTRACAO: int = 3
# Abertura didática: três flores por cor, sem cartas extras nem pólens adicionais.
const AULA_SETUP_NOVE_FLORES: Array = [
	"vermelha", "lilas", "vermelha",
	"lilas", "amarela", "vermelha",
	"lilas", "amarela", "amarela"
]
const AULA_FADAS_INICIAIS: Array[Vector2i] = [Vector2i(1, 1), Vector2i(-1, 1)]
const AULA_ROTACAO_ALTERNATIVA: Dictionary = {"id": "gamer:15:vermelha:lilas", "giro": 2, "casas": [Vector2i(0, 2), Vector2i(0, 1), Vector2i(-2, 2), Vector2i(-2, 1)]}
const AULA_ALTERNATIVA: Array = [
	{"dono": 0, "fonte": "aberta", "cor": "lilas", "origem": Vector2i(99999, 99999), "destino": Vector2i(0, -2), "fada": -1, "voo": "", "objetivo": "gamer:11:lilas:vermelha"},
	{"dono": 0, "fonte": "baralho", "cor": "lilas", "origem": Vector2i(99999, 99999), "destino": Vector2i(-1, -2), "fada": 1, "voo": "straight", "objetivo": ""},
	{"dono": 0, "fonte": "baralho", "cor": "lilas", "origem": Vector2i(99999, 99999), "destino": Vector2i(-2, -2), "fada": 0, "voo": "diag", "objetivo": ""},
	{"dono": 0, "fonte": "aberta", "cor": "vermelha", "origem": Vector2i(-2, -2), "destino": Vector2i(-2, -1), "fada": -1, "voo": "", "objetivo": "", "licao": "preparar_coleta"},
]
const AULA_ALTERNATIVA_INICIAL: Array = [["gamer:11:lilas:vermelha"]]
const AULA_ALTERNATIVA_REPOSICOES: Dictionary = {
	0: ["gamer:15:vermelha:lilas"],
}
const CARTAS_POR_COR: int = 32
const MAX_POLENS_POR_CARTA: int = 4
const TAMANHO_CARTA: float = 88.0
const TAXA_AMOSTRAGEM_AUDIO: int = 22050
const CORES: Array[String] = ["vermelha", "amarela", "lilas"]
# Versao Gamer: preservar o motor de Pintura de Flor, mas nao oferecer o poder.
# Para reativar futuramente, alterar esta constante e restaurar a aula extra.
const PINTURA_GAMER_ATIVA: bool = false
const OBJETIVOS_FADA_COPIAS: Dictionary = {} # Tipos de baixa pontuação removidos; cada objetivo restante possui uma cópia.
# Meta, observada em UM voo. Os identificadores respeitam o catalogo combinado.
const VIZINHOS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0),
	Vector2i(0, 1), Vector2i(0, -1)
]
const COR_TEXTO: Color = Color("fff5e5")
const COR_TEXTO_FRACO: Color = Color("cec4b3")
const COR_OURO: Color = Color("f1d49a")
const COR_PRATA: Color = Color("d8dde6")
const COR_PRATA_BRILHO: Color = Color("f6fbff")
const ICONE_ESTRELA_VITORIA: String = "★"
# Todos os controles clicaveis, inclusive os desenhados sobre a mesa, sao verdes.
const COR_BOTAO_VERDE: Color = Color("236b42")
const COR_BOTAO_VERDE_HOVER: Color = Color("2e9056")
const COR_BOTAO_VERDE_PRESSIONADO: Color = Color("155533")
const COR_BOTAO_VERDE_DESABILITADO: Color = Color("335c43")
const COR_BOTAO_VERDE_BORDA: Color = Color("4b9c69")

# CADASTRO DE FORMATOS — SOMENTE OBJETIVOS FLORAIS BICOLORES.
# Modelos antigos: tipos 1, 2, 3, 4, 5, 6 e 8.
# Modelos Grandes adicionais compartilhados: tipos 11 a 17 (15, 16, 17 novos).
# Grade 3x3 de referencia:
#     1 2 3
#     4 5 6
#     7 8 9
# Em todos os formatos, A e B sao cores obrigatoriamente diferentes.
# Cada modelo oferece seis pares ordenados (3 opcoes A x 2 opcoes B).
# Pares que representem o mesmo desafio apos rotacao geram somente UMA carta.
# padrao[i] corresponde a quadrantes[i], na mesma ordem.
# rotacionar=true aceita as quatro orientacoes; espelhar=false nao
# aceita reflexoes (preservadas as regras dos tipos 1 e 2).
var sorteador: RandomNumberGenerator = RandomNumberGenerator.new()
# v220: todas as flores usam a mesma ilustração com miolo da cor das pétalas.
const PERF_FLORES = {
	"vermelha": preload("res://assets/cache_visual/flor_objetivo_vermelha.png"),
	"amarela": preload("res://assets/cache_visual/flor_objetivo_amarela.png"),
	"lilas": preload("res://assets/cache_visual/flor_objetivo_lilas.png")
}
const PERF_POLENS = {
	"vermelha": preload("res://assets/cache_visual/polen_vermelha.png"),
	"amarela": preload("res://assets/cache_visual/polen_amarela.png"),
	"lilas": preload("res://assets/cache_visual/polen_lilas.png"),
	"branca": preload("res://assets/cache_visual/polen_branca.png")
}
const PERF_GRAMA = [preload("res://assets/cache_visual/grama_48.png"), preload("res://assets/cache_visual/grama_96.png"), preload("res://assets/cache_visual/grama_192.png")]
var perf_layout_chave: Array = []
var perf_fundo: Node2D
var perf_fundo_tela: Vector2 = Vector2.ZERO
var perf_fundo_inicio: bool = false
var perf_textos: Dictionary = {}
# v209: caches exclusivamente visuais, limitados e sem mutar o jogo.
var v209_geometrias: Dictionary = {}
var v209_fontes: Dictionary = {}
var v209_candidatas: Array[Vector2i] = []
var v209_previsao_fila: Array[Vector2i] = []
var v209_previsao_cursor: int = 0
var v209_candidatas_chave: Array = []
var v209_leve: bool = false
var v209_amostra: float = 0.0
var v209_lento: int = 0
var v209_rapido: int = 0
var v209_encaixe: Vector2i = Vector2i(99999, 99999)
var v209_encaixe_inicio: float = -10.0
var v209_encaixe_som: float = -10.0
var v209_retorno_borda: Dictionary = {}
var perf_pulso_idle: float = 0.0
var perf_audio_web_proximo: float = 0.0
var perf_debug: Label
var perf_debug_tempo: float = 0.0
# v218: design tokens de interface (não alteram as cores das flores ou fadas).
const UI_FUNDO: Color = Color("201f1b")
const UI_PAINEL: Color = Color("302e28")
const UI_SUPERFICIE: Color = Color("39362e")
const UI_BORDA: Color = Color("766b55")
const UI_MESA: Color = Color("40382e")
const UI_ACAO: Color = Color("315c42")
const UI_ACAO_HOVER: Color = Color("3c6e50")
const UI_ACAO_PRESSIONADA: Color = Color("264734")
var ui_insets: Vector4 = Vector4.ZERO
var fonte: Font
var fonte_destaque: FontVariation
var _ui_paineis: Dictionary = {}
var _ui_botoes: Dictionary = {}
var tabuleiro: Dictionary = {} # Vector2i -> "grama" ou cor da flor.
var baralho: Array[String] = []
var flor_aberta: String = ""
var flor_na_mao: String = "" # Carta selecionada; esvaziada ao encaixar a flor no jardim.
var origem_carta_selecionada: String = "" # "aberta" ou "baralho".
# Textura independente: cor aplicada somente ao corpo; asas brancas.
# Recurso externo: res://assets/fadas/fada_cinza.png

# Textura independente: cor aplicada somente ao corpo; asas brancas.
# Recurso externo: res://assets/fadas/fada_marrom.png

var jogadores: Array[Dictionary] = []
# Miniaturas de fadas, sobre as cartas do jardim.
# Cada entrada: dono (indice do jogador), numero (1/2), casa (Vector2i).
var fadas: Array[Dictionary] = []
var textura_verso_baralho: Texture2D = null # PNG do verso do baralho, em memoria.
var texturas_fadas: Dictionary = {} # 0 preta, 1 branca (asas cinzas), 2 cinza, 3 marrom; demais asas brancas.
var texturas_fadas_voo: Dictionary = {} # corpo e asas separados, apenas durante o voo.
# Máscaras com transparência idêntica aos PNGs das fadas: brilho no contorno real,
# sem anéis/círculos sobre o tabuleiro. Criadas uma vez na inicialização.
var mascaras_silhueta_fadas: Dictionary = {}
var imagens_fadas_para_hit_test: Dictionary = {}
# Cada flor pode guardar varios polens (todos da cor da flor).
# A chave e a casa atual; os polens acompanham a flor se ela for deslocada.
var polens_por_casa: Dictionary = {} # Vector2i -> quantidade de polens
var ids_cartas: Dictionary = {} # Vector2i -> id estavel da flor, mesmo que se mova
var proximo_id_carta: int = 0
# ID das flores cujo primeiro polen JA EXISTE, mas ainda nao esta visivel.
# A espera de 1 s afeta apenas o desenho, nunca a coleta ou a pontuacao.
var polen_inicial_pendente: Dictionary = {} # id_carta -> true (apenas visual)
var fada_em_movimento: int = -1
# Oferta de movimento da fada, apos a flor ser colocada no jardim.
var etapa_fada: String = ""  # "", "oferta", "escolha", "movendo"
var fadas_elegiveis: Array[int] = []
var destino_da_fada: Vector2i = Vector2i(99999, 99999)
var jogada_alteradas_pendentes: Array[Vector2i] = []
var jogada_estado_anterior_pendente: Dictionary = {}
var jogada_casa_reposta_pendente: Vector2i = Vector2i(99999, 99999)
var cartas_catalogo_visual: Array[Dictionary] = []
var pagina_catalogo: int = 0
var botao_catalogo_anterior: Button
var botao_catalogo_proximo: Button
# IDs de TODAS as cartas ja aparecidas na partida.
# Os catalogos removem variantes equivalentes por rotacao e cada carta
# restante tem ID proprio, sem repeticao durante a partida.
# Compartilhado pelos jogadores; so reinicia em novo_jogo().
var objetivos_ja_sorteados: Dictionary = {}
var jogador_atual: int = 0
var turnos_jogados: int = 0
var partida_encerrada: bool = false
# Duelo: conquistar um objetivo abre uma rodada bônus para cada jogador.
# O adversario joga primeiro, e o autor da conquista joga em seguida:
# nunca ha duas jogadas consecutivas de um mesmo participante.
# Conquistas nessa rodada nao acumulam novas rodadas bônus.
var rodada_bonus_ativa: bool = false
var rodada_bonus_etapa: int = 0 # Compatibilidade visual com o contador exibido da rodada bônus.
var rodada_bonus_autor: int = -1
var rodada_bonus_fila: Array[int] = []
var quantidade_maquinas_partida: int = 1 # Todas as versões: de 1 a 3 rivais autonomos.
# Guarda os IDs das CARTAS de objetivo concluidas nesta partida.
# Nao bloqueia futuros objetivos diferentes que usem as mesmas casas.
var linhas_pontuadas: Dictionary = {}
var mensagem: String = ""
var zoom: float = 1.0
var deslocamento: Vector2 = Vector2.ZERO
var mouse_pos: Vector2 = Vector2.ZERO
var arrastando: bool = false  # Reservado (pan pelo mouse direito foi removido).
var celula_mouse: Vector2i = Vector2i(99999, 99999)

# Segunda opcao de jogada: mover uma flor vizinha antes de encaixar a comprada.
# A carta central nunca pode ser deslocada. A flor comprada ocupa a origem.
const CELULA_INVALIDA: Vector2i = Vector2i(99999, 99999)
var modo_movimento: bool = false
var origem_selecionada: Vector2i = CELULA_INVALIDA
var movimento_pendente: bool = false
var origem_movimento: Vector2i = CELULA_INVALIDA
var destino_movimento: Vector2i = CELULA_INVALIDA
var cor_movida: String = ""
var tabuleiro_antes_movimento: Dictionary = {}
var aguardando_reposicao_automatica: bool = false
var identificador_partida: int = 0
var identificador_movimento: int = 0  # Invalida o timer se a jogada for cancelada.

# Abertura cinematica, somente visual: o estado real do jogo ja esta pronto.
# Cartas iniciais estão todas visíveis; a sequência de entrada anima somente fadas.
# Cada chegada acontece a cada 0,5 segundo, em todos os modos.
const INTERVALO_ANIMACAO_SETUP: float = 0.5
const DURACAO_ENTRADA_SETUP: float = 0.28
var animacao_setup_ativa: bool = false
var animacao_setup_etapa: int = 0
var animacao_setup_tempo: float = 0.0

# Anima a carta escolhida indo para o espaço "CARTA ESCOLHIDA".
# Coletiva: desloca diretamente.
# Baralho: primeiro revela a carta (desvirando), depois a move.
const DURACAO_ANIMACAO_CARTA_COLETIVA: float = 0.26
const DURACAO_ANIMACAO_REVELAR_BARALHO: float = 0.22
const DURACAO_ANIMACAO_MOVER_CARTA_ESCOLHIDA: float = 0.28
# v150: efeitos cosméticos, separados da lógica e do RNG da partida.
var juice_nivel: int = 1 # 0 reduzidas, 1 normais, 2 cinematográficas
var juice_relogio: float = 0.0
var juice_efeitos: Dictionary = {}
var juice_particulas: Array[Dictionary] = []
var juice_rotacoes: Dictionary = {}
var juice_entradas: Dictionary = {}
var juice_mao_anterior: Dictionary = {}
# v185: camada de feedback, sem participação no cálculo das regras.
var juice_ganhos_placar: Dictionary = {}
var juice_ultima_vibracao: float = -10.0
var juice_notas_voo: int = 0
var juice_arquivo: Dictionary = {}
var juice_voo: Dictionary = {}
# Animações cosméticas de prontidão e retorno ao repouso, por miniatura.
var juice_fada_prontidao: Dictionary = {}
var juice_mover: Dictionary = {}
# v160: estados exclusivamente visuais, separados dos estoques e mãos reais.
var juice_reserva_refluxo: Dictionary = {}
var juice_reserva_pousos: Array[Dictionary] = []
var juice_transicao_objetivos: Dictionary = {}
var juice_plantar: Dictionary = {}
var juice_repor: Dictionary = {}
var juice_modal: String = ""
var juice_modal_inicio: float = -10.0
var juice_modal_retangulo: Rect2
var juice_fim: float = -10.0
var juice_final_expandida_inicio: float = -10.0
var juice_final_expandida_duracao: float = 2.8
var juice_ultima_pressao: Vector2 = Vector2(-9999, -9999)
var juice_pressao_tempo: float = -10.0
var juice_erro_tempo: float = -10.0
var juice_erro_casa: Vector2i = Vector2i(99999, 99999)
var juice_cancelar_tempo: float = -10.0
var juice_cancelar_casa: Vector2i = Vector2i(99999, 99999)
var juice_serie: int = 0
var animacao_compra_ativa: bool = false
var animacao_compra_fonte: String = "" # "aberta" ou "baralho"
var animacao_compra_cor: String = ""
var animacao_compra_tempo: float = 0.0

# Tela inicial ilustrada: brilho suave, partículas e pequenos movimentos decorativos.
var tempo_animacao_abertura: float = 0.0
var capa_animada: Sprite2D
var material_abertura: ShaderMaterial
var abertura_visivel: bool = false
var abertura_tela_anterior: Vector2 = Vector2.ZERO

var celebracao_objetivo_ativa: bool = false
var celebracao_objetivo_casas: Array[Vector2i] = []
var celebracao_objetivo_indice: int = -1
var celebracao_objetivo_jogador: int = -1
var polens_novos_ampliados: Dictionary = {} # casa -> indice do unico polen recem-criado
var polens_em_tamanho_duplo: bool = false

# Variaveis legadas de animacao; a Gamer ativa a duplicacao apenas no final. Nao confundir com a
# polinizacao (que acrescenta polens no jardim quando um objetivo e concluido).
const INTERVALO_DUPLICACAO_POLEN: float = 0.5
var duplicacao_ativa: bool = false
var duplicacao_indice_jogador: int = -1
var duplicacao_indice_historico: int = -1
var duplicacao_voo_ativo: bool = false
var duplicacao_voo_cor: String = ""
var duplicacao_voo_inicio: Vector2 = Vector2.ZERO
var duplicacao_voo_destino: Vector2 = Vector2.ZERO
var duplicacao_voo_tempo: float = 0.0
var duplicacao_polen_ultimo_indice: int = -1
var duplicacao_polen_ultimo_tempo: float = 0.0

var layout_paisagem: bool = false
var area_tabuleiro: Rect2
var area_dica_aprender: Rect2
var area_compra: Rect2
var area_contadores_polens: Rect2
var area_objetivos: Rect2 # Informacoes e objetivos do jogador atual.
var area_historico: Rect2 # Área reservada para placar.
var area_janela_conquistas: Rect2
var botao_fechar_conquistas: Rect2
var botao_anterior_conquistas: Rect2
var botao_proximo_conquistas: Rect2
var conquistas_abertas: bool = false
var conquistas_jogador: int = -1
var conquistas_controles_atras: Dictionary = {}
var pagina_historico: Array[int] = [0, 0]
# Revisao visual, exclusivamente de leitura: um retrato da mesa no setup e
# depois de cada jogada completa, com suas flores, fadas e polens.
var cenarios_anteriores: Array[Dictionary] = []
var indice_cenario_em_revisao: int = -1 # -1 = mesa atual, sem revisao.
# Tutorial: snapshots completos permitem desfazer/refazer uma jogada real.
var indice_estado_tutorial: int = -1
# Revisao do placar: somente leitura, inclusive depois de a partida terminar.
var revisao_final_ativa: bool = false
var botao_historico_anterior: Button
var botao_historico_proximo: Button
var area_aberta: Rect2
var area_baralho: Rect2
var area_mao: Rect2
var area_acoes_gamer: Rect2 = Rect2() # Faixa interna de ações do painel unificado de compra.
var botao_novo: Rect2
var botao_encerrar: Rect2
var saida_pressionada: bool = false
var cancelar_voo_press: Vector2i = Vector2i(-1, -1)
var confirmacao_saida: ColorRect
var caixa_confirmacao_saida: PanelContainer
var botao_cancelar_saida: Button
var botao_confirmar_saida: Button
var pausa_saida_ativa: bool = false
# Botoes nativos Control/Button: os cliques nao dependem de Rect2.has_point().

# SISTEMA DE AUDIO: efeitos sintetizados na inicializacao (nenhum loop).
var audio_ativo: bool = true
var amostras_som: Dictionary = {} # id -> AudioStreamWAV gerado em memoria.
var canais_som: Array[AudioStreamPlayer] = []
# Canal exclusivo do voo: uma única vibração contínua, nunca disparos de papel.
var canal_voo_beija_flor: AudioStreamPlayer
var voo_audio_web_ativo: bool = false
var voo_audio_volume: float = -60.0
var voo_audio_pitch: float = 0.85
var audio_web_disponivel: bool = false
var audio_aula_polens_aplicados: int = 0
var audio_trincas_final_tocou: bool = false

# Telas e modos de jogo. Ambos compartilham o mesmo tabuleiro e objetivos.
var estado_tela: String = "inicio"  # inicio, regras, escolha_modo, escolha_maquina, partida, resultado, explicacao_pontuacao
var modo_partida: String = "duelo"  # aprender, duelo, maquina
var aula_duelo: bool = false # Aprender: duelo contra uma única máquina (Pretas).
var aula_aviso_licao_partida: int = -1
var aula_aviso_licao_tipo: String = ""
var aula_aviso_licao_carta: Dictionary = {}
var aula_aviso_licao_controles: Dictionary = {}
# v204: páginas de instrução visitadas, sem voltar o estado da partida.
var aula_nav_historico: Array[Dictionary] = []
var aula_nav_indice: int = -1 # -1 = instrução atual
var aula_nav_atual: Dictionary = {}
var aula_nav_visual: Dictionary = {}
var aula_nav_clip: Control
var aula_nav_canvas: Node2D
var aula_nav_pressao: bool = false
var aula_nav_pressao_bloqueada: bool = false
var aula_nav_inicio: Vector2 = Vector2.ZERO
var aula_nav_botao: int = 0
var aula_nav_desvio: float = 0.0
var aula_nav_saida: Dictionary = {}
var aula_nav_direcao: int = 0
var aula_nav_anim_t: float = 0.0
var aula_nav_anim_de: float = 0.0
var aula_nav_animando: bool = false
var aula_nav_token: int = -1
var aula_aviso_fada_partida: int = -1
var aula_aviso_fada_controles: Dictionary = {}
var aula_ultima_instrucao: String = ""
# Ajuda voluntária: calculada apenas ao tocar em Dica, nunca a cada quadro.
var aula_ajuda_turno: int = -1
var aula_ajuda_cor: String = ""
var aula_ajuda_plano: Dictionary = {}
var aula_ajuda_solicitada: bool = false
# As duas versoes compartilham interface e tabuleiro, mas nao as regras novas.
const versao_nova: bool = true
const versao_gamer_progressiva: bool = false
# false/false = Original; true/false = Expandida.
var catalogo_objetivos_grandes: Array[Dictionary] = []
# Baralho de objetivos de Fada: tipos de coleta, posicionamento e confronto.
var objetivos_fada_sorteados: Dictionary = {}

# Escolha de objetivos simultaneamente concluidos (somente jogadores humanos).
var escolha_objetivo_ativa: bool = false
var escolha_objetivo_opcoes: Array[Dictionary] = []
var escolha_objetivo_jogador: int = -1
var painel_escolha_objetivo: ColorRect
var caixa_escolha_objetivo: PanelContainer
var titulo_escolha_objetivo: Label
var botoes_escolha_objetivo: Array[Button] = []

# Telemetria local para balanceamento. Nao interfere nas regras e pontuacoes.
# Registrada apenas nas partidas competitivas e não nos tutoriais.
var metricas_objetivos_fada: Dictionary = {}
var polens_gastos_no_voo_pendente: int = 0
var metricas_partida_gravadas: bool = false
# Estatisticas exclusivas do ultimo voo da jogada (zeradas entre turnos).
var registro_voo_fada: Dictionary = {}
# Eventos da jogada: somente a ação REAL (não prévias/simulações) os altera.
var inimigo_deslocado_na_jogada: bool = false
var deslocamento_inimigo_pendente: bool = false
var escolhas_iniciais_pendentes: bool = false
var alvo_transformacao: Vector2i = Vector2i(99999, 99999)
var fada_diagonal_pendente: int = -1
var botao_poder_pular: Button
var botoes_poder_cores: Dictionary = {}
# Mini-janela desenhada no Node2D, com flores clicaveis, sem botoes textuais.
var janela_pintura_retangulo: Rect2 = Rect2()
var escolhas_flores_pintura: Dictionary = {}
var texto_pontuacao_original: String = ""
# Interface de ações: sem Voo Livre em qualquer modalidade.
var acao_nova: String = "" # "", "plantar", "mover", "poderes", "diagonal_fada", "diagonal_destino", "pintar_alvo", "pintar_cor"
var botoes_acao_nova: Dictionary = {}
var tutorial_novo_primeira_fada: int = -1
# Guia dos dois voos finais: a fada da direita vai e volta pelo mesmo diagonal.
var tutorial_voo_fada_indice: int = -1
var tutorial_voo_fada_origem: Vector2i = Vector2i(3, 1)
var tutorial_rotacao_pronta: bool = false
var tutorial_rotacao_configurada: bool = false
var tutorial_final_pendente: bool = false
var tutorial_pratica_livre: bool = false
# Cada coleta em qualquer modalidade exibe a mesma animacao de retorno a reserva.
var animacoes_coleta_aula: Array[Dictionary] = []
const DURACAO_BRILHO_COLETA_AULA: float = 0.9
# Janela flutuante: arrastar segurando a faixa do titulo (nao move as cartas).
var tutorial_painel_posicao: Vector2 = Vector2(-1.0, -1.0)
var tutorial_painel_retangulo: Rect2 = Rect2()
var tutorial_painel_titulo: Rect2 = Rect2()
var tutorial_painel_arrastando: bool = false
var tutorial_painel_ancora: Vector2 = Vector2.ZERO
var fada_poder_preselecionada: int = -1
const TUTORIAL_POSICAO_X: Vector2i = Vector2i(0, -2)
# Dez jogadas reais; a nona etapa apenas gira uma carta e NAO gasta turno.
# Oito jogadas de flores e duas com objetivos de coleta das fadas.
const TUTORIAL_NOVO_JOGADAS: int = 10
const TUTORIAL_NOVO_ETAPAS: int = 10
const TUTORIAL_GAMER_ETAPAS: int = 8

# Duelo vs Maquina: apenas medio (Normal) e dificil.
var dificuldade_maquina: String = "medio"
# Válido apenas durante o sorteio das cartas iniciais de objetivo.
var sorteando_objetivos_iniciais: bool = false
var tutorial_etapa: String = ""
# O botao Voltar revisita explicacoes, mas NUNCA desfaz ou repete jogadas.
# -1 = seguir a etapa real; 1..17 = instrucao antiga exibida em leitura.
var tutorial_passo_consulta: int = -1
var tutorial_passo_maximo: int = 1
var resultado_titulo: String = ""
var resultado_detalhes: String = ""
var pagina_resultado: int = 0
var botao_resultado_anterior: Button
var botao_resultado_proximo: Button
var botao_abertura_aprender: Button
var botao_abertura_jogar: Button
var botao_regras_voltar: Button
var texto_regras_completas: RichTextLabel
var botao_menu_duelo: Button
var botao_menu_maquina: Button
var botao_maquinas_1: Button
var botao_maquinas_2: Button
var botao_maquinas_3: Button
var botao_maquinas_voltar: Button
var botao_maquina_medio: Button
var botao_maquina_dificil: Button
var botao_maquina_voltar: Button
var maquina_ocupada: bool = false
var botao_menu_voltar: Button
var botao_resultado_inicio: Button
var botao_pontuacao_entenda: Button
var botao_pontuacao_voltar: Button
var texto_pontuacao_explicacao: RichTextLabel
# Arrastar a mesa com o dedo ou botao esquerdo; toque curto = colocar carta.
# v177: intenções transitórias, nunca alteram cartas ou pontuação.
var mobile_fonte_pressionada: int = -1 # 0 baralho, 1 coletiva
var mobile_token_compra: int = -1
var mobile_turno_compra: int = -1
var mobile_ajustando_plantio: bool = false
var mobile_token_tabuleiro: int = -1
var mobile_turno_tabuleiro: int = -1
var mobile_casa_pressionada: Vector2i = Vector2i(99999, 99999)
var mobile_fada_pressionada: int = -1
var mobile_dedos: Dictionary = {}
var mobile_gesto_cancelado: bool = false
var mobile_constelacao_floral: bool = false
# v187: gesto de mão e consulta são apenas estados visuais.
var mobile_arrastando_mao: bool = false
var mobile_arrastando_coletiva: bool = false
# v199: deslocamento por arrasto mantém o modelo intacto até a soltura.
var mobile_borda_arrastada: Vector2i = CELULA_INVALIDA
var feel_inicio_deslocamento: Dictionary = {}
var feel_previa_casas: Dictionary = {}
var feel_previa_arrasto_chave: Array = []
var ambiente_canal: AudioStreamPlayer
var ambiente_web_ativo: bool = false
var ambiente_foco: bool = true
var ambiente_proximo: float = 0.0
var feel_vento_centro: Vector2 = Vector2.ZERO
var feel_vento_ativo: bool = false
var feel_vento_forca: float = 0.0
var mobile_inicio_compra: Vector2 = Vector2.ZERO
# v190: estados exclusivamente visuais, sem alterar reservas ou tabuleiro.
var feel_pos: Vector2 = Vector2.ZERO
var feel_alvo: Vector2 = Vector2.ZERO
var feel_angulo: float = 0.0
var feel_inclinacao_alvo: float = 0.0
var feel_retorno: Dictionary = {}
var feel_origem_plantio: Dictionary = {}
var feel_estrelas: Array[Dictionary] = []
var feel_trincas: Array[Dictionary] = []
var feel_final_por_regra: bool = false
var feel_turno: int = -1
var feel_turno_anterior: int = -1
var feel_turno_inicio: float = -10.0
var feel_previsao_chave: Array = []
var feel_previsao_ids: Dictionary = {}
var mobile_objetivo_press: int = -1
var mobile_objetivo_giro_indice: int = -1
var mobile_objetivo_giro_inicio: Vector2 = Vector2.ZERO
var mobile_objetivo_giro_centro: Vector2 = Vector2.ZERO
var mobile_objetivo_giro_angulo_inicial: float = 0.0
var v209_giro_angulo: float = 0.0
var v209_giro_ultimo: float = 0.0
var v209_giro_token: int = -1
var v209_giro_turno: int = -1
var v209_giro_id: String = ""
var mobile_objetivo_ampliado: Dictionary = {}
var mobile_objetivo_fechar_press: bool = false
var mobile_objetivo_controles: Dictionary = {}
var camera_chave_v187: Array = []
var camera_manual_ate: float = -1.0
var camera_alvo_zoom: float = 1.0
var camera_alvo_offset: Vector2 = Vector2.ZERO
var camera_ajustando: bool = false
var toque_tabuleiro: bool = false
var toque_arrastou: bool = false
var inicio_toque: Vector2 = Vector2.ZERO
var ultimo_toque: Vector2 = Vector2.ZERO
# Interface integrada: nenhuma aba oculta a compra, o jardim ou os objetivos.
var interface_compacta: bool = false
var dispositivo_mobile_web: bool = false
var alterando_escala_compacta: bool = false
var pontos_multitoque: Dictionary = {}
var gesto_multitoque_ativo: bool = false

# ==== MÓDULO: recursos/texturas.gd ====
## Carregamento de texturas externas; mantém máscaras e hit-test das fadas.

func carregar_textura_verso_baralho() -> void:
	# A referência preload garante inclusão na exportação para Web/itch.io.
	textura_verso_baralho = preload("res://assets/cartas/verso_baralho.png")
	if textura_verso_baralho == null:
		push_warning("Verso do baralho indisponível. Usando desenho de reserva.")

func carregar_texturas_fadas() -> void:
	# Texturas importadas pela Godot, sem decodificação Base64 durante a execução.
	# Indices de textura: 0 preta, 1 branca, 2 cinza, 3 marrom.
	# O jogador principal (indice 0 de jogadores) sempre usa a textura 1: branca,
	# unica com asas cinzas. As demais possuem asas brancas do mesmo tom.
	texturas_fadas.clear()
	texturas_fadas_voo.clear()
	mascaras_silhueta_fadas.clear()
	imagens_fadas_para_hit_test.clear()
	var recursos: Array[Texture2D] = [
		preload("res://assets/fadas/fada_preta.png"),
		preload("res://assets/fadas/fada_branca.png"),
		preload("res://assets/fadas/fada_cinza.png"),
		preload("res://assets/fadas/fada_marrom.png")
	]
	var halos: Array[Texture2D] = [
		preload("res://assets/cache_visual/halo_fada_preta.png"),
		preload("res://assets/cache_visual/halo_fada_branca.png"),
		preload("res://assets/cache_visual/halo_fada_cinza.png"),
		preload("res://assets/cache_visual/halo_fada_marrom.png"),
	]
	var camadas_voo: Array = [
		[preload("res://assets/fadas/fada_preta_corpo.png"), preload("res://assets/fadas/fada_preta_asa_esq.png"), preload("res://assets/fadas/fada_preta_asa_dir.png")],
		[preload("res://assets/fadas/fada_branca_corpo.png"), preload("res://assets/fadas/fada_branca_asa_esq.png"), preload("res://assets/fadas/fada_branca_asa_dir.png")],
		[preload("res://assets/fadas/fada_cinza_corpo.png"), preload("res://assets/fadas/fada_cinza_asa_esq.png"), preload("res://assets/fadas/fada_cinza_asa_dir.png")],
		[preload("res://assets/fadas/fada_marrom_corpo.png"), preload("res://assets/fadas/fada_marrom_asa_esq.png"), preload("res://assets/fadas/fada_marrom_asa_dir.png")]
	]
	for indice_cor in range(recursos.size()):
		var textura: Texture2D = recursos[indice_cor]
		if textura == null:
			push_warning("Textura da fada %d indisponível." % indice_cor)
			continue
		var imagem: Image = textura.get_image()
		if imagem == null or imagem.is_empty():
			push_warning("Falha ao ler a textura da fada %d." % indice_cor)
			continue
		imagem.convert(Image.FORMAT_RGBA8)
		imagens_fadas_para_hit_test[indice_cor] = imagem
		texturas_fadas[indice_cor] = textura
		texturas_fadas_voo[indice_cor] = camadas_voo[indice_cor]
		mascaras_silhueta_fadas[indice_cor] = halos[indice_cor]



# ==== MÓDULO: tabuleiro/geometria.gd ====
## Regras geométricas e normalização rotacional dos objetivos.

func assinatura_rotacional_objetivo(objetivo: Dictionary) -> String:
	var modelo: Dictionary = MODELOS_OBJETIVO[int(objetivo["tipo"])]
	var posicoes: Array[Vector2i] = posicoes_do_modelo(modelo)
	var padrao: Array = modelo["padrao"]
	var quantidade_rotacoes: int = 4 if bool(modelo.get("rotacionar", true)) else 1
	var quantidade_espelhos: int = 2 if bool(modelo.get("espelhar", false)) else 1
	var melhor_assinatura: String = ""
	for indice_espelho in range(quantidade_espelhos):
		for rotacao in range(quantidade_rotacoes):
			var casas: Array[Vector2i] = []
			var menor_x: int = 999999
			var menor_y: int = 999999
			for posicao in posicoes:
				var transformada: Vector2i = transformar_posicao(posicao, rotacao, indice_espelho == 1)
				casas.append(transformada)
				menor_x = mini(menor_x, transformada.x)
				menor_y = mini(menor_y, transformada.y)
			var partes: Array[String] = []
			for i in range(casas.size()):
				var casa: Vector2i = casas[i]
				var cor: String = cor_da_marca(objetivo, str(padrao[i]))
				partes.append("%d,%d:%s" % [casa.x - menor_x, casa.y - menor_y, cor])
			partes.sort()
			var atual: String = ""
			for parte in partes:
				atual += "|" + parte
			if melhor_assinatura == "" or atual < melhor_assinatura:
				melhor_assinatura = atual
	return melhor_assinatura

func coordenada_do_quadrante(quadrante: int) -> Vector2i:
	# 1 = (-1,-1); 5 = (0,0); 9 = (1,1).
	var coluna: int = (quadrante - 1) % 3
	var linha: int = floori(float(quadrante - 1) / 3.0)
	return Vector2i(coluna - 1, linha - 1)

func posicoes_do_modelo(modelo: Dictionary) -> Array[Vector2i]:
	var saida: Array[Vector2i] = []
	var quadrantes: Array = modelo["quadrantes"]
	for quadrante in quadrantes:
		saida.append(coordenada_do_quadrante(int(quadrante)))
	return saida

func cor_da_marca(objetivo: Dictionary, marca: String) -> String:
	return str(objetivo["cor_a"]) if marca == "A" else str(objetivo["cor_b"])

func transformar_posicao(posicao: Vector2i, rotacao: int, espelhado: bool) -> Vector2i:
	var resultado: Vector2i = posicao
	if espelhado:
		resultado.x = -resultado.x
	for _passo in range(rotacao):
		resultado = Vector2i(-resultado.y, resultado.x)
	return resultado

func chave_da_combinacao(tipo: int, casas: Array[Vector2i]) -> String:
	var partes: Array[String] = []
	for casa in casas:
		partes.append("%d,%d" % [casa.x, casa.y])
	partes.sort()
	var chave: String = str(tipo)
	for parte in partes:
		chave += "|" + parte
	return chave

func trajetoria_ortogonal(origem: Vector2i, destino: Vector2i) -> bool:
	return origem != destino and (origem.x == destino.x or origem.y == destino.y)

func trajetoria_diagonal(origem: Vector2i, destino: Vector2i) -> bool:
	var diferenca: Vector2i = destino - origem
	return origem != destino and absi(diferenca.x) == absi(diferenca.y)

func nome_cor(cor: String) -> String:
	match cor:
		"vermelha": return "vermelha"
		"amarela": return "amarela"
		"lilas": return "lilás"
	return cor

func cor_da_flor(cor: String) -> Color:
	match cor:
		"vermelha": return Color("e85e67")
		"amarela": return Color("f1ca55")
		"lilas": return Color("b78be4")
	return Color.WHITE



# ==== MÓDULO: regras/modalidades.gd ====
## Identificação das três modalidades. Não há mais Voo Livre.

func eh_gamer() -> bool:
	return false

func eh_alternativa() -> bool:
	return true

func nome_versao_atual() -> String:
	return "JARDIM DAS FADAS"

func tem_voo_livre() -> bool:
	return false # Nenhuma versão possui ação independente de Voo Livre.

func permite_diagonal_ao_jogar_flor() -> bool:
	return eh_gamer() or eh_alternativa()



# ==== MÓDULO: jogo/jardim.gd ====
## Jardim das Fadas v92 — controlador principal.
# As regras da versão 67 foram preservadas; recursos externos e módulos auxiliares
# evitam analisar centenas de KB de PNG em Base64 ao abrir este script.

func progresso_entrada_setup() -> float:
	return clampf(animacao_setup_tempo / DURACAO_ENTRADA_SETUP, 0.0, 1.0)

func instrucoes_setup() -> String:
	if animacao_setup_etapa <= 4:
		return "Jardim pronto. As fadas estão chegando."
	return "Preparando o Jardim: fada %d de %d" % [
		mini(animacao_setup_etapa - 4, fadas.size()), fadas.size()]

func iniciar_animacao_setup() -> void:
	# As cartas ja sao mostradas: apenas as fadas aparecem por etapas.
	# Nenhuma regra do jogo depende da animacao das fadas.
	animacao_setup_ativa = true
	# Mantemos apenas a chegada sequencial das fadas.
	animacao_setup_etapa = 4
	animacao_setup_tempo = 0.0
	tocar_som("inicio")
	queue_redraw()

func atualizar_animacao_setup(delta: float) -> void:
	if not animacao_setup_ativa:
		return
	if estado_tela != "partida" or partida_encerrada:
		animacao_setup_ativa = false
		return
	animacao_setup_tempo += delta
	if animacao_setup_tempo >= INTERVALO_ANIMACAO_SETUP:
		# Avanca uma unica entrada por vez, mesmo apos queda de FPS.
		# Mantem o intervalo de meio segundo sem sobrepor varias chegadas.
		animacao_setup_tempo = 0.0
		animacao_setup_etapa += 1
		if animacao_setup_etapa <= 4 + fadas.size():
			tocar_som("entrada_fada", 0.97 + 0.02 * float((animacao_setup_etapa - 5) % 4))
		else:
			animacao_setup_ativa = false
			animacao_setup_etapa = 4 + fadas.size()
			sincronizar_botoes_menu()
			pass
	queue_redraw()

# Celebracao das conquistas: 2 segundos de bordas amarelas.
# Os novos polens aparecem TODOS JUNTOS no inicio: por 1 segundo, cada
# unidade nova e desenhada em dobro; no segundo seguinte fica no tamanho
# padrao. O objetivo so passa ao historico apos os 2 segundos completos.
# O espaco permanece vazio por mais 1 segundo antes da reposicao.
func controles_revisao_no_pc() -> bool:
	return false # v171: sem controles de revisão/retrocesso em qualquer dispositivo.

func deve_usar_interface_compacta(_tamanho: Vector2) -> bool:
	return true

func configurar_interface_por_dispositivo() -> void:
	var janela: Window = get_window()
	if janela == null or alterando_escala_compacta:
		return
	alterando_escala_compacta = true
	# Escala proporcional sem deformação: retrato até em uma janela larga.
	# Limitar a altura lógica reduz a verticalização; telas mais longas mantêm proporção, sem esticar a mesa.
	var real: Vector2 = Vector2(janela.size)
	var altura: int = clampi(roundi(420.0 * real.y / maxf(1.0, real.x)), 740, 820) if real.x > 0.0 and real.y > 0.0 else 820
	var logica: Vector2i = Vector2i(420, altura)
	janela.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	janela.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	janela.content_scale_factor = 1.0
	if janela.content_scale_size != logica:
		janela.content_scale_size = logica
	ui_insets = Vector4.ZERO
	# Safe area nativa (notch, recorte e barra de gestos). Na Web a área
	# disponível depende do canvas/HTML do exportador; não supor insets nativos.
	if OS.has_feature("mobile") and not OS.has_feature("web") and real.x > 0.0 and real.y > 0.0:
		var segura: Rect2 = Rect2(DisplayServer.get_display_safe_area())
		var tela_fisica: Rect2 = Rect2(Vector2.ZERO, Vector2(DisplayServer.screen_get_size(janela.current_screen)))
		if segura.has_area() and tela_fisica.has_area():
			var escala: float = minf(real.x / float(logica.x), real.y / float(logica.y))
			var barra: Vector2 = (real - Vector2(logica) * escala) * 0.5
			var proporcao: Vector2 = real / tela_fisica.size
			var inicio: Vector2 = segura.position * proporcao
			var fim: Vector2 = (tela_fisica.end - segura.end) * proporcao
			ui_insets = Vector4(clampf((inicio.x - barra.x) / escala, 0.0, 45.0), clampf((inicio.y - barra.y) / escala, 0.0, 75.0), clampf((fim.x - barra.x) / escala, 0.0, 45.0), clampf((fim.y - barra.y) / escala, 0.0, 75.0))
	alterando_escala_compacta = false

func ui_area_segura() -> Rect2:
	var tela: Vector2 = get_viewport_rect().size
	# Margens simétricas preservam a centralização das telas e dos modais.
	var horizontal: float = maxf(ui_insets.x, ui_insets.z)
	var vertical: float = maxf(ui_insets.y, ui_insets.w)
	return Rect2(Vector2(horizontal, vertical), tela - Vector2(horizontal, vertical) * 2.0)

func tratar_gestos_de_toque(event: InputEvent) -> bool:
	if not interface_compacta or estado_tela != "partida":
		if event is InputEventScreenTouch and not event.pressed:
			pontos_multitoque.erase(event.index)
			if pontos_multitoque.is_empty():
				gesto_multitoque_ativo = false
		return false
	if event is InputEventMagnifyGesture:
		if area_tabuleiro.has_point(event.position):
			mudar_zoom(clampf(event.factor, 0.72, 1.35), event.position)
			get_viewport().set_input_as_handled()
			return true
	if event is InputEventScreenTouch:
		if event.pressed:
			if not area_tabuleiro.has_point(event.position):
				return false
			pontos_multitoque[event.index] = event.position
			if pontos_multitoque.size() > 1:
				gesto_multitoque_ativo = true
				mobile_limpar_intencao()
				toque_arrastou = true
				get_viewport().set_input_as_handled()
				return true
		else:
			pontos_multitoque.erase(event.index)
			if pontos_multitoque.is_empty():
				gesto_multitoque_ativo = false
		return false
	if event is InputEventScreenDrag and pontos_multitoque.has(event.index):
		var tamanho_anterior: float = 0.0
		var centro_anterior: Vector2 = Vector2.ZERO
		var indices: Array = pontos_multitoque.keys()
		if indices.size() >= 2:
			var primeira: Vector2 = pontos_multitoque[indices[0]]
			var segunda: Vector2 = pontos_multitoque[indices[1]]
			tamanho_anterior = primeira.distance_to(segunda)
			centro_anterior = (primeira + segunda) * 0.5
		pontos_multitoque[event.index] = event.position
		if indices.size() >= 2:
			var nova_primeira: Vector2 = pontos_multitoque[indices[0]]
			var nova_segunda: Vector2 = pontos_multitoque[indices[1]]
			var centro_novo: Vector2 = (nova_primeira + nova_segunda) * 0.5
			if area_tabuleiro.has_point(centro_novo):
				mobile_camera_manual()
				deslocamento += centro_novo - centro_anterior
				if tamanho_anterior > 12.0:
					mudar_zoom(clampf(nova_primeira.distance_to(nova_segunda) / tamanho_anterior, 0.78, 1.28), centro_novo)
				else:
					queue_redraw()
			get_viewport().set_input_as_handled()
			return true
	return false

# A partida, os tutoriais e os menus usam a MESMA janela em tela cheia.
# Em computadores a configuracao inicial do project.godot tambem e Fullscreen.
# No navegador, a permissao para fullscreen depende de uma acao do usuario.
func configurar_tela_cheia_desktop() -> void:
	configurar_interface_por_dispositivo()
	if OS.has_feature("web") or OS.has_feature("mobile") or not (OS.get_name() in ["Windows", "Linux", "macOS"]):
		return
	var janela: Window = get_window()
	var util: Rect2i = DisplayServer.screen_get_usable_rect(janela.current_screen)
	var fator: float = minf(float(util.size.x) * 0.90 / 420.0, float(util.size.y) * 0.92 / 820.0)
	janela.mode = Window.MODE_WINDOWED
	janela.size = Vector2i(Vector2(420, 820) * maxf(0.25, fator))
	janela.position = util.position + Vector2i(Vector2(util.size - janela.size) * 0.5)

# ============================================================================
# PREPARACAO DO JOGO E CATALOGO DE OBJETIVOS
# ============================================================================
func _ready() -> void:
	# A abertura não depende de JS, de detecção de dispositivo nem de áudio.
	configurar_tela_cheia_desktop()
	sorteador.randomize()
	fonte = ThemeDB.fallback_font
	fonte_destaque = FontVariation.new()
	fonte_destaque.base_font = fonte
	fonte_destaque.variation_embolden = 0.32
	carregar_texturas_fadas()
	carregar_textura_verso_baralho()
	perf_criar_fundo()
	criar_capa_animada()
	criar_botoes_historico()
	criar_botoes_menu()
	mostrar_botoes_abertura()
	criar_botoes_poder()
	criar_botoes_acao_nova()
	criar_painel_escolha_de_objetivos()
	criar_confirmacao_saida()
	aula_nav_criar()
	montar_catalogo_objetivos_grandes()
	atualizar_layout()
	get_viewport().size_changed.connect(_ao_redimensionar_tela)
	queue_redraw()
	# Só depois que o menu está pronto, inicializar recursos opcionais.
	call_deferred("preparar_recursos_opcionais")

func preparar_recursos_opcionais() -> void:
	# Preparar primeiro o áudio nativo, sem depender de JavaScript.
	preparar_audio()
	if OS.has_feature("web"):
		# Evita eval na detecção: usa o objeto navegador diretamente.
		var navegador: JavaScriptObject = JavaScriptBridge.get_interface("navigator")
		if navegador != null:
			var agente: String = str(navegador.userAgent).to_lower()
			dispositivo_mobile_web = "android" in agente or "iphone" in agente or "ipad" in agente or "ipod" in agente or "mobile" in agente
			if str(navegador.platform) == "MacIntel" and DisplayServer.is_touchscreen_available():
				dispositivo_mobile_web = true
	v209_leve = OS.has_feature("web") and mobile_tem_toque()
	configurar_interface_por_dispositivo()
	atualizar_layout()
	queue_redraw()
	# O PC mantém a reprodução nativa da v120, que já funcionava.
	# A ponte Web é apenas um complemento para aparelhos móveis.
	if OS.has_feature("web") and (dispositivo_mobile_web or OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("web_mobile") or DisplayServer.is_touchscreen_available()):
		call_deferred("preparar_audio_web")

func _ao_redimensionar_tela() -> void:
	if alterando_escala_compacta:
		return
	configurar_interface_por_dispositivo()
	# Preservar o estado, o zoom e a câmera quando girar o celular.
	atualizar_layout()
	if aula_duelo_ativa():
		aula_enquadrar_jardim()
	atualizar_posicao_escolha_de_objetivos()
	atualizar_posicao_confirmacao_saida()
	queue_redraw()

func _process(delta: float) -> void:
	v209_atualizar_qualidade(delta)
	aula_nav_atualizar(delta)
	juice_atualizar(delta)
	v199_camera_arrasto(delta)
	feel_atualizar(delta)
	v199_atualizar_ambiente(delta)
	mobile_camera_inteligente(delta)
	atualizar_som_demonstracao_aula()
	if estado_tela == "resultado" and eh_alternativa() and not audio_trincas_final_tocou and juice_relogio - juice_fim >= 0.65:
		audio_trincas_final_tocou = true
		for dados in jogadores:
			if int(dados.get("bonus_trios", 0)) > 0:
				tocar_som("coleta_4")
				break
	var pulso_compra_ativo: bool = estado_tela == "partida" and (pode_realcar_fonte_compra(false) or pode_realcar_fonte_compra(true))
	if animacao_compra_ativa:
		var tempo_compra_anterior: float = animacao_compra_tempo
		animacao_compra_tempo += delta / juice_fator_tempo()
		if animacao_compra_fonte == "baralho":
			if tempo_compra_anterior < DURACAO_ANIMACAO_REVELAR_BARALHO * 0.5 and animacao_compra_tempo >= DURACAO_ANIMACAO_REVELAR_BARALHO * 0.5:
				tocar_som("papel_virar")
		var duracao_animacao: float = DURACAO_ANIMACAO_CARTA_COLETIVA if animacao_compra_fonte == "aberta" else (DURACAO_ANIMACAO_REVELAR_BARALHO + DURACAO_ANIMACAO_MOVER_CARTA_ESCOLHIDA)
		if animacao_compra_tempo >= duracao_animacao:
			animacao_compra_ativa = false
			animacao_compra_fonte = ""
			animacao_compra_cor = ""
			animacao_compra_tempo = 0.0
		queue_redraw()
	if estado_tela == "inicio":
		atualizar_animacao_menu(delta)
	# Setup: cartas ja visiveis; apenas a entrada das fadas e animada.
	if animacao_setup_ativa and not aula_aviso_licao_ativo():
		atualizar_animacao_setup(delta)
	# Cada unidade chega à reserva no seu próprio instante e toca seu som.
	if not animacoes_coleta_aula.is_empty():
		for i in range(animacoes_coleta_aula.size() - 1, -1, -1):
			var lote: Dictionary = animacoes_coleta_aula[i]
			lote["tempo"] = float(lote["tempo"]) + delta
			var quantidade: int = int(lote["quantidade"])
			var chegados: int = int(lote.get("chegados", 0))
			var duracao: float = float(lote.get("duracao_unidade", DURACAO_BRILHO_COLETA_AULA))
			var intervalo: float = float(lote.get("intervalo", 0.0))
			var primeira_chegada: int = chegados
			while chegados < quantidade and float(lote["tempo"]) >= duracao + float(chegados) * intervalo:
				if lote.has("primeiro_polen"):
					juice_reserva_pousos.append({"dono": lote["dono"], "cor": lote["cor"], "primeiro_polen": int(lote["primeiro_polen"]) + chegados, "quantidade": 1, "inicio": juice_relogio})
				chegados += 1
				if lote.has("primeiro_polen") and (int(lote["primeiro_polen"]) + chegados) % 3 == 0 and estado_tela == "partida" and not partida_encerrada:
					feel_trinca(int(lote["dono"]), str(lote["cor"]))
			# Em um frame atrasado, não empilhar vários sons no mesmo instante.
			if chegados > primeira_chegada and estado_tela == "partida" and not partida_encerrada:
				# Motivo pentatônico: continua ao longo do voo, sem reiniciar em cada flor.
				var notas: Array[float] = [0.0, 2.0, 4.0, 7.0, 9.0, 7.0, 4.0, 2.0]
				tocar_som("polen_acomodar", pow(2.0, notas[juice_notas_voo % notas.size()] / 12.0))
				juice_notas_voo += chegados - primeira_chegada
			lote["chegados"] = chegados
			if chegados >= quantidade:
				animacoes_coleta_aula.remove_at(i)
		queue_redraw()
	if duplicacao_ativa:
		if duplicacao_voo_ativo:
			duplicacao_voo_tempo = minf(INTERVALO_DUPLICACAO_POLEN, duplicacao_voo_tempo + delta)
		if duplicacao_polen_ultimo_tempo > 0.0:
			duplicacao_polen_ultimo_tempo = maxf(0.0, duplicacao_polen_ultimo_tempo - delta)
		queue_redraw()
	# Pulsos de orientação não precisam reconstruir a mesa a cada frame.
	# Voo, plantio, coleta, celebração e transições continuam em frequência plena.
	if estado_tela == "partida" and not partida_encerrada:
		if etapa_fada == "movendo" or celebracao_objetivo_ativa or (aula_aviso_licao_ativo() and aula_aviso_licao_tipo == "pontuacao"):
			queue_redraw()
		else:
			perf_pulso_idle += delta
			var intervalo_idle: float = 1.0 / (20.0 if v209_leve else 30.0) if pulso_compra_ativo or etapa_fada != "" or aula_duelo or origem_selecionada != CELULA_INVALIDA else 1.0 / (10.0 if v209_leve else 15.0)
			if perf_pulso_idle >= intervalo_idle:
				perf_pulso_idle = fposmod(perf_pulso_idle, intervalo_idle)
				queue_redraw()
	else:
		perf_pulso_idle = 0.0
	perf_atualizar_debug(delta)

func turno_da_maquina() -> bool:
	# Jogador 1 é humano; 2, 3 e 4 são máquinas em qualquer versão.
	return modo_partida == "maquina" and estado_tela == "partida" and not partida_encerrada and jogador_atual >= 1 and jogador_atual < jogadores.size()

func maquina_pode_agir(token: int, numero_turno: int) -> bool:
	return is_inside_tree() and token == identificador_partida and numero_turno == turnos_jogados and turno_da_maquina()

# Mantem a demonstracao das conquistas deterministica sem mudar os duelos.
func preparar_poder_do_tutorial_novo() -> void:
	return

func iniciar_turno_maquina() -> void:
	if animacao_setup_ativa or not turno_da_maquina() or maquina_ocupada:
		return
	maquina_ocupada = true
	turno_automatico_maquina(identificador_partida, turnos_jogados)

func candidatos_de_jogada_maquina() -> Array[Dictionary]:
	# Examina colocacoes normais e a alternativa Mover + jogar.
	# O espaco original da flor afastada recebe sempre a nova carta.
	var candidatos: Array[Dictionary] = []
	var vistos: Dictionary = {}
	for chave in tabuleiro.keys():
		var casa: Vector2i = chave
		for direcao in VIZINHOS:
			var livre: Vector2i = casa + direcao
			if tabuleiro.has(livre) or vistos.has(livre):
				continue
			vistos[livre] = true
			candidatos.append({"tipo": "normal", "casa": livre})
	for chave in tabuleiro.keys():
		var origem: Vector2i = chave
		if not pode_deslocar_origem(origem):
			continue
		for direcao in VIZINHOS:
			var destino: Vector2i = origem + direcao
			if destino_valido_para_movimento(origem, destino):
				candidatos.append({
					"tipo": "deslocar",
					"casa": origem,
					"origem": origem,
					"destino_movido": destino
				})
	return candidatos

func progresso_parcial_maquina(objetivo: Dictionary, estado: Dictionary, casa_nova: Vector2i) -> float:
	if str(objetivo.get("classe", "flor")) == "fada":
		return 0.0
	# Considera apenas desenhos que incluem a flor recem-colocada.
	if linhas_pontuadas.has(str(objetivo["id"])):
		return 0.0
	# Uma casa com outra cor (ou gramado) bloqueia aquela configuracao.
	var modelo: Dictionary = MODELOS_OBJETIVO[int(objetivo["tipo"])]
	var base: Array[Vector2i] = posicoes_do_modelo(modelo)
	var padrao: Array = modelo["padrao"]
	var melhor: float = 0.0
	for rotacao in range(4 if bool(modelo.get("rotacionar", true)) else 1):
		var posicoes: Array[Vector2i] = []
		for posicao in base:
			posicoes.append(transformar_posicao(posicao, rotacao, false))
		for ancora in range(posicoes.size()):
			var referencia: Vector2i = casa_nova - posicoes[ancora]
			var boas: int = 0
			var vazias: int = 0
			var invalida: bool = false
			var casas: Array[Vector2i] = []
			for i in range(posicoes.size()):
				var casa: Vector2i = referencia + posicoes[i]
				casas.append(casa)
				if not estado.has(casa):
					vazias += 1
				elif str(estado[casa]) == cor_da_marca(objetivo, str(padrao[i])):
					boas += 1
				else:
					invalida = true
					break
			if invalida or vazias == 0 or boas < 2:
				continue
			var parcial: float = float(objetivo["pontos"]) * 3.0 * float(boas - 1)
			if vazias == 1:
				parcial *= 1.45
			melhor = maxf(melhor, parcial)
	return melhor

func prever_voo_fada_maquina(origem: Vector2i, destino: Vector2i, plano: Dictionary, nova_cor: String) -> Dictionary:
	var estado: Dictionary = tabuleiro.duplicate()
	if str(plano.get("tipo", "")) == "deslocar":
		var casa_original: Vector2i = plano["origem"]
		var nova_casa: Vector2i = plano["destino_movido"]
		estado[nova_casa] = estado[casa_original]
		estado.erase(casa_original)
	estado[plano["casa"]] = nova_cor
	var diferenca: Vector2i = destino - origem
	var passos: int = maxi(absi(diferenca.x), absi(diferenca.y))
	var direcao: Vector2i = Vector2i(clampi(diferenca.x, -1, 1), clampi(diferenca.y, -1, 1))
	var resultado: Dictionary = {
		"passos": passos, "coletados": 0, "produzidos": 0,
		"maior_coleta_flor": 0, "flores_coletadas": 0, "flores_visitadas": 0,
		"coletados_por_cor": {"vermelha": 0, "amarela": 0, "lilas": 0},
		"produzidos_por_cor": {"vermelha": 0, "amarela": 0, "lilas": 0}
	}
	for passo in range(1, passos + 1):
		var casa: Vector2i = origem + passo * direcao
		var cor: String = str(estado.get(casa, ""))
		if not CORES.has(cor):
			continue
		resultado["flores_visitadas"] = int(resultado["flores_visitadas"]) + 1
		var q: int = int(polens_por_casa.get(casa, 0))
		if str(plano.get("tipo", "")) == "deslocar":
			if casa == plano["origem"] or casa == plano["casa"]:
				q = 0
			elif casa == plano["destino_movido"]:
				q = int(polens_por_casa.get(plano["origem"], 0))
		# O primeiro polen da nova flor existe desde o plantio.
		# A previsao nao depende da espera visual de 1 segundo.
		if casa == plano["casa"] and str(plano.get("tipo", "")) != "voar":
			q = 1
		if q > 0:
			resultado["coletados"] = int(resultado["coletados"]) + q
			resultado["flores_coletadas"] = int(resultado["flores_coletadas"]) + 1
			resultado["maior_coleta_flor"] = maxi(int(resultado["maior_coleta_flor"]), q)
			var colhidos: Dictionary = resultado["coletados_por_cor"]
			colhidos[cor] = int(colhidos[cor]) + q
		else:
			resultado["produzidos"] = int(resultado["produzidos"]) + 1
			var gerados: Dictionary = resultado["produzidos_por_cor"]
			gerados[cor] = int(gerados[cor]) + 1
	return resultado

# v96: avaliacao de TODOS os objetivos de Fada. Nenhuma informacao
# oculta e lida; consideram-se apenas cartas ja recebidas, flores e fadas.
func casa_fada_em_plano_maquina(indice: int, plano: Dictionary) -> Vector2i:
	var casa: Vector2i = fadas[indice]["casa"]
	if str(plano.get("tipo", "")) == "deslocar" and casa == plano["origem"]:
		return plano["destino_movido"]
	return casa

func casas_fadas_em_plano_maquina(plano: Dictionary, fada_voando: int = -1,
		destino: Vector2i = CELULA_INVALIDA, proprio: bool = true) -> Array[Vector2i]:
	var casas: Array[Vector2i] = []
	for indice in range(fadas.size()):
		if (int(fadas[indice]["dono"]) == jogador_atual) != proprio:
			continue
		casas.append(destino if indice == fada_voando else casa_fada_em_plano_maquina(indice, plano))
	return casas

func cartas_entre_em_estado_maquina(a: Vector2i, b: Vector2i, estado: Dictionary) -> int:
	var dx: int = absi(a.x - b.x)
	var dy: int = absi(a.y - b.y)
	if (dx != 0 and dy != 0 and dx != dy) or (dx == 0 and dy == 0):
		return -1
	var direcao: Vector2i = Vector2i(signi(b.x-a.x), signi(b.y-a.y))
	var quantidade: int = 0
	for passo in range(1, maxi(dx, dy)):
		if estado.has(a + direcao * passo):
			quantidade += 1
	return quantidade

func linha_continua_estado_maquina(a: Vector2i, b: Vector2i, estado: Dictionary) -> bool:
	var dx: int = absi(a.x-b.x)
	var dy: int = absi(a.y-b.y)
	if (dx != 0 and dy != 0 and dx != dy) or (dx == 0 and dy == 0):
		return false
	var d: Vector2i = Vector2i(signi(b.x-a.x), signi(b.y-a.y))
	for passo in range(maxi(dx,dy)+1):
		if not CORES.has(str(estado.get(a+d*passo, ""))):
			return false
	return true

func alinhada_com_inimigo_em_plano_maquina(casa: Vector2i, inimigas: Array[Vector2i]) -> bool:
	for rival in inimigas:
		if casa.x == rival.x or casa.y == rival.y:
			return true
	return false

func grau_posicionamento_fadas_maquina(tipo: int, minhas: Array[Vector2i],
		estado: Dictionary) -> float:
	if minhas.size() != 2:
		return 0.0
	var a: Vector2i = minhas[0]
	var b: Vector2i = minhas[1]
	var ca: String = str(estado.get(a, ""))
	var cb: String = str(estado.get(b, ""))
	if not CORES.has(ca) or not CORES.has(cb):
		return 0.0
	var dx: int = absi(a.x-b.x)
	var dy: int = absi(a.y-b.y)
	var dist: int = maxi(dx,dy)
	var entre: int = cartas_entre_em_estado_maquina(a,b,estado)
	match tipo:
		41,42,43:
			var cor: String = "vermelha" if tipo == 41 else ("amarela" if tipo == 42 else "lilas")
			return (float(int(ca == cor) + int(cb == cor))/2.0) if a != b else 0.0
		44,45:
			if dx != 0 and dy != 0:
				return 0.0
			return clampf(float(maxi(0, entre))/float(2 if tipo == 44 else 4),0.0,1.0)
		46,47:
			if dx != dy or dx == 0:
				return 0.0
			return clampf(float(maxi(0, entre))/float(2 if tipo == 46 else 3),0.0,1.0)
		48:
			return 0.5 * float(ca != cb) + 0.5 * clampf(float(dist)/3.0,0.0,1.0)
		49:
			var min_x: int = 2147483647
			var max_x: int = -2147483647
			var min_y: int = 2147483647
			var max_y: int = -2147483647
			for chave in estado:
				if not CORES.has(str(estado[chave])):
					continue
				var p: Vector2i = chave
				min_x = mini(min_x,p.x)
				max_x = maxi(max_x,p.x)
				min_y = mini(min_y,p.y)
				max_y = maxi(max_y,p.y)
			var opostas: bool = (a.x == min_x and b.x == max_x and min_x < max_x) or (b.x == min_x and a.x == max_x and min_x < max_x) or (a.y == min_y and b.y == max_y and min_y < max_y) or (b.y == min_y and a.y == max_y and min_y < max_y)
			return (0.5 + 0.5*clampf(float(dist)/4.0,0.0,1.0)) if opostas else 0.0
	return 0.0

func inimiga_entre_fadas_em_plano_maquina(minhas: Array[Vector2i],
		inimigas: Array[Vector2i], estado: Dictionary, diagonal: bool) -> bool:
	if minhas.size() != 2:
		return false
	var a: Vector2i = minhas[0]
	var b: Vector2i = minhas[1]
	var dx: int = absi(a.x-b.x)
	var dy: int = absi(a.y-b.y)
	if diagonal:
		if dx != dy or dx < 2:
			return false
	elif (dx != 0 and dy != 0) or maxi(dx,dy)<2:
		return false
	if not linha_continua_estado_maquina(a,b,estado):
		return false
	var d: Vector2i = Vector2i(signi(b.x-a.x),signi(b.y-a.y))
	for passo in range(1,maxi(dx,dy)):
		if inimigas.has(a+d*passo):
			return true
	return false

func interposicao_em_plano_maquina(pouso: Vector2i, estado: Dictionary,
		plano: Dictionary) -> bool:
	for rival in range(jogadores.size()):
		if rival == jogador_atual:
			continue
		var posicoes: Array[Vector2i] = []
		for indice in range(fadas.size()):
			if int(fadas[indice]["dono"]) == rival:
				posicoes.append(casa_fada_em_plano_maquina(indice,plano))
		if posicoes.size() != 2:
			continue
		var a: Vector2i = posicoes[0]
		var b: Vector2i = posicoes[1]
		if not ((a.x == b.x or a.y == b.y) or absi(a.x-b.x) == absi(a.y-b.y)) or not linha_continua_estado_maquina(a,b,estado):
			continue
		var d: Vector2i = Vector2i(signi(b.x-a.x),signi(b.y-a.y))
		for passo in range(1,maxi(absi(b.x-a.x),absi(b.y-a.y))):
			if pouso == a+d*passo:
				return true
	return false

func progresso_objetivo_fada_maquina(obj: Dictionary, estado: Dictionary,
		plano: Dictionary, fada_voando: int, origem: Vector2i,
		destino: Vector2i, dados: Dictionary) -> float:
	# Retorna 0..1; 1 significa que a carta sera efetivamente concluida.
	var tipo: int = int(obj.get("fada_id",-1))
	if tipo < 41:
		return 1.0 if objetivo_fada_atendido(tipo,dados) else 0.0
	var minhas: Array[Vector2i] = casas_fadas_em_plano_maquina(plano,fada_voando,destino,true)
	var inimigas: Array[Vector2i] = casas_fadas_em_plano_maquina(plano,-1,CELULA_INVALIDA,false)
	var houve_voo: bool = fada_voando >= 0 and origem != destino
	var deslocou_inimiga: bool = false
	if str(plano.get("tipo","")) == "deslocar":
		for fada in fadas:
			if int(fada["dono"]) != jogador_atual and fada["casa"] == plano["origem"]:
				deslocou_inimiga = true
				break
	if tipo < 60:
		if not houve_voo:
			return 0.0
		var grau: float = grau_posicionamento_fadas_maquina(tipo,minhas,estado)
		return grau
	if tipo == 65:
		return 1.0 if deslocou_inimiga else 0.0
	if not houve_voo:
		return 0.0
	match tipo:
		61:
			var cerco: bool = (inimiga_entre_fadas_em_plano_maquina(minhas,inimigas,estado,false)
				or inimiga_entre_fadas_em_plano_maquina(minhas,inimigas,estado,true))
			return 1.0 if cerco else 0.0
		64:
			for rival in inimigas:
				if absi(rival.x-destino.x)+absi(rival.y-destino.y)==1:
					return 1.0
		66: return 1.0 if deslocou_inimiga else 0.0
		67:
			var antes: Array[Vector2i] = casas_fadas_em_plano_maquina({},-1,CELULA_INVALIDA,false)
			return 1.0 if alinhada_com_inimigo_em_plano_maquina(origem,antes) and not alinhada_com_inimigo_em_plano_maquina(destino,inimigas) else 0.0
		69:
			for rival in inimigas:
				if absi(rival.x-destino.x)==absi(rival.y-destino.y) and absi(rival.x-destino.x)>=3:
					return 1.0
		70: return 1.0 if interposicao_em_plano_maquina(destino,estado,plano) else 0.0
	return 0.0

func valor_objetivos_fada_maquina(estado: Dictionary, plano: Dictionary,
		fada_voando: int, origem: Vector2i, destino: Vector2i,
		dados: Dictionary) -> float:
	if not eh_alternativa() or not bool(jogadores[jogador_atual].get("fadas_desbloqueadas",false)):
		return 0.0
	var maior: float = 0.0
	for obj in jogadores[jogador_atual]["objetivos"]:
		if obj.is_empty() or str(obj.get("classe","flor")) != "fada":
			continue
		if linhas_pontuadas.has(str(obj["id"])):
			continue
		var grau: float = progresso_objetivo_fada_maquina(obj,estado,plano,fada_voando,origem,destino,dados)
		var peso: float = float(obj["pontos"])
		var nota: float = peso*52.0 if grau >= 0.999 else (peso*10.0*grau if dificuldade_maquina == "dificil" else 0.0)
		maior = maxf(maior,nota)
	return maior

# v103: a Original nao transforma polens em pontos fixos; as cores
# precisam corresponder a um objetivo historico ainda nao duplicado.
# Este incentivo pequeno complementa a coleta geral, sem consultar cartas
# ocultas, alterar o calculo final ou privilegiar reservas ja suficientes.
func potencial_posicao_fada_maquina(posicao: Vector2i, estado: Dictionary) -> float:
	var total: float = 0.0
	for chave in estado:
		var casa: Vector2i = chave
		if casa == posicao or not CORES.has(str(estado[casa])):
			continue
		if trajetoria_ortogonal(posicao, casa) or trajetoria_diagonal(posicao, casa):
			var q: int = int(polens_por_casa.get(casa, 0))
			total += 0.40 + 0.23 * float(mini(3, maxi(0, q)))
	return minf(total, 12.0)

func ganho_posicao_fada_maquina(origem: Vector2i, destino: Vector2i, estado: Dictionary) -> float:
	if dificuldade_maquina != "dificil" or origem == destino:
		return 0.0
	var depois: float = potencial_posicao_fada_maquina(destino, estado)
	var antes: float = potencial_posicao_fada_maquina(origem, estado)
	return clampf((depois - antes) * 2.6, -3.0, 8.0)

func ganho_coleta_rota_maquina(dados: Dictionary) -> float:
	var total: float = 0.0
	var por_cor: Dictionary = dados.get("coletados_por_cor",{})
	var reserva: Dictionary = jogadores[jogador_atual]["polens"]
	for cor in CORES:
		var q: int = int(por_cor.get(cor,0))
		if q <= 0:
			continue
		var n: int = int(reserva.get(cor,0))
		# 1 por polen, +2 por trinca completa dessa cor.
		var bonus_antes: int = floori(float(n) / 3.0) * 2
		var bonus_depois: int = floori(float(n+q) / 3.0) * 2
		total += float(q + bonus_depois-bonus_antes) * 4.0
	return total

func melhor_rota_maquina(destino: Vector2i, plano: Dictionary, cor_nova: String = "") -> Dictionary:
	var melhor: Dictionary = {}
	var nota_melhor: float = -999999.0
	var estado: Dictionary = tabuleiro.duplicate()
	if str(plano["tipo"]) == "deslocar":
		estado.erase(plano["origem"])
		estado[plano["destino_movido"]] = tabuleiro[plano["origem"]]
	estado[destino] = cor_nova
	for i in range(fadas.size()):
		if int(fadas[i]["dono"]) != jogador_atual:
			continue
		var origem: Vector2i = casa_fada_em_plano_maquina(i,plano)
		if not trajetoria_ortogonal(origem,destino) and not (permite_diagonal_ao_jogar_flor() and trajetoria_diagonal(origem,destino)):
			continue
		var futuro: Dictionary = prever_voo_fada_maquina(origem,destino,plano,cor_nova)
		var nota: float = ganho_coleta_rota_maquina(futuro)
		var credito_fada: float = valor_objetivos_fada_maquina(estado,plano,i,origem,destino,futuro)
		nota += credito_fada
		# Usar o ganho de oportunidades futuras, nao o comprimento do voo.
		# A Normal foca a jogada atual; a Dificil compara origem/destino.
		nota += ganho_posicao_fada_maquina(origem, destino, estado)
		if nota > nota_melhor:
			nota_melhor = nota
			melhor = {"indice":i,"nota":nota,"polens":int(futuro.get("coletados",0)),
				"origem":origem,"credito_fada_imediato":(credito_fada if credito_fada >= 150.0 else 0.0)}
	return melhor

func pode_colocar_em_estado_maquina(casa: Vector2i, estado: Dictionary) -> bool:
	if estado.has(casa):
		return false
	for direcao in VIZINHOS:
		if estado.has(casa + direcao):
			return true
	return false

func preparo_tatico_objetivo_maquina(objetivo: Dictionary, estado: Dictionary,
		casas_alteradas: Array[Vector2i]) -> float:
	# Na dificuldade Dificil, a IA examina as configuracoes que prepara
	# para a proxima rodada. Respeita rotacao, cores e vizinhanca real.
	if objetivo.is_empty() or str(objetivo.get("classe", "flor")) != "flor":
		return 0.0
	if linhas_pontuadas.has(str(objetivo["id"])):
		return 0.0
	var modelo: Dictionary = MODELOS_OBJETIVO[int(objetivo["tipo"])]
	var base: Array[Vector2i] = posicoes_do_modelo(modelo)
	var padrao: Array = modelo["padrao"]
	var melhor: float = 0.0
	for rotacao in range(4 if bool(modelo.get("rotacionar", true)) else 1):
		var posicoes: Array[Vector2i] = []
		for p in base:
			posicoes.append(transformar_posicao(p, rotacao, false))
		for casa_alterada in casas_alteradas:
			for ancora in range(posicoes.size()):
				var referencia: Vector2i = casa_alterada - posicoes[ancora]
				var certas: int = 0
				var livres: Array[Vector2i] = []
				var impossivel: bool = false
				for i in range(posicoes.size()):
					var casa: Vector2i = referencia + posicoes[i]
					if not estado.has(casa):
						livres.append(casa)
					elif str(estado[casa]) == cor_da_marca(objetivo, str(padrao[i])):
						certas += 1
					else:
						impossivel = true
						break
				if impossivel or certas < 2 or livres.is_empty():
					continue
				var acessiveis: int = 0
				for livre in livres:
					if pode_colocar_em_estado_maquina(livre, estado):
						acessiveis += 1
				if acessiveis == 0:
					continue
				var peso: float = float(objetivo["pontos"])
				var valor: float = 0.0
				if livres.size() == 1:
					# Objetivo com apenas 1 flor faltando: ameaca de pontuar
					# na rodada seguinte; desenhos espalhados ainda devem ser acessiveis.
					valor = peso * 15.0
				elif livres.size() == 2:
					valor = peso * (4.0 + float(acessiveis) * 1.5)
				melhor = maxf(melhor, valor)
	return melhor

func pontos_garantidos_carta_gamer(cor: String, plano: Dictionary) -> int:
	if cor == "" or plano.is_empty():
		return 0
	var depois: Dictionary = tabuleiro.duplicate()
	var casa_nova: Vector2i = plano["casa"]
	var alteradas: Array[Vector2i] = [casa_nova]
	var casa_reposta: Vector2i = CELULA_INVALIDA
	if str(plano["tipo"]) == "deslocar":
		var origem: Vector2i = plano["origem"]
		var destino: Vector2i = plano["destino_movido"]
		depois.erase(origem)
		depois[destino] = tabuleiro[origem]
		alteradas.append(destino)
		casa_reposta = origem
	depois[casa_nova] = cor
	var conquista: Dictionary = melhor_objetivo_da_jogada(jogador_atual, alteradas, tabuleiro, depois, casa_reposta)
	return int(conquista.get("pontos", 0))

func avaliar_plano_maquina(cor: String, plano: Dictionary) -> float:
	# Simula EXATAMENTE a mesma regra da partida: ate 1 objetivo concluido,
	# sempre o de maior valor, inclusive quando uma cor e reposta por ela mesma.
	var depois: Dictionary = tabuleiro.duplicate()
	var casa_nova: Vector2i = plano["casa"]
	var alteradas: Array[Vector2i] = [casa_nova]
	var casa_reposta: Vector2i = CELULA_INVALIDA
	if str(plano["tipo"]) == "deslocar":
		var origem: Vector2i = plano["origem"]
		var destino_movido: Vector2i = plano["destino_movido"]
		depois.erase(origem)
		depois[destino_movido] = tabuleiro[origem]
		alteradas.append(destino_movido)
		casa_reposta = origem
	depois[casa_nova] = cor

	var nota: float = 0.0
	var credito_flor_imediato: float = 0.0
	var objetivos: Array[Dictionary] = jogadores[jogador_atual]["objetivos"]
	var melhor: Dictionary = {}
	# A maquina pode concluir objetivos desde sua primeira jogada.
	melhor = melhor_objetivo_da_jogada(
		jogador_atual, alteradas, tabuleiro, depois, casa_reposta)
	if not melhor.is_empty():
		credito_flor_imediato = float(melhor["pontos"]) * 62.0 + 13.0
		nota += credito_flor_imediato
	# Na 3a conquista, as cartas antigas sao descartadas: nao premiar
	# preparo de objetivos que deixarao de existir apos esta jogada.
	var trocara_de_fase: bool = (not melhor.is_empty() and
		int(jogadores[jogador_atual].get("objetivos_concluidos", 0)) == 2 and
		(eh_gamer() or eh_alternativa()))
	# Os demais objetivos continuam ativos e podem ser preparados para
	# turnos seguintes, mas NAO somam pontos nesta jogada.
	for indice in range(objetivos.size()):
		if trocara_de_fase:
			break
		var objetivo: Dictionary = objetivos[indice]
		if objetivo.is_empty() or linhas_pontuadas.has(str(objetivo["id"])):
			continue
		if not melhor.is_empty() and indice == int(melhor["indice"]):
			continue
		var peso_parcial: float = 0.75 if dificuldade_maquina == "medio" else 1.10
		nota += progresso_parcial_maquina(objetivo, depois, casa_nova) * peso_parcial

	# O nivel Dificil planeja a proxima rodada. Na Original ele observa
	# tambem as ameacas publicas do rival (sem saber a proxima carta).
	if dificuldade_maquina == "dificil" and not trocara_de_fase:
		var gamer_estrategico: bool = eh_gamer()
		var fator_preparo: float = 1.36 if gamer_estrategico else 1.0
		var alteradas_taticas: Array[Vector2i] = [casa_nova]
		if str(plano["tipo"]) == "deslocar":
			alteradas_taticas.append(plano["destino_movido"])
		for objetivo in objetivos:
			if objetivo.is_empty() or (not melhor.is_empty() and str(objetivo["id"]) == str(melhor["id"])):
				continue
			nota += preparo_tatico_objetivo_maquina(objetivo, depois, alteradas_taticas) * fator_preparo
		# Os objetivos ainda nao revelados de adversarios nao sao usados.
		# A IA Dificil avalia preparacao de sua propria mao e oportunidades
		# publicas de voo/confronto, sem conhecer a proxima carta escondida.
	# Deslocamento forçado pode ser conquistado sem voo.
	var credito_deslocamento: float = 0.0
	if eh_alternativa() and str(plano["tipo"]) == "deslocar":
		var inimigo_na_origem: bool = false
		for fada in fadas:
			if int(fada["dono"]) != jogador_atual and fada["casa"] == plano["origem"]:
				inimigo_na_origem = true
				break
		if inimigo_na_origem:
			for obj in objetivos:
				if str(obj.get("classe","flor")) == "fada" and int(obj.get("fada_id",-1)) == 65 and not linhas_pontuadas.has(str(obj["id"])):
					credito_deslocamento = float(obj["pontos"])*50.0
	var rota: Dictionary = melhor_rota_maquina(casa_nova, plano, cor)
	if not rota.is_empty():
		# Um unico objetivo (floral OU de fada) pontua por jogada.
		var credito_fada: float = float(rota.get("credito_fada_imediato",0.0))
		var credito_competitivo: float = maxf(credito_fada,credito_deslocamento)
		var credito_descartar: float = minf(credito_flor_imediato,credito_competitivo)
		nota += maxf(0.0,float(rota["nota"])-credito_descartar)
		if credito_deslocamento > credito_fada:
			nota += credito_deslocamento-credito_fada
	elif credito_deslocamento > 0.0:
		nota += maxf(0.0,credito_deslocamento-credito_flor_imediato)
	if str(plano["tipo"]) == "deslocar":
		nota -= 2.2
	return nota

func perfil_dificuldade_maquina() -> Dictionary:
	return PERFIS_MAQUINA.get(dificuldade_maquina, PERFIS_MAQUINA["medio"])

func perf_escolher_plano_avaliado(melhor: Dictionary, melhor_nota: float, alternativas: Array[Dictionary]) -> Dictionary:
	if alternativas.is_empty():
		return {}
	# Normal explora poucas alternativas quase equivalentes; Dificil
	# usa a maior nota, considerando preparacao de varias jogadas.
	var perfil: Dictionary = perfil_dificuldade_maquina()
	var chance_alternativa: float = float(perfil["alternativa"])
	var tolerancia: float = float(perfil["margem"])
	if alternativas.size() > 1 and sorteador.randf() < chance_alternativa:
		var proximas: Array[Dictionary] = []
		for opcao in alternativas:
			if float(opcao["nota"]) >= melhor_nota - tolerancia:
				proximas.append(opcao)
		if not proximas.is_empty():
			return proximas[sorteador.randi_range(0, proximas.size() - 1)]
	return melhor

# Avaliação em fatias de tempo, com os mesmos candidatos, notas e sorteios.
# O cache é local à jogada e descartado ao mudar de turno/partida.
func perf_melhor_plano_async(cor: String, candidatos: Array[Dictionary], token: int, numero_turno: int, cache: Dictionary) -> Dictionary:
	if cor == "" or not maquina_pode_agir(token, numero_turno):
		return {}
	var alternativas: Array[Dictionary] = []
	var melhor: Dictionary = {}
	var melhor_nota: float = -999999.0
	if cache.has(cor):
		alternativas = cache[cor]
		for opcao in alternativas:
			if float(opcao["nota"]) > melhor_nota:
				melhor_nota = float(opcao["nota"])
				melhor = opcao
	else:
		var inicio_fatia: int = Time.get_ticks_usec()
		for plano in candidatos:
			var nota: float = avaliar_plano_maquina(cor, plano)
			var opcao: Dictionary = plano.duplicate()
			opcao["nota"] = nota
			if nota > melhor_nota:
				melhor_nota = nota
				melhor = opcao
			alternativas.append(opcao)
			if Time.get_ticks_usec() - inicio_fatia >= (1800 if v209_leve else 3500):
				await aguardar_frame_jogo()
				if not maquina_pode_agir(token, numero_turno):
					return {}
				inicio_fatia = Time.get_ticks_usec()
		cache[cor] = alternativas
	return perf_escolher_plano_avaliado(melhor, melhor_nota, alternativas)

func maquina_objetivos_disponiveis() -> bool:
	var objetivos: Array[Dictionary] = jogadores[jogador_atual]["objetivos"]
	for objetivo in objetivos:
		if objetivo.is_empty():
			return false
	return true

# Abertura protegida: as Pretas plantam a leste nas primeiras três respostas.
# A compra, o voo, o consumo e a pontuação continuam sendo os reais.
# Da quarta resposta em diante, usa o planejador Normal sem restrições.
func aula_destino_preto() -> Vector2i:
	if not aula_duelo_ativa() or not turno_da_maquina():
		return CELULA_INVALIDA
	var passo: int = int(jogadores[1].get("turnos_proprios", 0))
	var destinos: Array[Vector2i] = [Vector2i(2, 0), Vector2i(2, -1), Vector2i(2, 1)]
	if passo < 0 or passo >= destinos.size():
		return CELULA_INVALIDA
	return destinos[passo] if pode_colocar(destinos[passo]) else CELULA_INVALIDA

func turno_automatico_maquina(token: int, numero_turno: int) -> void:
	# Pausas curtas mantem a jogada observavel. Todas as chamadas executam
	# as funcoes oficiais de selecao, colocacao, deslocamento e fadas.
	mensagem = texto_vez_atual() + "…"
	atualizar_botoes_de_movimento()
	queue_redraw()
	await get_tree().create_timer(0.55, false).timeout
	if not maquina_pode_agir(token, numero_turno):
		return

	# Quando a troca de vez acontece antes da reposicao de 2 segundos,
	# aguardar as cartas de objetivos, sem dar vantagens ocultas a maquina.
	for _espera in range(11):
		if maquina_objetivos_disponiveis():
			break
		await get_tree().create_timer(0.25, false).timeout
		if not maquina_pode_agir(token, numero_turno):
			return

	var destino_didatico: Vector2i = aula_destino_preto()
	if destino_didatico != CELULA_INVALIDA and not baralho.is_empty():
		mensagem = "As Pretas compram do baralho. Observe sua jogada."
		escolher_carta(false)
		while animacao_compra_ativa:
			await aguardar_frame_jogo()
			if not maquina_pode_agir(token, numero_turno):
				return
		await get_tree().create_timer(0.40, false).timeout
		if not maquina_pode_agir(token, numero_turno):
			return
		if flor_na_mao != "" and pode_colocar(destino_didatico):
			mensagem = "As Pretas plantam uma flor."
			colocar_carta(destino_didatico)
			return # oferecer_movimento_fada e a conclusão avançam a vez.
		# A jogada protegida é executada somente em um estado válido.
		# Se a carta já entrou na mão, não comprar outra.
		if flor_na_mao != "":
			for alternativa in candidatos_de_jogada_maquina():
				if str(alternativa.get("tipo", "")) == "normal" and pode_colocar(alternativa["casa"]):
					colocar_carta(alternativa["casa"])
					return
	var candidatos: Array[Dictionary] = candidatos_de_jogada_maquina()
	if candidatos.is_empty():
		mensagem = "%s não encontraram uma posição disponível." % nome_cor_fada_plural(jogador_atual)
		maquina_ocupada = false
		return

	var cache_notas: Dictionary = {}
	var avaliacao_aberta: Dictionary = await perf_melhor_plano_async(flor_aberta, candidatos, token, numero_turno, cache_notas)
	if not maquina_pode_agir(token, numero_turno):
		return
	var nota_plantio: float = float(avaliacao_aberta.get("nota", 0.0))
	var pesos_baralho: Dictionary = {}
	var peso_total: float = 0.0
	for cor in CORES:
		var visiveis: int = 0
		for valor in tabuleiro.values():
			if str(valor) == cor:
				visiveis += 1
		# Mesma distribuicao de chances usada por comprar_do_baralho:
		# as cores menos frequentes na mesa tem maior chance. A IA nao
		# consulta a proxima carta nem quantas de cada cor restam no monte.
		var peso: float = 1.0 / float(1 + visiveis)
		pesos_baralho[cor] = peso
		peso_total += peso
	var esperado_baralho: float = 0.0
	if not baralho.is_empty() and peso_total > 0.0:
		for cor in pesos_baralho:
			var melhor_cor: Dictionary = await perf_melhor_plano_async(str(cor), candidatos, token, numero_turno, cache_notas)
			if not maquina_pode_agir(token, numero_turno):
				return
			if not melhor_cor.is_empty():
				esperado_baralho += float(melhor_cor["nota"]) * float(pesos_baralho[cor]) / peso_total

	# Voo Livre nao existe: a IA voa somente apos jogar uma flor.
	# A carta aberta e garantida; o baralho e incerto e recebe uma
	# penalidade de risco. Nao vemos qual carta sairia antes de compra-la.
	# Na Original Dificil, dar preferencia discreta a uma boa carta
	# garantida, em vez de apostar numa cor ainda desconhecida.
	var margem_carta_coletiva: float = 12.0 if eh_gamer() and dificuldade_maquina == "dificil" else 3.0
	var usar_coletiva: bool = flor_aberta != "" and (
		baralho.is_empty() or (
			not avaliacao_aberta.is_empty() and float(avaliacao_aberta["nota"]) + margem_carta_coletiva >= esperado_baralho))
	# Evitar que uma dificuldade descarte uma conquista floral certa
	# em troca de uma cor ainda oculta. A Normal tambem joga bem.
	# A Normal explora ocasionalmente o baralho somente se a estimativa
	# nao for muito pior que a carta aberta; nunca descarta uma conquista certa.
	var chance_baralho_arriscado: float = float(perfil_dificuldade_maquina()["risco_baralho"])
	if flor_aberta != "" and not baralho.is_empty() and nota_plantio < 95.0 and esperado_baralho + 5.0 >= nota_plantio and pontos_garantidos_carta_gamer(flor_aberta, avaliacao_aberta) == 0 and sorteador.randf() < chance_baralho_arriscado:
		usar_coletiva = false
	if flor_aberta == "" and baralho.is_empty():
		mensagem = "O baralho e a carta coletiva acabaram."
		maquina_ocupada = false
		encerrar_partida(true, true)
		return

	mensagem = "%s escolheram a coletiva." % nome_cor_fada_plural(jogador_atual) if usar_coletiva else "%s compraram do baralho." % nome_cor_fada_plural(jogador_atual)
	escolher_carta(usar_coletiva)
	atualizar_botoes_de_movimento()
	queue_redraw()
	await get_tree().create_timer(0.70, false).timeout
	if not maquina_pode_agir(token, numero_turno) or flor_na_mao == "":
		return
	while animacao_compra_ativa:
		await aguardar_frame_jogo()
		if not maquina_pode_agir(token, numero_turno):
			return

	var plano: Dictionary = await perf_melhor_plano_async(flor_na_mao, candidatos, token, numero_turno, cache_notas)
	if not maquina_pode_agir(token, numero_turno):
		return
	if plano.is_empty():
		maquina_ocupada = false
		return
	if str(plano["tipo"]) == "deslocar":
		var origem: Vector2i = plano["origem"]
		var destino_movido: Vector2i = plano["destino_movido"]
		mensagem = "%s vão deslocar uma flor." % nome_cor_fada_plural(jogador_atual)
		iniciar_deslocamento(origem, destino_movido)
		# Esta funcao aplica automaticamente a carta selecionada apos 1 s.
		await get_tree().create_timer(1.15, false).timeout
	else:
		var destino: Vector2i = plano["casa"]
		mensagem = "%s escolheram onde plantar." % nome_cor_fada_plural(jogador_atual)
		colocar_carta(destino)
		await get_tree().create_timer(0.40, false).timeout
	if not maquina_pode_agir(token, numero_turno):
		return

	# O jogador humano escolhe mover ou nao; a maquina decide sozinha.
	# A jogada finaliza quando a decisao e o eventual percurso de 0,5 s por casa terminam.

func quantidade_jogadores() -> int:
	if aula_duelo and modo_partida == "maquina":
		return 2
	if modo_partida in ["aprender", "aprender_novo", "aula"]:
		return 1
	if modo_partida == "maquina":
		return 1 + clampi(quantidade_maquinas_partida, 1, 3)
	return 2

func criar_botoes_menu() -> void:
	botao_abertura_aprender = criar_botao_menu("Aprender", Callable(self, "iniciar_tutorial_novo"))
	botao_abertura_jogar = criar_botao_menu("Jogar", Callable(self, "abrir_selecao_modo"))
	# Abertura, submenus e controles de partida utilizam a mesma paleta dourada.
	configurar_visual_botao_dourado(botao_abertura_aprender)
	configurar_visual_botao_dourado(botao_abertura_jogar)
	botao_catalogo_anterior = criar_botao_menu("‹ Anteriores", Callable(self, "mudar_pagina_catalogo").bind(-1))
	botao_catalogo_proximo = criar_botao_menu("Próximos ›", Callable(self, "mudar_pagina_catalogo").bind(1))
	botao_regras_voltar = criar_botao_menu("Voltar ao Menu", Callable(self, "voltar_do_catalogo"))
	botao_menu_duelo = criar_botao_menu("Duelo Local", Callable(self, "iniciar_duelo"))
	botao_menu_maquina = criar_botao_menu("Contra adversários", Callable(self, "abrir_escolha_quantidade_maquinas"))
	botao_maquinas_1 = criar_botao_menu("2 Jogadores", Callable(self, "selecionar_quantidade_maquinas").bind(1))
	botao_maquinas_2 = criar_botao_menu("3 Jogadores", Callable(self, "selecionar_quantidade_maquinas").bind(2))
	botao_maquinas_3 = criar_botao_menu("4 Jogadores", Callable(self, "selecionar_quantidade_maquinas").bind(3))
	botao_maquinas_voltar = criar_botao_menu("Voltar", Callable(self, "voltar_da_escolha_quantidade_maquinas"))
	botao_maquina_medio = criar_botao_menu("Normal", Callable(self, "iniciar_maquina_nivel").bind("medio"))
	botao_maquina_dificil = criar_botao_menu("Difícil", Callable(self, "iniciar_maquina_nivel").bind("dificil"))
	botao_maquina_voltar = criar_botao_menu("Voltar", Callable(self, "voltar_da_selecao_maquina"))
	botao_menu_voltar = criar_botao_menu("Voltar", Callable(self, "retornar_abertura"))
	botao_pontuacao_entenda = criar_botao_menu("Entenda as Estrelas", Callable(self, "abrir_explicacao_pontuacao"))
	botao_resultado_inicio = criar_botao_menu("Menu Inicial", Callable(self, "voltar_inicio"))
	botao_pontuacao_voltar = criar_botao_menu("Voltar ao placar", Callable(self, "voltar_placar_geral"))
	texto_pontuacao_explicacao = RichTextLabel.new()
	texto_pontuacao_explicacao.name = "ExplicacaoDaPontuacao"
	texto_pontuacao_explicacao.bbcode_enabled = true
	texto_pontuacao_explicacao.scroll_active = true
	texto_pontuacao_explicacao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto_pontuacao_explicacao.mouse_filter = Control.MOUSE_FILTER_STOP
	texto_pontuacao_explicacao.add_theme_color_override("default_color", COR_TEXTO)
	texto_pontuacao_explicacao.add_theme_font_override("normal_font", fonte)
	texto_pontuacao_explicacao.add_theme_font_override("bold_font", fonte_destaque)
	texto_pontuacao_explicacao.text = "[b]Jardim das Fadas[/b]\nAo finalizar, o placar em estrelas é explicado."
	texto_pontuacao_original = texto_pontuacao_explicacao.text
	add_child(texto_pontuacao_explicacao)
	texto_pontuacao_original = texto_pontuacao_explicacao.text
	texto_pontuacao_explicacao.visible = false
	botao_resultado_anterior = criar_botao_menu("‹", Callable(self, "mudar_pagina_resultado").bind(-1))
	botao_resultado_proximo = criar_botao_menu("›", Callable(self, "mudar_pagina_resultado").bind(1))
	botao_resultado_anterior.add_theme_font_size_override("font_size", 21)
	botao_resultado_proximo.add_theme_font_size_override("font_size", 21)

	# Manual completo acessivel sem iniciar uma partida.
	texto_regras_completas = RichTextLabel.new()
	texto_regras_completas.name = "RegrasCompletas"
	texto_regras_completas.bbcode_enabled = true
	texto_regras_completas.scroll_active = true
	texto_regras_completas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto_regras_completas.mouse_filter = Control.MOUSE_FILTER_STOP
	texto_regras_completas.add_theme_color_override("default_color", COR_TEXTO)
	texto_regras_completas.add_theme_font_override("normal_font", fonte)
	texto_regras_completas.add_theme_font_override("bold_font", fonte_destaque)
	texto_regras_completas.text = """[color=#f9d28a][b]JARDIM DAS FADAS — REGRAS[/b][/color]

[b]Início[/b]
O jardim começa com nove flores em um quadrado 3x3, três de cada cor. A flor central é fixa. Cada jogador controla duas fadas. Há Duelo Local e partidas contra um, dois ou três adversários.

[b]Flores e turnos[/b]
Pegue a carta coletiva visível ou compre do baralho. A carta vai para sua mão, no canto inferior direito. Nenhuma compra pode ser desfeita. Plante a flor junto a outra carta ou desloque uma flor da borda uma casa ortogonal e preencha o espaço deixado.

[b]Voos[/b]
Após plantar ou repor uma flor, uma fada alinhada em reta ou diagonal pode voar até ela gratuitamente. Recolhe os pólens das flores visitadas ou produz um pólen nas flores vazias. Cada flor comporta até quatro pólens. Não há Voo Livre.

[b]Objetivos[/b]
Comece com três objetivos Médios (3–4 estrelas). Após três conquistas, receba dois Difíceis (5–7 estrelas) e dois Objetivos de Fada. Os desenhos giram em 90°, sem espelhamento. Só um objetivo rende estrelas por jogada. Cada flor de um objetivo floral concluído recebe um pólen, respeitando o limite. Objetivos de Fada rendem as estrelas indicadas. No tutorial, você joga contra as fadas pretas. As primeiras jogadas são guiadas; depois, você escolhe livremente suas ações e pode pedir uma dica quando disponível.

[b]Pontuação[/b]
Cada pólen guardado vale 1 estrela; uma trinca da mesma cor vale 5 estrelas no total (3 básicas e 2 de bônus). Não há duplicação de objetivos. Os objetivos de posição exigem voo efetivo nesta vez. As cartas de fada mostram o valor de estrelas já ajustado à quantidade de jogadores.

[b]Fim de partida[/b]
A partida termina após a sexta conquista e a rodada de fechamento. Vence quem somar mais estrelas.

[b]Interface[/b]
A mesa permanece em retrato em todos os dispositivos. O placar compacto e o botão de saída ficam juntos no topo. As instruções aparecem diretamente sobre a mesa marrom, logo acima dos objetivos. Na metade inferior, os objetivos permanecem grandes em grade 2×2 e, à direita, ficam baralho, coletiva, ações e sua carta. Acima do baralho aparecem seus pólens por cor; a coletiva fica abaixo do baralho, e o ícone de saída fica no canto superior direito da tela. Arraste a coletiva direto para o jardim ou toque nela para levá-la à mão. Arraste uma flor da borda para deslocá-la. Arraste sua carta para plantar ou toque na casa desejada. Toque no corpo de um objetivo para ampliar; toque no canto superior direito da carta para girar, ou arraste a partir desse canto. Use zoom para aproximar o jardim. O placar mostra o total de estrelas de cada jogador em tempo real."""
	add_child(texto_regras_completas)
	texto_regras_completas.visible = false

func criar_botao_menu(titulo: String, acao: Callable) -> Button:
	var botao: Button = Button.new()
	botao.text = titulo
	botao.mouse_filter = Control.MOUSE_FILTER_STOP
	botao.add_theme_font_size_override("font_size", 19)
	configurar_visual_botao(botao)
	botao.pressed.connect(acao)
	botao.button_down.connect(func():
		tocar_som("botao")
		botao.pivot_offset = botao.size * 0.5
		botao.scale = Vector2.ONE * 0.95)
	botao.button_up.connect(func(): botao.scale = Vector2.ONE)
	botao.visibility_changed.connect(func(): botao.scale = Vector2.ONE)
	add_child(botao)
	botao.visible = false
	return botao

func criar_botoes_poder() -> void:
	botao_poder_pular = criar_botao_menu("Pular magia", Callable(self, "cancelar_poder_novo"))
	botao_poder_pular.add_theme_font_size_override("font_size", 12)
	for cor in CORES:
		var botao: Button = criar_botao_menu(nome_cor(cor).capitalize(), Callable(self, "escolher_cor_do_poder").bind(cor))
		botao.add_theme_font_size_override("font_size", 12)
		botoes_poder_cores[cor] = botao

func atualizar_interface_poder() -> void:
	# A escolha da nova cor acontece somente pela mini-janela de duas flores.
	# Os antigos botoes de cores permanecem criados por compatibilidade,
	# mas nunca ficam visiveis, nem cobrem o tabuleiro.
	if not is_instance_valid(botao_poder_pular):
		return
	var disponivel: bool = versao_nova and not tutorial_final_pendente and estado_tela == "partida" and not partida_encerrada and not turno_da_maquina()
	botao_poder_pular.visible = not aula_duelo and disponivel and etapa_fada in ["magia", "pagar_diagonal", "cor_nova"]
	botao_poder_pular.text = "Pular magia" if etapa_fada == "magia" else "Cancelar"
	for cor in CORES:
		var botao: Button = botoes_poder_cores[cor]
		botao.visible = false

func posicionar_botoes_poder() -> void:
	if not is_instance_valid(botao_poder_pular):
		return
	# Botoes curtos no rodape da mesa, fora das cartas de compra.
	var altura: float = 31.0
	var margem: float = 8.0
	var largura: float = minf(100.0, maxf(48.0, (area_tabuleiro.size.x - 5.0 * margem) / 4.0))
	var total: float = largura * 4.0 + margem * 3.0
	var x: float = area_tabuleiro.get_center().x - total * 0.5
	var y: float = area_tabuleiro.end.y - altura - 7.0
	for indice in range(CORES.size()):
		var botao: Button = botoes_poder_cores[CORES[indice]]
		botao.position = Vector2(x + float(indice) * (largura + margem), y)
		botao.size = Vector2(largura, altura)
	if versao_nova and acao_nova == "pintar_cor":
		# A escolha das duas cores fica afastada do botao Cancelar.
		# Em telas largas usa a coluna vizinha; em estreitas vai abaixo das acoes.
		var largura_larga: bool = area_tabuleiro.size.x >= 450.0
		var xo: float = area_tabuleiro.position.x + (195.0 if largura_larga else 9.0)
		var yo: float = area_tabuleiro.position.y + (124.0 if largura_larga else 231.0)
		for i in range(CORES.size()):
			var bt: Button = botoes_poder_cores[CORES[i]]
			bt.position = Vector2(xo + float(i) * 101.0, yo)
			bt.size = Vector2(96.0, altura)
	botao_poder_pular.position = Vector2(x + 3.0 * (largura + margem), y)
	botao_poder_pular.size = Vector2(largura, altura)

func criar_botoes_acao_nova() -> void:
	# Todos os comandos, inclusive Cancelar, utilizam a paleta dourada comum.
	for chave in ["poderes", "diagonal", "pintar", "cancelar"]:
		var nomes: Dictionary = { "poderes":"Usar Poder", "diagonal":"Voo Livre (desativado)", "pintar":"Pintura de Flor", "cancelar":"Cancelar"}
		var botao: Button = criar_botao_menu(str(nomes[chave]), Callable(self, "selecionar_botao_acao_nova").bind(chave))
		botao.add_theme_font_size_override("font_size", 12)
		configurar_visual_botao_dourado(botao)
		botoes_acao_nova[chave] = botao

func tutorial_novo_ativo() -> bool:
	return versao_nova and modo_partida == "aprender_novo" and estado_tela == "partida" and not partida_encerrada and not tutorial_final_pendente and not tutorial_pratica_livre

func tutorial_guiado_ativo() -> bool:
	return estado_tela == "partida" and not partida_encerrada and not tutorial_final_pendente and not tutorial_pratica_livre and \
		modo_partida in ["aprender", "aprender_novo"]

func total_etapas_tutorial_atual() -> int:
	return TUTORIAL_GAMER_ETAPAS if versao_gamer_progressiva else TUTORIAL_NOVO_ETAPAS

func passo_tutorial_novo() -> int:
	# Os tutoriais de Original e Expandida usam prática livre; sem Voo Livre.
	return clampi(turnos_jogados + 1, 1, APRENDER_MAX_JOGADAS if not versao_nova else total_etapas_tutorial_atual())

func acao_permitida_no_tutorial_novo(chave: String) -> bool:
	if aula_guiada_ativa() and not turno_da_maquina():
		return not aula_rotacao_pendente() and chave == ("plantar" if aula_origem() == CELULA_INVALIDA else "mover")
	return true

func selecionar_botao_acao_nova(chave: String) -> void:
	if estado_tela != "partida" or turno_da_maquina() or partida_encerrada:
		return
	if (eh_gamer() and chave != "cancelar") or (not tem_voo_livre() and chave == "diagonal"):
		return
	if chave == "pintar" and not PINTURA_GAMER_ATIVA:
		return
	if animacao_setup_ativa or celebracao_objetivo_ativa or etapa_fada != "" or maquina_ocupada or tutorial_passo_consulta >= 1:
		return
	if chave == "cancelar":
		cancelar_acao_nova()
		return
	if acao_nova == "":
		if not acao_permitida_no_tutorial_novo(chave):
			mensagem = "No tutorial, siga a ação indicada para esta jogada."
			queue_redraw()
			return
		if chave == "diagonal":
			acao_nova = "diagonal_fada"
			mensagem = "Escolha a Fada para realizar o Voo Livre."
			if fada_poder_preselecionada >= 0:
				var fada_escolhida: int = fada_poder_preselecionada
				fada_poder_preselecionada = -1
				escolher_fada_para_voo_diagonal(fada_escolhida)
	elif acao_nova == "poderes":
		if chave == "diagonal" and acao_permitida_no_tutorial_novo(chave):
			# A seleção da fada vem PRIMEIRO. Não bloquear silenciosamente
			# o botão por falta de uma rota pagável no estado atual do jardim.
			acao_nova = "diagonal_fada"
			mensagem = "Escolha a Fada: clique em uma das suas duas fadas (destacadas em azul)."
			if fada_poder_preselecionada >= 0:
				# Se o jogador abriu o poder clicando numa fada, ela já foi escolhida.
				var fada_ja_clicada: int = fada_poder_preselecionada
				fada_poder_preselecionada = -1
				escolher_fada_para_voo_diagonal(fada_ja_clicada)
		elif chave == "pintar" and acao_permitida_no_tutorial_novo(chave):
			if flores_transformaveis(jogador_atual).is_empty():
				mensagem = "Sem flores próximas que possam ser pintadas com seus pólens."
				queue_redraw()
				return
			acao_nova = "pintar_alvo"
			fada_poder_preselecionada = -1
			mensagem = "Escolha onde pintar: flores de contorno azul próximas às suas fadas."
	atualizar_interface_acoes_nova()
	queue_redraw()

func cancelar_acao_nova() -> void:
	if animacao_compra_ativa or not juice_plantar.is_empty():
		return
	if acao_nova == "" or etapa_fada != "":
		return
	if acao_nova == "pintar_cor":
		acao_nova = "pintar_alvo"
		alvo_transformacao = CELULA_INVALIDA
		mensagem = "Escolha outra flor indicada para pintar, ou cancele o poder."
		atualizar_interface_acoes_nova()
		queue_redraw()
		return
	# Depois de revelar o BARALHO, Cancelar pode desfazer apenas a
	# SELEÇÃO/DESLOCAMENTO, jamais devolver ou descartar a carta comprada.
	if flor_na_mao != "":
		if acao_nova == "mover" or movimento_pendente or modo_movimento or origem_selecionada != CELULA_INVALIDA:
			cancelar_movimento()
			acao_nova = "mover" if aula_compra_antes_de_mover() else "plantar"
			mensagem = "A carta continua na mão. Mova a flor indicada." if aula_compra_antes_de_mover() else "Movimento cancelado. A carta continua na mão: plante ou escolha outra flor da borda para mover."
			atualizar_interface_acoes_nova()
			queue_redraw()
			return
		mensagem = "A carta da mão deve ser jogada; você ainda pode mover uma flor da borda antes disso."
		queue_redraw()
		return
	if movimento_pendente or modo_movimento or flor_na_mao != "":
		cancelar_movimento()
	alvo_transformacao = CELULA_INVALIDA
	fada_diagonal_pendente = -1
	fada_poder_preselecionada = -1
	acao_nova = ""
	mensagem = "Escolha uma carta ou mova uma flor da borda."
	atualizar_interface_acoes_nova()
	queue_redraw()

func atualizar_interface_acoes_nova() -> void:
	if botoes_acao_nova.is_empty():
		return

	# Cada atualização limpa os rótulos dos botões, inclusive os legados
	# (o botão do antigo Voo Livre permanece sempre oculto).
	var rotulos_base: Dictionary = {
		"poderes": "Usar Poder", # Estado legado oculto: código da pintura preservado.
		"diagonal": "Voo Livre (desativado)",
		"pintar": "Pintura de Flor",
		"cancelar": "Cancelar"
	}
	for chave in rotulos_base:
		var b_limpar: Button = botoes_acao_nova[chave]
		b_limpar.text = str(rotulos_base[chave])
		b_limpar.visible = false
		b_limpar.disabled = false

	# v136: no Aprender, as cartas e o jardim são os únicos comandos da jogada.
	if aula_guiada_ativa():
		return

	var disponivel: bool = not escolhas_iniciais_pendentes and not tutorial_final_pendente and estado_tela == "partida" and not partida_encerrada and not turno_da_maquina() and not animacao_setup_ativa and not celebracao_objetivo_ativa and etapa_fada == "" and indice_cenario_em_revisao < 0 and tutorial_passo_consulta < 1
	if not disponivel:
		return

	match acao_nova:
		"", "plantar", "mover":
			# Plantio e deslocamento são comandos diretos nas cartas e no jardim.
			pass
		"poderes":
			# PRIMEIRA tela após "Usar Poder": apenas as duas escolhas.
			# Nunca mostrar rótulos de etapas anteriores nesta tela.
			for chave in (["diagonal", "pintar"] if PINTURA_GAMER_ATIVA else ["diagonal"]):
				var botao: Button = botoes_acao_nova[chave]
				botao.visible = true
				botao.disabled = not acao_permitida_no_tutorial_novo(chave)
		"diagonal_fada", "diagonal_destino", "pintar_alvo", "pintar_cor":
			var chave_botao: String = "diagonal" if acao_nova.begins_with("diagonal") else "pintar"
			var botao: Button = botoes_acao_nova[chave_botao]
			botao.visible = true
			botao.disabled = true
			match acao_nova:
				"diagonal_fada": botao.text = "Escolha a Fada"
				"diagonal_destino": botao.text = "Escolha onde Pousar"
				"pintar_alvo": botao.text = "Escolha onde Pintar"
				"pintar_cor": botao.text = "Qual a nova cor?"
		_:
			# Estado desconhecido: nenhum botão de ação fica exposto.
			return

	if acao_nova != "" and (acao_nova != "plantar" or flor_na_mao == ""):
		botoes_acao_nova["cancelar"].visible = true
		# Uma carta comprada continua reservada: ela não pode ser devolvida
		# ao baralho, mas ainda é possível cancelar um movimento de flor.
		botoes_acao_nova["cancelar"].disabled = (flor_na_mao != "" and acao_nova == "plantar")

	# Controles em uma linha interna ao painel de compra, sem cobrir cartas/mesa.
	var ordem: Array[String] = ["poderes", "diagonal", "pintar", "cancelar"]
	var visiveis: Array[Button] = []
	for chave in ordem:
		var candidato: Button = botoes_acao_nova[chave]
		if candidato.visible:
			visiveis.append(candidato)
	if visiveis.is_empty():
		return
	var margem: float = 8.0
	var espaco: float = 11.0 if area_acoes_gamer.size.x >= 400.0 else 7.0
	var n: int = visiveis.size()
	var largura: float = maxf(1.0, (area_acoes_gamer.size.x - margem * 2.0 - espaco * float(n - 1)) / float(n))
	var altura: float = minf(44.0, maxf(29.0, area_acoes_gamer.size.y - 5.0))
	var largura_total: float = largura * float(n) + espaco * float(n - 1)
	var inicio_x: float = area_acoes_gamer.get_center().x - largura_total * 0.5
	var y: float = area_acoes_gamer.get_center().y - altura * 0.5
	for i in range(n):
		var b: Button = visiveis[i]
		b.position = Vector2(inicio_x + float(i) * (largura + espaco), y)
		b.size = Vector2(largura, altura)
		b.add_theme_font_size_override("font_size", 12 if largura >= 138.0 else (10 if largura >= 105.0 else 9))

func consumir_polens_do_pouso(dono: int, destino: Vector2i) -> bool:
	# Rotina legada de cobrança desativada por tem_voo_livre() = false.
	# O custo pertence EXCLUSIVAMENTE a cor da flor de destino.
	if dono < 0 or dono >= jogadores.size() or not tabuleiro.has(destino):
		return false
	var cor_pouso: String = str(tabuleiro[destino])
	if not CORES.has(cor_pouso):
		return false
	var estoque: Dictionary = jogadores[dono]["polens"]
	if int(estoque.get(cor_pouso, 0)) < 1:
		return false
	estoque[cor_pouso] = int(estoque[cor_pouso]) - 1
	polens_gastos_no_voo_pendente = 1
	return true

func destinos_diagonais_da_fada(indice: int) -> Array[Vector2i]:
	# Poder VOAR: a fada escolhe exatamente a flor de pouso, sem precisar
	# chegar à última flor da linha. Retas e diagonais têm o mesmo custo.
	var destinos: Array[Vector2i] = []
	if indice < 0 or indice >= fadas.size() or jogadores.is_empty():
		return destinos
	var dona: int = int(fadas[indice]["dono"])
	var origem: Vector2i = fadas[indice]["casa"]
	var estoque: Dictionary = jogadores[dona]["polens"]
	for chave in tabuleiro:
		var destino: Vector2i = chave
		var cor: String = str(tabuleiro[destino])
		var alinhada: bool = trajetoria_ortogonal(origem, destino) or trajetoria_diagonal(origem, destino)
		if alinhada and CORES.has(cor) and int(estoque.get(cor, 0)) >= 1:
			destinos.append(destino)
	return destinos

func escolher_fada_para_voo_diagonal(indice: int) -> void:
	if acao_nova != "diagonal_fada" or indice < 0 or indice >= fadas.size():
		return
	if int(fadas[indice]["dono"]) != jogador_atual:
		return
	if destinos_diagonais_da_fada(indice).is_empty():
		# Não há movimento legal para esta fada: deixar a seleção aberta
		# e explicar exatamente a condição de pagamento ao jogador.
		mensagem = "Esta fada ainda não pode Voar: precisa haver uma flor alinhada (reta ou diagonal) e 1 pólen da COR dessa flor. Escolha outra fada ou Cancele."
		atualizar_interface_acoes_nova()
		queue_redraw()
		return
	fada_diagonal_pendente = indice
	acao_nova = "diagonal_destino"
	mensagem = "Escolha onde pousar: as flores acessíveis estão com contorno azul."
	atualizar_interface_acoes_nova()
	queue_redraw()

func realizar_voo_diagonal_novo(_destino: Vector2i) -> void:
	return

func concluir_poder_sem_plantio(casas_alteradas: Array[Vector2i] = [], estado_anterior: Dictionary = {}) -> void:
	var antes: Dictionary = estado_anterior if not estado_anterior.is_empty() else tabuleiro.duplicate()
	limpar_etapa_fadas()
	acao_nova = ""
	fada_poder_preselecionada = -1
	fada_diagonal_pendente = -1
	alvo_transformacao = CELULA_INVALIDA
	atualizar_interface_acoes_nova()
	finalizar_jogada(casas_alteradas, antes)

func continuar_apos_tutorial() -> void:
	if not tutorial_final_pendente or estado_tela != "partida":
		return
	# A mesma mesa e a mesma reserva permanecem. E uma pratica de um
	# jogador, sem limite de turnos, encerrada ao completar seis objetivos.
	tutorial_final_pendente = false
	tutorial_pratica_livre = true
	tutorial_passo_consulta = -1
	tutorial_etapa = "pratica"
	mensagem = "Continue o tutorial até completar 6 objetivos. Para terminar antes, use o ícone de saída."
	atualizar_botoes_de_movimento()
	sincronizar_botoes_menu()
	queue_redraw()

func passo_tutorial_atual() -> int:
	# A numeração acompanha o progresso real, não o texto consultado.
	match tutorial_etapa:
		"coletiva": return 1
		"colocar_primeira": return 2
		"baralho": return 3
		"colocar_baralho": return 4
		"fada", "fada_movendo": return 5
		"afastar": return 6
		"destino_afastar": return 7
		"coletiva_repor": return 8
		"esperar_repor": return 9
		"fada_livre", "fada_livre_movendo": return 10
		"pratica": return clampi(11 + turnos_jogados - 3, 11, 17)
	return 1

func mostrar_instrucao_atual_tutorial() -> void:
	if not (aprender_ativo() or tutorial_novo_ativo() or tutorial_final_pendente):
		return
	if not cenarios_anteriores.is_empty():
		indice_estado_tutorial = cenarios_anteriores.size() - 1
		var estado: Dictionary = cenarios_anteriores[indice_estado_tutorial].get("estado_tutorial", {})
		if not estado.is_empty():
			restaurar_estado_tutorial(estado)

func v200_altura_painel_menu(tela: Vector2) -> float:
	# As telas de leitura e resultado aproveitam a altura do retrato.
	var limite: float = 860.0 if estado_tela in ["resultado", "explicacao_pontuacao", "regras", "catalogo_objetivos"] else 620.0
	return minf(limite, ui_area_segura().size.y - 24.0)

func sincronizar_botoes_menu() -> void:
	if not is_instance_valid(botao_abertura_aprender):
		return
	sincronizar_capa_animada()
	mostrar_botoes_abertura()
	var tela: Vector2 = get_viewport_rect().size
	var painel_largura: float = minf(540.0, ui_area_segura().size.x - 28.0)
	var painel_altura: float = v200_altura_painel_menu(tela)
	var topo_painel: float = (tela.y - painel_altura) * 0.5
	var esquerda_painel: float = (tela.x - painel_largura) * 0.5
	var compacto: bool = painel_altura < 370.0
	var largura: float = minf(320.0, painel_largura - 28.0)
	var x: float = (tela.x - largura) * 0.5
	botao_abertura_aprender.visible = estado_tela == "inicio"
	botao_abertura_jogar.visible = estado_tela == "inicio"
	atualizar_interface_acoes_nova()
	atualizar_interface_poder()
	botao_regras_voltar.visible = estado_tela in ["regras", "catalogo_objetivos"]
	texto_regras_completas.visible = estado_tela == "regras"
	botao_catalogo_anterior.visible = estado_tela == "catalogo_objetivos"
	botao_catalogo_proximo.visible = estado_tela == "catalogo_objetivos"
	# Modalidades ficam acessíveis exclusivamente após clicar em Jogar.
	botao_menu_duelo.visible = estado_tela == "escolha_modo"
	botao_menu_maquina.visible = estado_tela == "escolha_modo"
	botao_menu_voltar.visible = estado_tela == "escolha_modo"
	botao_maquina_medio.visible = estado_tela == "escolha_maquina"
	botao_maquina_dificil.visible = estado_tela == "escolha_maquina"
	botao_maquina_voltar.visible = estado_tela == "escolha_maquina"
	botao_maquinas_1.visible = estado_tela == "escolha_quantidade_maquinas"
	botao_maquinas_2.visible = estado_tela == "escolha_quantidade_maquinas"
	botao_maquinas_3.visible = estado_tela == "escolha_quantidade_maquinas"
	botao_maquinas_voltar.visible = estado_tela == "escolha_quantidade_maquinas"
	botao_pontuacao_entenda.visible = estado_tela == "resultado"
	botao_resultado_inicio.visible = estado_tela == "resultado"
	botao_pontuacao_voltar.visible = estado_tela == "explicacao_pontuacao"
	texto_pontuacao_explicacao.visible = estado_tela == "explicacao_pontuacao"

	if estado_tela == "inicio":
		posicionar_botoes_abertura_ilustrada(tela)

	# A tela Jogar exibe somente as modalidades disponíveis nesta versão.
	var altura_modo: float = 64.0 if tela.y >= 650.0 else 48.0
	var espaco_modo: float = 12.0 if tela.y >= 650.0 else 8.0
	var passo_modo: float = altura_modo + espaco_modo
	var topo_ideal_modo: float = topo_painel + painel_altura * 0.31
	var botoes_modo: Array[Button] = []
	botoes_modo.append_array([botao_menu_duelo, botao_menu_maquina, botao_menu_voltar])
	var topo_maximo_modo: float = topo_painel + painel_altura - 12.0 - altura_modo - float(botoes_modo.size() - 1) * passo_modo
	var topo_modo: float = minf(topo_ideal_modo, topo_maximo_modo)
	for i in range(botoes_modo.size()):
		botoes_modo[i].position = Vector2(x, topo_modo + float(i) * passo_modo)
		botoes_modo[i].size = Vector2(largura, altura_modo)
		botoes_modo[i].add_theme_font_size_override("font_size", 23 if tela.x >= 380.0 else 19)

	# Escolha da dificuldade da Máquina, com o estilo dos botões do menu.
	var botoes_maquina: Array[Button] = [botao_maquina_medio, botao_maquina_dificil, botao_maquina_voltar]
	var topo_maquina: float = minf(topo_ideal_modo,
		topo_painel + painel_altura - 12.0 - altura_modo - 2.0 * passo_modo)
	for i in range(botoes_maquina.size()):
		botoes_maquina[i].position = Vector2(x, topo_maquina + float(i) * passo_modo)
		botoes_maquina[i].size = Vector2(largura, altura_modo)
		botoes_maquina[i].add_theme_font_size_override("font_size", 23 if tela.x >= 380.0 else 19)

	var botoes_quantidade_maquinas: Array[Button] = [botao_maquinas_1, botao_maquinas_2, botao_maquinas_3, botao_maquinas_voltar]
	var topo_quantidade_maquinas: float = minf(topo_ideal_modo,
		topo_painel + painel_altura - 12.0 - altura_modo - 3.0 * passo_modo)
	for i in range(botoes_quantidade_maquinas.size()):
		botoes_quantidade_maquinas[i].position = Vector2(x, topo_quantidade_maquinas + float(i) * passo_modo)
		botoes_quantidade_maquinas[i].size = Vector2(largura, altura_modo)
		botoes_quantidade_maquinas[i].add_theme_font_size_override("font_size", 23 if tela.x >= 380.0 else 19)

	# Placar: tres botoes exclusivos no rodape e duas areas para os jogadores.
	var altura_resultado: float = altura_botoes_resultado()
	var espaco_resultado: float = 5.0 if compacto else 8.0
	var margem_inferior: float = 10.0 if compacto else 12.0
	# Em telas baixas, quatro botoes ocupam duas colunas e duas linhas.
	var colunas_placar: int = 2 if painel_altura < 420.0 else 1
	var botoes_placar: Array[Button] = [botao_pontuacao_entenda]
	botoes_placar.append(botao_resultado_inicio)
	var linhas_placar: int = ceili(float(botoes_placar.size()) / float(colunas_placar))
	var topo_resultado_botoes: float = topo_painel + painel_altura - margem_inferior - float(linhas_placar) * altura_resultado - float(linhas_placar - 1) * espaco_resultado
	var largura_placar: float = (largura - float(colunas_placar - 1) * espaco_resultado) / float(colunas_placar)
	for i in range(botoes_placar.size()):
		var botao: Button = botoes_placar[i]
		botao.position = Vector2(x + float(i % colunas_placar) * (largura_placar + espaco_resultado),
			topo_resultado_botoes + float(floori(float(i) / float(colunas_placar))) * (altura_resultado + espaco_resultado))
		botao.size = Vector2(largura_placar, altura_resultado)
		botao.add_theme_font_size_override("font_size", 14 if colunas_placar == 2 else 22)

	# Tela explicativa com texto rolavel, sem ficar por cima do botao Voltar.
	botao_pontuacao_voltar.position = Vector2(x, topo_painel + painel_altura - margem_inferior - altura_resultado)
	botao_pontuacao_voltar.size = Vector2(largura, altura_resultado)
	botao_pontuacao_voltar.add_theme_font_size_override("font_size", 17 if compacto else 22)
	var margem_explicacao: float = 22.0 if painel_largura >= 400.0 else 16.0
	var topo_explicacao: float = topo_painel + (62.0 if compacto else 108.0)
	texto_pontuacao_explicacao.position = Vector2(esquerda_painel + margem_explicacao, topo_explicacao)
	texto_pontuacao_explicacao.size = Vector2(
		maxf(40.0, painel_largura - 2.0 * margem_explicacao),
		maxf(30.0, botao_pontuacao_voltar.position.y - topo_explicacao - 12.0)
	)
	texto_pontuacao_explicacao.add_theme_font_size_override("normal_font_size", 17 if compacto else 22)
	texto_pontuacao_explicacao.add_theme_constant_override("line_separation", 7)
	texto_pontuacao_explicacao.add_theme_font_size_override("bold_font_size", 18 if compacto else 23)

	# Manual do menu inicial: mesmo cartaz, texto com rolagem e retorno fixo.
	botao_regras_voltar.position = Vector2(x, topo_painel + painel_altura - margem_inferior - altura_resultado)
	botao_regras_voltar.size = Vector2(largura, altura_resultado)
	botao_regras_voltar.add_theme_font_size_override("font_size", 17 if compacto else 22)
	# Paginação do catálogo sem texto sobre as cartas.
	var largura_navegacao: float = (largura - 10.0) * 0.5
	var topo_navegacao: float = botao_regras_voltar.position.y - (38.0 if compacto else 45.0)
	botao_catalogo_anterior.position = Vector2(x, topo_navegacao)
	botao_catalogo_proximo.position = Vector2(x + largura_navegacao + 10.0, topo_navegacao)
	botao_catalogo_anterior.size = Vector2(largura_navegacao, 30.0 if compacto else 34.0)
	botao_catalogo_proximo.size = botao_catalogo_anterior.size
	var capacidade_catalogo: int = itens_por_pagina_catalogo()
	var ultima_catalogo: int = maxi(0, int(ceil(float(cartas_catalogo_visual.size()) / float(capacidade_catalogo))) - 1)
	pagina_catalogo = clampi(pagina_catalogo, 0, ultima_catalogo)
	botao_catalogo_anterior.disabled = pagina_catalogo <= 0
	botao_catalogo_proximo.disabled = pagina_catalogo >= ultima_catalogo
	var topo_regras: float = topo_painel + (58.0 if compacto else 88.0)
	texto_regras_completas.position = Vector2(esquerda_painel + margem_explicacao, topo_regras)
	texto_regras_completas.size = Vector2(
		maxf(40.0, painel_largura - 2.0 * margem_explicacao),
		maxf(30.0, botao_regras_voltar.position.y - topo_regras - 12.0)
	)
	texto_regras_completas.add_theme_font_size_override("normal_font_size", 17 if compacto else 21)
	texto_regras_completas.add_theme_constant_override("line_separation", 6)
	texto_regras_completas.add_theme_font_size_override("bold_font_size", 18 if compacto else 22)

	var paginas: int = total_paginas_resultado()
	pagina_resultado = clampi(pagina_resultado, 0, maxi(0, paginas - 1))
	botao_resultado_anterior.visible = estado_tela == "resultado" and paginas > 1
	botao_resultado_proximo.visible = estado_tela == "resultado" and paginas > 1
	botao_resultado_anterior.disabled = pagina_resultado <= 0
	botao_resultado_proximo.disabled = pagina_resultado >= paginas - 1
	# Paginação em uma linha própria, nunca sobre a mensagem do vencedor.
	var nav_y: float = topo_painel + (43.0 if painel_altura < 500.0 else 53.0)
	var nav_lado: float = 48.0
	botao_resultado_anterior.position = Vector2(esquerda_painel + 14.0, nav_y)
	botao_resultado_proximo.position = Vector2(esquerda_painel + painel_largura - 14.0 - nav_lado, nav_y)
	botao_resultado_anterior.size = Vector2(nav_lado, nav_lado)
	botao_resultado_proximo.size = Vector2(nav_lado, nav_lado)
	botao_resultado_anterior.add_theme_font_size_override("font_size", 26)
	botao_resultado_proximo.add_theme_font_size_override("font_size", 26)

func abrir_explicacao_pontuacao() -> void:
	if estado_tela != "resultado":
		return
	texto_pontuacao_explicacao.text = """[color=#f9d28a][b]Objetivos concluídos[/b][/color]
Some as estrelas de todas as cartas que você completou. Os objetivos florais não são duplicados.

[color=#f9d28a][b]Pólens guardados[/b][/color]
Cada pólen coletado vale [b]1 estrela[/b]. Os pólens que ainda estão no jardim não pontuam.

[color=#f9d28a][b]Trincas da mesma cor[/b][/color]
Cada grupo de três pólens rende mais [b]2 estrelas de bônus[/b], totalizando 5 estrelas por trinca.

[b]Exemplo[/b]
3 pólens = 5 estrelas
6 pólens = 10 estrelas
7 pólens = 11 estrelas

[color=#f9d28a][b]Pontuação final[/b][/color]
Some as estrelas dos objetivos, dos pólens guardados e dos bônus de trincas. Vence quem somar mais estrelas."""
	estado_tela = "explicacao_pontuacao"
	texto_pontuacao_explicacao.scroll_to_line(0)
	sincronizar_botoes_menu()
	queue_redraw()

func voltar_placar_geral() -> void:
	if estado_tela != "explicacao_pontuacao":
		return
	estado_tela = "resultado"
	sincronizar_botoes_menu()
	queue_redraw()


# v183 — confirmação de saída; pausar também timers e corrotinas do jogo.
func aguardar_frame_jogo() -> void:
	await get_tree().process_frame
	while pausa_saida_ativa and is_inside_tree():
		await get_tree().process_frame

func criar_confirmacao_saida() -> void:
	var camada: CanvasLayer = CanvasLayer.new()
	camada.name = "CamadaConfirmacaoSaida"
	camada.layer = 50
	camada.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camada)
	confirmacao_saida = ColorRect.new()
	confirmacao_saida.color = Color(0.03, 0.02, 0.01, 0.78)
	confirmacao_saida.mouse_filter = Control.MOUSE_FILTER_STOP
	camada.add_child(confirmacao_saida)
	confirmacao_saida.hide()
	caixa_confirmacao_saida = PanelContainer.new()
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = UI_SUPERFICIE
	estilo.border_color = Color("bd995e")
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(12)
	estilo.content_margin_left = 16.0
	estilo.content_margin_right = 16.0
	estilo.content_margin_top = 18.0
	estilo.content_margin_bottom = 16.0
	caixa_confirmacao_saida.add_theme_stylebox_override("panel", estilo)
	confirmacao_saida.add_child(caixa_confirmacao_saida)
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 14)
	caixa_confirmacao_saida.add_child(coluna)
	var titulo: Label = Label.new()
	titulo.text = "Sair da partida?"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override("font", fonte_destaque)
	titulo.add_theme_font_size_override("font_size", 27)
	titulo.add_theme_color_override("font_color", COR_OURO)
	coluna.add_child(titulo)
	var descricao: Label = Label.new()
	descricao.text = "A partida será encerrada e o placar será exibido."
	descricao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descricao.add_theme_font_size_override("font_size", 21)
	descricao.add_theme_color_override("font_color", COR_TEXTO)
	coluna.add_child(descricao)
	var acoes: HBoxContainer = HBoxContainer.new()
	acoes.add_theme_constant_override("separation", 10)
	coluna.add_child(acoes)
	botao_cancelar_saida = Button.new()
	botao_cancelar_saida.text = "Cancelar"
	botao_cancelar_saida.custom_minimum_size = Vector2(0.0, 56.0)
	botao_cancelar_saida.add_theme_font_size_override("font_size", 21)
	botao_cancelar_saida.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	configurar_visual_botao_dourado(botao_cancelar_saida)
	botao_cancelar_saida.pressed.connect(cancelar_saida_partida)
	acoes.add_child(botao_cancelar_saida)
	botao_confirmar_saida = Button.new()
	botao_confirmar_saida.text = "Sair"
	botao_confirmar_saida.custom_minimum_size = Vector2(0.0, 56.0)
	botao_confirmar_saida.add_theme_font_size_override("font_size", 21)
	botao_confirmar_saida.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	configurar_visual_botao_dourado(botao_confirmar_saida)
	botao_confirmar_saida.pressed.connect(confirmar_saida_partida)
	acoes.add_child(botao_confirmar_saida)
	# Cancelar é o foco inicial; Escape também cancela quando um botão tem foco.
	for b in [botao_cancelar_saida, botao_confirmar_saida]:
		b.gui_input.connect(func(event: InputEvent):
			if event.is_action_pressed("ui_cancel"):
				get_viewport().set_input_as_handled()
				cancelar_saida_partida())
	atualizar_posicao_confirmacao_saida()

func atualizar_posicao_confirmacao_saida() -> void:
	if not is_instance_valid(confirmacao_saida):
		return
	var tela: Vector2 = get_viewport_rect().size
	confirmacao_saida.size = tela
	var tamanho: Vector2 = Vector2(minf(370.0, ui_area_segura().size.x - 24.0), 228.0)
	caixa_confirmacao_saida.size = tamanho
	caixa_confirmacao_saida.position = (tela - tamanho) * 0.5

func solicitar_saida_partida() -> void:
	aula_nav_cancelar_gesto()
	if estado_tela != "partida" or partida_encerrada or pausa_saida_ativa or not is_instance_valid(confirmacao_saida):
		return
	mobile_limpar_intencao()
	mobile_dedos.clear()
	pontos_multitoque.clear()
	gesto_multitoque_ativo = false
	mobile_gesto_cancelado = false
	saida_pressionada = false
	atualizar_posicao_confirmacao_saida()
	pausa_saida_ativa = true
	v199_parar_ambiente()
	get_tree().paused = true
	confirmacao_saida.show()
	botao_cancelar_saida.grab_focus()

func fechar_confirmacao_saida() -> void:
	if not pausa_saida_ativa:
		return
	confirmacao_saida.hide()
	pausa_saida_ativa = false
	get_tree().paused = false
	mobile_limpar_intencao()
	saida_pressionada = false
	queue_redraw()

func cancelar_saida_partida() -> void:
	fechar_confirmacao_saida()

func confirmar_saida_partida() -> void:
	if not pausa_saida_ativa:
		return
	fechar_confirmacao_saida()
	# Preserva o comportamento do antigo X: encerrar e apurar o placar.
	encerrar_partida()

func desenhar_icone_saida() -> void:
	# Botão no cabeçalho, alinhado ao placar.
	var sobre: bool = botao_encerrar.has_point(mouse_pos)
	ui_superficie(botao_encerrar.grow(-3.0), Color("473a30") if sobre else UI_PAINEL, UI_BORDA, 7)
	var c: Vector2 = botao_encerrar.get_center()
	var d: float = botao_encerrar.size.x / 48.0
	var cor: Color = COR_TEXTO
	# Porta aberta e seta para fora: desenho vetorial independente da fonte.
	var porta: PackedVector2Array = PackedVector2Array([c + Vector2(1, -12) * d,
		c + Vector2(-11, -12) * d, c + Vector2(-11, 12) * d,
		c + Vector2(1, 12) * d])
	draw_polyline(porta, cor, 2.2 * d, true)
	draw_line(c + Vector2(-4, 0) * d, c + Vector2(12, 0) * d, cor, 2.2 * d, true)
	draw_polyline(PackedVector2Array([c + Vector2(6, -6) * d, c + Vector2(12, 0) * d,
		c + Vector2(6, 6) * d]), cor, 2.2 * d, true)

func abrir_menu_ao_pedir_novo_jogo() -> void:
	juice_limpar()
	retornar_abertura()

func retornar_abertura() -> void:
	if conquistas_abertas:
		fechar_conquistas()
	# Ao voltar da partida invalida temporizadores antigos e limpa interacoes.
	identificador_partida += 1
	escolhas_iniciais_pendentes = false
	indice_cenario_em_revisao = -1
	toque_tabuleiro = false
	toque_arrastou = false
	limpar_etapa_fadas()
	identificador_movimento += 1
	estado_tela = "inicio"
	sincronizar_botoes_menu()
	queue_redraw()

func iniciar_tutorial_novo() -> void:
	# As duas versões públicas começam diretamente na mesa, com dicas breves.
	iniciar_modo("aprender_novo")


func abrir_selecao_modo() -> void:
	# "Jogar" abre as modalidades da versão atual.
	# Nenhuma modalidade deve aparecer antes desta ação.
	indice_cenario_em_revisao = -1
	toque_tabuleiro = false
	toque_arrastou = false
	limpar_etapa_fadas()
	identificador_partida += 1
	identificador_movimento += 1
	estado_tela = "escolha_modo"
	sincronizar_botoes_menu()
	queue_redraw()

func voltar_inicio() -> void:
	limpar_etapa_fadas()
	identificador_partida += 1
	identificador_movimento += 1
	atualizar_pontos_catalogos_da_versao()
	estado_tela = "inicio"
	sincronizar_botoes_menu()
	queue_redraw()

func aprender_ativo() -> bool:
	return modo_partida == "aprender" and estado_tela == "partida" and not partida_encerrada and not tutorial_pratica_livre and not tutorial_final_pendente

func iniciar_duelo() -> void:
	# Duelo Local é sempre uma partida entre dois jogadores humanos.
	iniciar_modo("duelo")

# Versão Original: mesmas modalidades, mas somente objetivos Grandes.
func voltar_da_selecao_maquina() -> void:
	abrir_escolha_quantidade_maquinas()

func voltar_da_escolha_quantidade_maquinas() -> void:
	abrir_selecao_modo()

func abrir_escolha_quantidade_maquinas() -> void:
	identificador_partida += 1
	identificador_movimento += 1
	estado_tela = "escolha_quantidade_maquinas"
	sincronizar_botoes_menu()
	queue_redraw()

func selecionar_quantidade_maquinas(total: int) -> void:
	quantidade_maquinas_partida = clampi(total, 1, 3)
	abrir_dificuldades_maquina_direto()

func abrir_dificuldades_maquina_direto() -> void:
	identificador_partida += 1
	identificador_movimento += 1
	estado_tela = "escolha_maquina"
	sincronizar_botoes_menu()
	queue_redraw()

func iniciar_maquina_nivel(nivel: String) -> void:
	if not PERFIS_MAQUINA.has(nivel):
		return
	dificuldade_maquina = nivel
	iniciar_modo("maquina")

func nome_dificuldade_maquina() -> String:
	match dificuldade_maquina:
		"dificil": return "Difícil"
	return "Normal"

func iniciar_modo(novo_modo: String) -> void:
	aula_duelo = (eh_gamer() or eh_alternativa()) and novo_modo in ["aprender", "aprender_novo"]
	if aula_duelo:
		novo_modo = "maquina"
		quantidade_maquinas_partida = 1
		dificuldade_maquina = "medio"
	# Modos públicos: tutorial, duelo local e contra a máquina.
	if novo_modo not in ["aprender_novo", "duelo", "maquina", "aula"]:
		return
	modo_partida = novo_modo
	estado_tela = "partida"
	novo_jogo()
	sincronizar_botoes_menu()
	queue_redraw()

# v120: paleta marrom/dourada compartilhada pela abertura, menus e jogo.
func configurar_visual_botao_dourado(botao: Button) -> void:
	var secundario: bool = botao.text.to_lower().begins_with("voltar") or botao.text in ["X", "‹", "›", "Menu Inicial", "Cancelar", "Entenda as Estrelas"]
	var perigo: bool = botao.text == "Sair"
	for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
		var chave: String = ("d:" if perigo else ("s:" if secundario else "p:")) + estado
		if not _ui_botoes.has(chave):
			var estilo: StyleBoxFlat = StyleBoxFlat.new()
			var paleta: Dictionary = {"normal": UI_ACAO, "hover": UI_ACAO_HOVER, "pressed": UI_ACAO_PRESSIONADA, "disabled": Color("3b3d36")}
			if secundario:
				paleta = {"normal": Color("474137"), "hover": Color("595144"), "pressed": Color("363129"), "disabled": Color("393731")}
			if perigo:
				paleta = {"normal": Color("75483e"), "hover": Color("89584b"), "pressed": Color("57362e"), "disabled": Color("423832")}
			if estado == "focus":
				estilo.draw_center = false
			else:
				estilo.bg_color = paleta[estado]
			estilo.border_color = Color("efd39c") if estado in ["hover", "focus"] else (Color("675844") if estado == "disabled" else Color("b49665"))
			estilo.set_border_width_all(2 if estado == "focus" else 1)
			estilo.set_corner_radius_all(13)
			estilo.corner_detail = 6
			estilo.content_margin_left = 11.0
			estilo.content_margin_right = 11.0
			estilo.content_margin_top = 5.0
			estilo.content_margin_bottom = 5.0
			if estado == "normal":
				estilo.shadow_color = Color(0.06, 0.04, 0.025, 0.30)
				estilo.shadow_size = 3
				estilo.shadow_offset = Vector2(0.0, 2.0)
			_ui_botoes[chave] = estilo
		botao.add_theme_stylebox_override(estado, _ui_botoes[chave])
	if fonte_destaque != null:
		botao.add_theme_font_override("font", fonte_destaque)
	for estado_cor in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		botao.add_theme_color_override(estado_cor, COR_TEXTO)
	botao.add_theme_color_override("font_disabled_color", Color("bcb5a8"))
	botao.add_theme_constant_override("outline_size", 0)
	botao.alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

# Distribuição calculada em coordenadas REAIS do viewport; funciona
# em retrato, paisagem, desktop, navegador e após girar o celular.
func mostrar_botoes_abertura() -> void:
	if estado_tela != "inicio" or not is_instance_valid(botao_abertura_aprender) or not is_instance_valid(botao_abertura_jogar):
		return
	posicionar_botoes_abertura_ilustrada(get_viewport_rect().size)
	botao_abertura_aprender.show()
	botao_abertura_jogar.show()

# Usar o mesmo enquadramento proporcional para o Sprite, o fallback e os botões.
func retangulo_abertura_ilustrada(tela: Vector2) -> Rect2:
	var tamanho_original: Vector2 = FUNDO_MENU_RETRATO.get_size()
	var fator: float = minf(tela.x / tamanho_original.x, tela.y / tamanho_original.y)
	var tamanho: Vector2 = tamanho_original * fator
	return Rect2((tela - tamanho) * 0.5, tamanho)

func posicionar_botoes_abertura_ilustrada(tela: Vector2) -> void:
	var arte: Rect2 = retangulo_abertura_ilustrada(tela)
	var largura: float = minf(ui_area_segura().size.x - 24.0, minf(arte.size.x - 32.0, arte.size.x * 0.76))
	var altura: float = clampf(arte.size.y * 0.075, 52.0, 64.0)
	var espaco: float = minf(14.0, arte.size.y * 0.012)
	var topo: float = minf(arte.position.y + arte.size.y * 0.74,
		minf(arte.end.y - arte.size.y * 0.045, ui_area_segura().end.y - 10.0) - 2.0 * altura - espaco)
	for i in range(2):
		var botao: Button = botao_abertura_aprender if i == 0 else botao_abertura_jogar
		botao.position = Vector2(arte.get_center().x - largura * 0.5, topo + float(i) * (altura + espaco))
		botao.size = Vector2(largura, altura)
		botao.add_theme_font_size_override("font_size", clampi(roundi(altura * 0.44), 12, 23))

func criar_capa_animada() -> void:
	# Sprite independente do desenho do tabuleiro; não intercepta cliques.
	capa_animada = Sprite2D.new()
	capa_animada.name = "CapaAnimada"
	capa_animada.centered = false
	material_abertura = ShaderMaterial.new()
	material_abertura.shader = preload("res://assets/menu/abertura_animada.gdshader")
	capa_animada.material = material_abertura
	capa_animada.hide()
	add_child(capa_animada)
	move_child(capa_animada, 0)

func sincronizar_capa_animada() -> void:
	if not is_instance_valid(capa_animada):
		return
	var mostrar: bool = estado_tela == "inicio"
	if mostrar != abertura_visivel:
		abertura_visivel = mostrar
		capa_animada.visible = mostrar
		if mostrar:
			tempo_animacao_abertura = 0.0
			material_abertura.set_shader_parameter("tempo", 0.0)
		else:
			# A animação nunca deixa botões transparentes ao sair do menu.
			for botao in [botao_abertura_aprender, botao_abertura_jogar]:
				if is_instance_valid(botao):
					botao.self_modulate = Color.WHITE
	if not mostrar:
		return
	var tela: Vector2 = get_viewport_rect().size
	if tela.x <= 0.0 or tela.y <= 0.0:
		return
	if tela != abertura_tela_anterior or capa_animada.texture == null:
		var retrato: bool = true
		capa_animada.texture = FUNDO_MENU_RETRATO
		var arte: Rect2 = retangulo_abertura_ilustrada(tela)
		capa_animada.position = arte.position
		capa_animada.scale = arte.size / capa_animada.texture.get_size()
		material_abertura.set_shader_parameter("retrato", retrato)
		abertura_tela_anterior = tela

func atualizar_animacao_menu(delta: float) -> void:
	if not is_instance_valid(capa_animada):
		return
	sincronizar_capa_animada()
	tempo_animacao_abertura += minf(delta, 0.05)
	material_abertura.set_shader_parameter("tempo", tempo_animacao_abertura)
	var intensidade: float = [0.45, 1.0, 1.20][juice_nivel]
	material_abertura.set_shader_parameter("intensidade", intensidade)
	material_abertura.set_shader_parameter("modo_leve", v209_leve)
	# Entrada escalonada sem deslocar os alvos de toque nem impedir cliques.
	for i in range(2):
		var botao: Button = botao_abertura_aprender if i == 0 else botao_abertura_jogar
		if not is_instance_valid(botao):
			continue
		var t: float = interpolar_suave((tempo_animacao_abertura - float(i) * 0.12) / 0.55)
		var alpha: float = lerpf(0.65, 1.0, t)
		var alvo: float = 1.0 if not botao.is_hovered() else 1.09
		var tom: float = move_toward(botao.self_modulate.r, alvo, delta * 1.4)
		botao.self_modulate = Color(tom, tom, tom, alpha)

func desenhar_abertura_ilustrada() -> void:
	if is_instance_valid(capa_animada) and capa_animada.visible and capa_animada.texture != null:
		return # A camada animada usa o enquadramento proporcional da abertura.
	# A imagem original é a base estática; o Sprite2D animado fica sobre ela
	# e abaixo dos botões reais. Em outras telas o Sprite2D é ocultado.
	var tela: Vector2 = get_viewport_rect().size
	var fundo: Texture2D = FUNDO_MENU_RETRATO
	draw_texture_rect(fundo, retangulo_abertura_ilustrada(tela), false)

func configurar_visual_botao(botao: Button) -> void:
	# Tema unificado: todos os botoes do jogo seguem a identidade dourada.
	configurar_visual_botao_dourado(botao)
	botao.alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func atualizar_botoes_de_movimento() -> void:
	# Novos controles magicos aparecem somente nas etapas correspondentes.
	atualizar_interface_poder()
	queue_redraw()

func preparar_audio_web() -> void:
	if not OS.has_feature("web"):
		return
	# O toque precisa chegar ao JavaScript NATIVO, inclusive no Safari/iOS.
	# O áudio sintetizado permanece idêntico; não há mídia externa nem autoplay.
	var codigo: String = """
(function () {
  if (window.__jardimAudio121) return true;
  const Audio = window.AudioContext || window.webkitAudioContext;
  if (!Audio) return false;
  let ctx = null, enabled = true, unlocking = null, epoch = 0;
  const raw = new Map(), buffers = new Map(), sources = new Set();
  let flight = null, ambient = null;
  function stopAmbient() {
    if (!ambient) return;
    const a = ambient; ambient = null;
    try { a.gain.gain.setTargetAtTime(0, ctx.currentTime, .04); a.node.stop(ctx.currentTime + .18); } catch (_) { try { a.node.stop(); } catch (_) {} }
  }
  function setAmbient(db) {
    if (!enabled || !ctx || ctx.state !== 'running') { stopAmbient(); return false; }
    try {
      if (!ambient) {
        const b = buffer('ambiente_jardim'); if (!b) return false;
        const node = ctx.createBufferSource(), gain = ctx.createGain();
        node.buffer = b; node.loop = true; gain.gain.value = 0;
        node.connect(gain); gain.connect(ctx.destination);
        const a = {node,gain}; ambient = a;
        node.onended = () => { if (ambient === a) ambient = null; node.disconnect(); gain.disconnect(); };
        node.start();
      }
      ambient.gain.gain.setTargetAtTime(Math.pow(10,db/20), ctx.currentTime, .18);
      return true;
    } catch (_) { stopAmbient(); return false; }
  }
  function stopFlight() {
    if (!flight) return;
    const f = flight; flight = null;
    try {
      const now = ctx.currentTime;
      f.gain.gain.cancelScheduledValues(now);
      f.gain.gain.setTargetAtTime(0, now, 0.009);
      f.node.stop(now + 0.045);
    } catch (_) { try { f.node.stop(); } catch (_) {} }
  }
  function setFlight(db, pitch) {
    if (!enabled || !ctx || ctx.state !== 'running') { stopFlight(); return false; }
    try {
      const now = ctx.currentTime;
      if (!flight) {
        const b = buffer('voo_ar'); if (!b) return false;
        const node = ctx.createBufferSource(), gain = ctx.createGain();
        node.buffer = b; node.loop = true; node.playbackRate.value = pitch;
        gain.gain.value = 0; node.connect(gain); gain.connect(ctx.destination);
        const f = {node, gain}; flight = f;
        node.onended = () => { if (flight === f) flight = null; node.disconnect(); gain.disconnect(); };
        node.start();
      }
      flight.gain.gain.setTargetAtTime(Math.pow(10, db / 20), now, 0.022);
      flight.node.playbackRate.setTargetAtTime(pitch, now, 0.026);
      return true;
    } catch (_) { stopFlight(); return false; }
  }
  function unlock(event) {
    if (!event.isTrusted) return;
    try {
      if (!ctx || ctx.state === 'closed') { stopFlight(); stopAmbient(); ctx = new Audio(); buffers.clear(); }
      if (ctx.state !== 'running') {
        // A chamada a resume ocorre dentro do evento DOM de toque/clique.
        const promise = ctx.resume();
        const attempt = Promise.resolve(promise).catch(() => {});
        unlocking = attempt;
        attempt.then(() => { if (unlocking === attempt) unlocking = null; });
      }
    } catch (_) { unlocking = null; }
  }
  for (const name of ['pointerdown','pointerup','touchstart','touchend','mousedown','click','keydown']) {
    window.addEventListener(name, unlock, {capture:true, passive:true});
  }
  function buffer(id) {
    if (buffers.has(id)) return buffers.get(id);
    const item = raw.get(id);
    if (!item || !ctx) return null;
    const bytes = atob(item.pcm), count = Math.floor(bytes.length / 2);
    const b = ctx.createBuffer(1, count, item.rate);
    const out = b.getChannelData(0);
    for (let i = 0; i < count; i++) {
      let sample = bytes.charCodeAt(2*i) | (bytes.charCodeAt(2*i+1) << 8);
      if (sample >= 32768) sample -= 65536;
      out[i] = sample / 32768;
    }
    buffers.set(id, b);
    return b;
  }
  function playNow(id, db, token, pitch = 1) {
    if (!enabled || token !== epoch || !ctx || ctx.state !== 'running' || sources.size >= 12) return;
    try {
      const b = buffer(id);
      if (!b) return;
      const node = ctx.createBufferSource(), gain = ctx.createGain();
      node.buffer = b; node.playbackRate.value = pitch; gain.gain.value = Math.pow(10, db / 20);
      node.connect(gain); gain.connect(ctx.destination);
      sources.add(node);
      node.onended = () => { sources.delete(node); node.disconnect(); gain.disconnect(); };
      node.start();
    } catch (_) {}
  }
  window.__jardimAudio121 = {
    register(id, pcm, rate) { raw.set(id, {pcm, rate}); buffers.delete(id); },
    setFlight, stopFlight, setAmbient, stopAmbient,
    setEnabled(value) {
      enabled = value; epoch++;
      if (!enabled) { stopFlight(); stopAmbient(); }
      if (!enabled) { for (const node of sources) { try { node.stop(); } catch (_) {} } sources.clear(); }
    },
    play(id, db, pitch = 1) {
      if (!enabled) return true;
      if (!ctx) return false;
      const token = epoch;
      if (ctx && ctx.state === 'running') playNow(id, db, token, pitch);
      else if (unlocking) unlocking.then(() => playNow(id, db, token, pitch));
      else return false;
      return true;
    }
  };
  return true;
})()
"""
	var resultado: Variant = JavaScriptBridge.eval(codigo, true)
	audio_web_disponivel = resultado == true
	if not audio_web_disponivel:
		return
	var ponte: JavaScriptObject = JavaScriptBridge.get_interface("__jardimAudio121")
	if ponte == null:
		audio_web_disponivel = false
		return
	ponte.setEnabled(audio_ativo)
	for id_som in amostras_som:
		var amostra: AudioStreamWAV = amostras_som[id_som]
		ponte.register(str(id_som), Marshalls.raw_to_base64(amostra.data), amostra.mix_rate)

func preparar_audio() -> void:
	# Foley sintetizado uma vez: papel, asas, terra e motivos melódicos clássicos.
	# Sem downloads ou arquivos externos; voo e ambiente usam canais contínuos.
	var ids: Array[String] = [
		"ambiente_jardim", "selecionar", "colocar", "mover", "objetivo", "objetivo_maquina",
		"pontos", "cancelar", "inicio", "fim", "passo_fada", "entrada_fada",
		"polinizar", "coleta_1", "coleta_2", "coleta_4", "coleta_5",
		"voo_coleta_boa", "voo_coleta_grande",
		"papel_coletiva", "papel_saque", "papel_virar", "papel_deslizar",
		"plantar_terra", "papel_mover", "papel_girar", "papel_objetivo",
		"papel_arquivo", "papel_chegada", "voo_ar", "pouso_fada", "polen_acomodar",
		"polen_nascer", "polen_chegada", "polen_transferir",
		"janela_abrir", "janela_fechar", "botao", "invalido",
		"duplicar"
	]
	for id_som in ids:
		amostras_som[id_som] = gerar_audio_em_memoria(id_som)

	# Diversos canais evitam que o toque de coleta corte conquistas e avisos.
	for i in range(12):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "EfeitoSonoro_%d" % i
		player.volume_db = -9.0
		add_child(player)
		canais_som.append(player)
	canal_voo_beija_flor = AudioStreamPlayer.new()
	canal_voo_beija_flor.name = "VooBeijaFlor"
	canal_voo_beija_flor.stream = amostras_som["voo_ar"]
	canal_voo_beija_flor.volume_db = -60.0
	add_child(canal_voo_beija_flor)
	ambiente_canal = AudioStreamPlayer.new()
	ambiente_canal.name = "AmbienteJardim"
	ambiente_canal.stream = amostras_som["ambiente_jardim"]
	ambiente_canal.volume_db = -60.0
	add_child(ambiente_canal)

func parar_audio_voo() -> void:
	if voo_audio_web_ativo and audio_web_disponivel:
		var ponte: JavaScriptObject = JavaScriptBridge.get_interface("__jardimAudio121")
		if ponte != null:
			ponte.stopFlight()
	voo_audio_web_ativo = false
	perf_audio_web_proximo = 0.0
	if is_instance_valid(canal_voo_beija_flor) and canal_voo_beija_flor.playing:
		canal_voo_beija_flor.stop()
	voo_audio_volume = -60.0
	voo_audio_pitch = 0.85

func atualizar_audio_voo(delta: float) -> void:
	if not audio_ativo or estado_tela != "partida" or etapa_fada != "movendo" or partida_encerrada or indice_cenario_em_revisao >= 0 or juice_voo.is_empty():
		parar_audio_voo()
		return
	if not is_instance_valid(canal_voo_beija_flor):
		return
	var fase: String = str(juice_voo.get("fase", ""))
	var t: float = interpolar_suave(juice_progresso(juice_voo))
	var volume_alvo: float = -18.0
	var pitch_alvo: float = 1.0
	match fase:
		"decolar":
			volume_alvo = lerpf(-24.0, -18.0, t)
			pitch_alvo = lerpf(0.78, 1.0, t)
		"viajar":
			# O som das asas permanece contínuo, inclusive durante a coleta.
			# As notas dos pólens se sobrepõem ao voo sem reduzir seu volume.
			pitch_alvo = 1.0 + 0.010 * sin((juice_relogio - float(juice_voo["inicio_global"])) * 2.0)
		"pousar":
			volume_alvo = lerpf(-18.0, -46.0, t)
			pitch_alvo = lerpf(1.0, 0.74, t)
	# v234: asas dos adversarios mais discretas, inclusive na exportacao Web.
	if turno_da_maquina():
		volume_alvo -= 4.0
	var suavizar: float = 1.0 - exp(-delta * 38.0)
	voo_audio_volume = lerpf(voo_audio_volume, volume_alvo, suavizar)
	voo_audio_pitch = lerpf(voo_audio_pitch, pitch_alvo, suavizar)
	if audio_web_disponivel:
		if voo_audio_web_ativo and juice_relogio < perf_audio_web_proximo:
			return
		perf_audio_web_proximo = juice_relogio + 1.0 / 30.0
		var ponte: JavaScriptObject = JavaScriptBridge.get_interface("__jardimAudio121")
		if ponte != null and ponte.setFlight(voo_audio_volume, voo_audio_pitch) == true:
			voo_audio_web_ativo = true
			if canal_voo_beija_flor.playing:
				canal_voo_beija_flor.stop()
			return
	voo_audio_web_ativo = false
	canal_voo_beija_flor.volume_db = voo_audio_volume
	canal_voo_beija_flor.pitch_scale = voo_audio_pitch
	if not canal_voo_beija_flor.playing:
		canal_voo_beija_flor.play()

func tocar_som(id_som: String, altura_som: float = 1.0) -> void:
	if id_som in ["voo_ar", "ambiente_jardim"] or not audio_ativo or not amostras_som.has(id_som) or canais_som.is_empty():
		return
	# Mix v154: foley variado, asas suaves e motivos clássicos de recompensa.
	var volumes: Dictionary = {
		"passo_fada": -25.0,
		"cancelar": -10.5,
		"colocar": -17.0,
		"entrada_fada": -17.0,
		"polinizar": -21.0,
		"coleta_1": -17.5,
		"coleta_2": -17.0,
		"coleta_4": -16.5,
		"coleta_5": -16.0,
		"voo_coleta_boa": -26.0,
		"voo_coleta_grande": -25.0,
		"objetivo": -14.0,
		"objetivo_maquina": -16.0,
		"pontos": -17.0,
		"fim": -17.0,
		"papel_coletiva": -17.0,
		"papel_saque": -18.0,
		"papel_virar": -16.0,
		"papel_deslizar": -16.0,
		"plantar_terra": -16.5,
		"papel_mover": -19.0,
		"papel_girar": -20.0,
		"papel_objetivo": -18.0,
		"papel_arquivo": -21.0,
		"papel_chegada": -22.0,
		"pouso_fada": -14.0,
		"polen_acomodar": -24.0,
		"polen_nascer": -26.0,
		"polen_chegada": -26.0,
		"polen_transferir": -25.0,
		"janela_abrir": -22.0,
		"janela_fechar": -23.0,
		"botao": -23.0,
		"invalido": -21.0,
		"duplicar": -16.0
	}
	var volume: float = float(volumes.get(id_som, -20.0))
	# v234: atenua apenas efeitos da jogada automatica, sem alterar setup ou interface.
	if id_som == "objetivo_maquina" or (turno_da_maquina() and not animacao_setup_ativa and id_som not in ["inicio", "fim", "entrada_fada", "botao", "janela_abrir", "janela_fechar", "invalido"]):
		volume -= 4.0
	# Variação cosmética: não consome a sequência aleatória do jogo.
	if id_som.begins_with("papel_") or id_som == "plantar_terra":
		altura_som *= 0.94 + float(Time.get_ticks_usec() % 121) / 1000.0
	elif id_som.begins_with("coleta_") or id_som in ["polinizar", "polen_chegada", "polen_transferir"]:
		# Variação pequena para manter o motivo melódico reconhecível.
		altura_som = 0.98 + float(Time.get_ticks_usec() % 41) / 1000.0
	if audio_web_disponivel:
		var ponte: JavaScriptObject = JavaScriptBridge.get_interface("__jardimAudio121")
		if ponte != null:
			if ponte.play(id_som, volume, altura_som) == true:
				return
	for canal in canais_som:
		if not canal.playing:
			canal.volume_db = volume
			canal.pitch_scale = altura_som
			canal.stream = amostras_som[id_som]
			canal.play()
			return
	# Em uma situacao rara de muitos efeitos simultaneos, descartar um
	# efeito novo e preferivel a interromper a celebracao ou o som de coleta.

# Ataque e ressonância curta, amortecida e inarmônica, como uma semente sobre feltro.
func toque_semente(t: float, inicio: float, frequencia: float, queda: float) -> float:
	var dt: float = t - inicio
	if dt < 0.0:
		return 0.0
	var ataque: float = minf(1.0, dt / 0.004)
	var fase: float = TAU * frequencia * dt
	return ataque * (0.55 * sin(fase) * exp(-queda * dt) + 0.23 * sin(fase * 1.73) * exp(-queda * 1.9 * dt) + 0.10 * sin(fase * 2.81) * exp(-queda * 3.0 * dt))

# Envoltória assimétrica e suave de um movimento de asa ou de papel.
func pulso_foley(u: float, centro: float, largura: float) -> float:
	var distancia: float = (u - centro) / largura
	return exp(-distancia * distancia * 2.0)

func nota_suave(t: float, inicio: float, duracao: float, frequencia: float) -> float:
	# Voz curta de sino/madeira, com ataque pequeno e decaimento delicado.
	if t < inicio or t >= inicio + duracao:
		return 0.0
	var tempo: float = t - inicio
	var ataque: float = minf(1.0, tempo / 0.008)
	var queda: float = pow(1.0 - tempo / duracao, 2.1)
	var fase: float = TAU * frequencia * tempo
	return ataque * queda * (sin(fase) + 0.22 * sin(fase * 2.01) + 0.07 * sin(fase * 3.99))

# v202: foley das asas da v196, com pulsos periódicos independentes das casas.
# 16 batidas em 2 s, sem a pausa entre grupos de três batidas da amostra antiga.
# Pré-aquecimento circular dos filtros evita uma mudança de timbre na emenda.
func gerar_loop_asas_continuas() -> AudioStreamWAV:
	var quantidade: int = 2 * TAXA_AMOSTRAGEM_AUDIO
	var rng_asas: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_asas.seed = 12573 + absi("voo_ar".hash())
	var ruido: PackedFloat32Array = PackedFloat32Array()
	ruido.resize(quantidade)
	for i in range(quantidade):
		ruido[i] = rng_asas.randf_range(-1.0, 1.0)
	var dados: PackedByteArray = PackedByteArray()
	dados.resize(quantidade * 2)
	var ruido_filtrado: float = 0.0
	var ruido_lento: float = 0.0
	var textura_lenta: float = 0.0
	var ruido_anterior: float = ruido[quantidade - 513]
	for j in range(-512, quantidade):
		var ruido_cru: float = ruido[posmod(j, quantidade)]
		ruido_filtrado = lerpf(ruido_filtrado, ruido_cru, 0.20)
		ruido_lento = lerpf(ruido_lento, ruido_cru, 0.045)
		textura_lenta = lerpf(textura_lenta, ruido_cru, 0.012)
		var fibra: float = (ruido_filtrado - ruido_lento) * 1.95 + (ruido_cru - ruido_anterior) * 0.10
		ruido_anterior = ruido_cru
		if j < 0:
			continue
		var t: float = float(j) / float(TAXA_AMOSTRAGEM_AUDIO)
		var fase: float = t * 8.0
		var batida: int = floori(fase)
		var distancia: float = fposmod(fase, 1.0) - 0.5
		# Batidas alternadamente fortes e leves, com uma pequena cauda de ar.
		var forca: float = 0.93 if batida % 2 == 0 else 0.76
		var forca_vizinha: float = 0.76 if batida % 2 == 0 else 0.93
		var pulso: float = forca * exp(-2.0 * pow(distancia / 0.39, 2.0))
		pulso += forca_vizinha * (exp(-2.0 * pow((distancia - 1.0) / 0.39, 2.0)) + exp(-2.0 * pow((distancia + 1.0) / 0.39, 2.0)))
		var envelope: float = 0.10 + 0.85 * pulso
		var textura: float = clampf(0.87 + 2.4 * textura_lenta, 0.55, 1.15)
		var sinal: float = (ruido_filtrado * 0.68 + fibra * 0.38) * envelope * textura
		var valor: int = clampi(roundi(sinal * 32767.0), -32768, 32767)
		dados[j * 2] = valor & 255
		dados[j * 2 + 1] = (valor >> 8) & 255
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = TAXA_AMOSTRAGEM_AUDIO
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.data = dados
	wav.loop_begin = 0
	wav.loop_end = quantidade
	return wav

func gerar_audio_em_memoria(id_som: String) -> AudioStreamWAV:
	if id_som == "ambiente_jardim":
		return v199_gerar_ambiente()
	if id_som == "voo_ar":
		return gerar_loop_asas_continuas()
	# Sons de ações sintéticos; os loops são gerados pelas funções anteriores.
	var duracoes: Dictionary = {
		"selecionar": 0.17,
		"colocar": 0.30,
		"mover": 0.28,
		"objetivo": 0.72,
		"objetivo_maquina": 0.88,
		"pontos": 0.36,
		"cancelar": 0.19,
		"inicio": 0.42,
		"fim": 0.72,
		"passo_fada": 0.15,
		"entrada_fada": 0.16,
		"polinizar": 0.25,
		"coleta_1": 0.24,
		"coleta_2": 0.29,
		"coleta_4": 0.38,
		"coleta_5": 0.46,
		"voo_coleta_boa": 0.38,
		"voo_coleta_grande": 0.52,
		"papel_coletiva": 0.23,
		"papel_saque": 0.12,
		"papel_virar": 0.15,
		"papel_deslizar": 0.3,
		"plantar_terra": 0.56,
		"papel_mover": 0.34,
		"papel_girar": 0.14,
		"papel_objetivo": 0.27,
		"papel_arquivo": 0.24,
		"papel_chegada": 0.12,
		"pouso_fada": 0.20,
		"polen_acomodar": 0.16,
		"polen_nascer": 0.11,
		"polen_chegada": 0.1,
		"polen_transferir": 0.13,
		"janela_abrir": 0.18,
		"janela_fechar": 0.13,
		"botao": 0.075,
		"invalido": 0.11,
		"duplicar": 0.42
	}
	var duracao: float = float(duracoes.get(id_som, 0.20))
	var quantidade: int = ceili(duracao * float(TAXA_AMOSTRAGEM_AUDIO))
	var dados: PackedByteArray = PackedByteArray()
	dados.resize(quantidade * 2) # PCM16 mono, little-endian.
	var ruido_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	ruido_rng.seed = 12573 + absi(id_som.hash()) # Timbres distintos, sem alterar o baralho.
	var ruido_filtrado: float = 0.0
	var ruido_lento: float = 0.0
	var ruido_anterior: float = 0.0
	var textura_lenta: float = 0.0

	for i in range(quantidade):
		var t: float = float(i) / float(TAXA_AMOSTRAGEM_AUDIO)
		var ruido_cru: float = ruido_rng.randf_range(-1.0, 1.0)
		ruido_filtrado = lerpf(ruido_filtrado, ruido_cru, 0.20)
		ruido_lento = lerpf(ruido_lento, ruido_cru, 0.045)
		textura_lenta = lerpf(textura_lenta, ruido_cru, 0.012)
		var fibra: float = (ruido_filtrado - ruido_lento) * 1.95 + (ruido_cru - ruido_anterior) * 0.10
		ruido_anterior = ruido_cru
		var sinal: float = 0.0
		var u: float = t / duracao
		var arco: float = sin(PI * u)
		var papel: float = fibra * 0.78 + ruido_filtrado * 0.22
		# Irregularidade de fibras, não um oscilador periódico.
		var textura: float = clampf(0.87 + 2.4 * textura_lenta, 0.55, 1.15)
		var raspagem: float = arco * arco * textura
		var borda: float = pulso_foley(u, 0.15, 0.075) + 0.45 * pulso_foley(u, 0.81, 0.10)
		match id_som:
			"papel_coletiva":
				sinal = (ruido_filtrado * 0.52 + fibra * 0.25) * (0.85 * raspagem + 0.12 * pulso_foley(u, 0.74, 0.13))
			"papel_saque":
				sinal = fibra * (0.52 * pulso_foley(u, 0.22, 0.15) + 0.22 * pulso_foley(u, 0.57, 0.21)) + ruido_filtrado * 0.12 * arco
			"papel_virar":
				sinal = fibra * (0.24 * raspagem + 0.64 * pulso_foley(u, 0.47, 0.065)) + ruido_filtrado * 0.15 * pulso_foley(u, 0.66, 0.13)
			"papel_deslizar", "mover":
				sinal = (ruido_filtrado * 0.52 + fibra * 0.20) * raspagem
			"papel_mover":
				sinal = (ruido_filtrado * 0.48 + ruido_lento * 0.55) * (0.62 * raspagem + 0.13 * borda)
			"papel_girar":
				sinal = fibra * 0.36 * pulso_foley(u, 0.34, 0.21) + ruido_filtrado * 0.12 * arco
			"papel_arquivo":
				sinal = papel * (0.37 * pulso_foley(u, 0.36, 0.25) + 0.22 * pulso_foley(u, 0.77, 0.11))
			"papel_objetivo":
				sinal = fibra * (0.35 * pulso_foley(u, 0.16, 0.09) + 0.27 * pulso_foley(u, 0.41, 0.11) + 0.23 * pulso_foley(u, 0.69, 0.10))
			"inicio":
				sinal = 0.22 * nota_suave(t, 0.0, 0.27, 392.0) + 0.18 * nota_suave(t, 0.10, 0.30, 587.33)
			"papel_chegada":
				sinal = ruido_filtrado * 0.35 * exp(-44.0 * t) + 0.09 * toque_semente(t, 0.0, 155.0, 65.0)
			"colocar":
				# Folhas mexendo antes de pousar a nova flor; não é outra raspagem de papel.
				sinal = (fibra * 0.30 + ruido_filtrado * 0.20) * (0.52 * pulso_foley(u, 0.30, 0.19) + 0.36 * pulso_foley(u, 0.71, 0.14))
			"plantar_terra":
				# v228: lâmina entrando em areia solta, sem pancada nem ressonância metálica.
				var entrada_areia: float = smoothstep(0.0, 0.20, u)
				var penetracao: float = entrada_areia * (1.0 - smoothstep(0.34, 0.76, u))
				var acomodacao: float = smoothstep(0.40, 0.58, u) * (1.0 - smoothstep(0.65, 1.0, u))
				# Atrito de banda média, com grãos finos e irregularidades suaves.
				var areia: float = (ruido_filtrado - ruido_lento) * 1.25
				var graos_finos: float = (ruido_cru - ruido_filtrado) * 0.085
				var resistencia: float = ruido_lento * 0.50
				var granularidade: float = clampf(0.88 + textura_lenta * 3.0, 0.65, 1.15)
				sinal = (areia + graos_finos + resistencia) * penetracao * granularidade
				sinal += (areia * 0.38 + graos_finos * 0.42 + resistencia * 0.20) * acomodacao
			"pouso_fada":
				# Contato abafado com a flor, sem cauda de notas mágicas.
				sinal = 0.14 * toque_semente(t, 0.006, 310.0, 43.0) + 0.22 * ruido_lento * pulso_foley(u, 0.12, 0.16)
			"passo_fada":
				sinal = 0.16 * toque_semente(t, 0.012, 250.0, 35.0) + ruido_lento * 0.20 * pulso_foley(u, 0.19, 0.12)
			"entrada_fada":
				# Pequena peca de madeira pousando na mesa: ataque arredondado,
				# ressonancia curta e abafada, sem sino nem estalo agudo.
				var toque: float = (1.0 - exp(-160.0 * t)) * exp(-35.0 * t)
				var corpo: float = 0.31 * sin(TAU * 340.0 * t) + 0.09 * sin(TAU * 510.0 * t)
				var contato: float = 0.16 * (ruido_filtrado * 0.65 + ruido_lento * 0.35) * pulso_foley(u, 0.12, 0.11)
				sinal = corpo * toque + contato
			"polen_acomodar":
				# Semente pequena na reserva: ataque arredondado e brilho curto.
				sinal = 0.28 * toque_semente(t, 0.005, 510.0, 39.0) + 0.12 * nota_suave(t, 0.018, 0.13, 765.0)
			"polen_nascer":
				sinal = 0.24 * toque_semente(t, 0.012, 690.0, 34.0) + fibra * 0.10 * raspagem
			"polen_chegada", "polen_transferir":
				sinal = 0.24 * toque_semente(t, 0.008, 540.0, 48.0) + ruido_filtrado * 0.12 * exp(-50.0 * t)
			"voo_coleta_boa", "voo_coleta_grande":
				sinal = 0.17 * toque_semente(t, 0.015, 390.0, 25.0)
			"selecionar":
				sinal = 0.54 * exp(-27.0 * t) * (sin(TAU * 210.0 * t) + 0.32 * sin(TAU * 325.0 * t))
				sinal += 0.17 * ruido_filtrado * exp(-36.0 * t)
			"objetivo":
				sinal = 0.36 * nota_suave(t, 0.00, 0.27, 523.25)
				sinal += 0.35 * nota_suave(t, 0.15, 0.31, 659.25)
				sinal += 0.40 * nota_suave(t, 0.31, 0.39, 783.99)
			"objetivo_maquina":
				# Assinatura descendente do adversario: distinta do arpejo de vitoria.
				sinal = 0.34 * nota_suave(t, 0.00, 0.25, 659.25)
				sinal += 0.33 * nota_suave(t, 0.15, 0.28, 523.25)
				sinal += 0.35 * nota_suave(t, 0.32, 0.31, 392.00)
				sinal += 0.33 * nota_suave(t, 0.49, 0.36, 293.66)
				sinal += 0.055 * ruido_filtrado * exp(-7.0 * t)
			"pontos":
				sinal = 0.50 * nota_suave(t, 0.00, 0.34, 1046.50)
				sinal += 0.13 * nota_suave(t, 0.045, 0.25, 1567.98)
			"cancelar":
				sinal = 0.38 * nota_suave(t, 0.0, 0.17, 240.0)
				sinal += 0.13 * ruido_filtrado * exp(-29.0 * t)
			"coleta_1":
				# Um polen: somente um toque nitido.
				sinal = 0.32 * nota_suave(t, 0.00, 0.22, 587.33)
			"coleta_2":
				# Dois: pequena dupla ascendente.
				sinal = 0.32 * nota_suave(t, 0.00, 0.19, 587.33)
				sinal += 0.30 * nota_suave(t, 0.105, 0.18, 739.99)
			"coleta_4":
				# Tres ou quatro: tres tilintares mais ricos e breves.
				sinal = 0.28 * nota_suave(t, 0.00, 0.20, 587.33)
				sinal += 0.28 * nota_suave(t, 0.105, 0.20, 739.99)
				sinal += 0.31 * nota_suave(t, 0.205, 0.17, 880.00)
			"coleta_5":
				# Cinco ou mais polens coletados ao longo do voo: arpejo de destaque, com volume controlado.
				sinal = 0.27 * nota_suave(t, 0.00, 0.20, 587.33)
				sinal += 0.26 * nota_suave(t, 0.09, 0.22, 739.99)
				sinal += 0.28 * nota_suave(t, 0.18, 0.23, 880.00)
				sinal += 0.31 * nota_suave(t, 0.275, 0.18, 1174.66)
			"polinizar":
				# Um unico brilho suave confirma que a fada criou um polen.
				sinal = 0.22 * nota_suave(t, 0.00, 0.22, 739.99)
				sinal += 0.09 * nota_suave(t, 0.045, 0.17, 1108.73)
			"duplicar":
				sinal = 0.30 * nota_suave(t, 0.0, 0.24, 659.25) + 0.26 * nota_suave(t, 0.09, 0.25, 987.77) + 0.28 * nota_suave(t, 0.20, 0.21, 1318.51)
			"janela_abrir", "janela_fechar":
				sinal = 0.18 * nota_suave(t, 0.0, duracao * 0.92, 440.0 if id_som == "janela_abrir" else 330.0)
			"botao", "invalido":
				sinal = 0.27 * toque_semente(t, 0.0, 480.0 if id_som == "botao" else 190.0, 67.0)
			"fim":
				# Encerramento quente e contido, sem fanfarra ou arpejo.
				sinal = 0.24 * nota_suave(t, 0.0, 0.58, 293.66) + 0.15 * nota_suave(t, 0.10, 0.60, 440.0)

		if id_som.begins_with("coleta_"):
			var sopro: float = sin(TAU * (210.0 * t + 85.0 * t * t)) + 0.6 * sin(TAU * 327.0 * t + 1.4 * sin(TAU * 13.0 * t))
			sinal += (0.025 * sopro + 0.08 * ruido_lento) * arco * arco
			sinal += 0.028 * nota_suave(t, 0.035, duracao - 0.035, 880.0)
		var entrada: float = minf(1.0, t / 0.006)
		var saida: float = minf(1.0, (duracao - t) / 0.016)
		var amplitude: float = clampf(sinal * entrada * saida, -0.94, 0.94)
		var valor: int = clampi(roundi(amplitude * 32767.0), -32768, 32767)
		dados[i * 2] = valor & 255
		dados[i * 2 + 1] = (valor >> 8) & 255

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = TAXA_AMOSTRAGEM_AUDIO
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = dados
	return wav

func tocar_conquista_em_sequencia(id_partida: int, indice_jogador: int) -> void:
	# A máquina tem o motivo descendente clássico, em volume discreto.
	await get_tree().create_timer(0.15, false).timeout
	if not is_inside_tree() or id_partida != identificador_partida:
		return
	if modo_partida == "maquina" and indice_jogador >= 1:
		tocar_som("objetivo_maquina")
		return
	tocar_som("objetivo")
	await get_tree().create_timer(0.32, false).timeout
	if not is_inside_tree() or id_partida != identificador_partida:
		return
	tocar_som("pontos")

func tocar_final_depois_da_conquista(id_partida: int) -> void:
	await get_tree().create_timer(0.98, false).timeout
	if is_inside_tree() and id_partida == identificador_partida and partida_encerrada:
		tocar_som("fim")

func criar_botoes_historico() -> void:
	botao_historico_anterior = Button.new()
	botao_historico_anterior.text = "‹"
	botao_historico_anterior.mouse_filter = Control.MOUSE_FILTER_STOP
	botao_historico_anterior.add_theme_font_size_override("font_size", 20)
	configurar_visual_botao(botao_historico_anterior)
	botao_historico_anterior.pressed.connect(alterar_pagina_historico.bind(-1))
	add_child(botao_historico_anterior)

	botao_historico_proximo = Button.new()
	botao_historico_proximo.text = "›"
	botao_historico_proximo.mouse_filter = Control.MOUSE_FILTER_STOP
	botao_historico_proximo.add_theme_font_size_override("font_size", 20)
	configurar_visual_botao(botao_historico_proximo)
	botao_historico_proximo.pressed.connect(alterar_pagina_historico.bind(1))
	add_child(botao_historico_proximo)

# ============================================================================
# HISTORICO VISUAL DE JOGADAS: NUNCA DESFAZ OU ALTERA A PARTIDA
# ============================================================================
func restaurar_estado_tutorial(estado: Dictionary) -> void:
	# Só permite voltar em momentos estáveis. As tarefas assíncronas antigas
	# são invalidadas e não podem alterar o tabuleiro restaurado.
	identificador_partida += 1
	identificador_movimento += 1
	fechar_painel_escolha_de_objetivos()
	animacao_setup_ativa = false
	celebracao_objetivo_ativa = false
	duplicacao_ativa = false
	duplicacao_voo_ativo = false
	polens_em_tamanho_duplo = false
	animacoes_coleta_aula.clear()
	juice_reserva_refluxo.clear()
	juice_reserva_pousos.clear()
	juice_transicao_objetivos.clear()
	polens_novos_ampliados.clear()
	maquina_ocupada = false
	aguardando_reposicao_automatica = false
	movimento_pendente = false
	limpar_estado_movimento()
	limpar_etapa_fadas()
	flor_na_mao = ""
	origem_carta_selecionada = ""
	acao_nova = ""
	fada_poder_preselecionada = -1
	fada_diagonal_pendente = -1
	alvo_transformacao = CELULA_INVALIDA
	registro_voo_fada.clear()
	inimigo_deslocado_na_jogada = false
	deslocamento_inimigo_pendente = false
	partida_encerrada = false
	jogada_alteradas_pendentes.clear()
	jogada_estado_anterior_pendente.clear()
	jogada_casa_reposta_pendente = CELULA_INVALIDA
	tabuleiro = estado["tabuleiro"].duplicate(true)
	polens_por_casa = estado["polens_por_casa"].duplicate(true)
	ids_cartas = estado["ids_cartas"].duplicate(true)
	polen_inicial_pendente = estado.get("polen_inicial_pendente", {}).duplicate(true)
	jogadores.clear()
	for item in estado["jogadores"]:
		jogadores.append(item.duplicate(true))
	fadas.clear()
	for item in estado["fadas"]:
		fadas.append(item.duplicate(true))
	baralho.clear()
	for item in estado["baralho"]:
		baralho.append(str(item))
	flor_aberta = str(estado["flor_aberta"])
	proximo_id_carta = int(estado["proximo_id_carta"])
	linhas_pontuadas = estado["linhas_pontuadas"].duplicate(true)
	objetivos_ja_sorteados = estado["objetivos_ja_sorteados"].duplicate(true)
	objetivos_fada_sorteados = estado["objetivos_fada_sorteados"].duplicate(true)
	turnos_jogados = int(estado["turnos_jogados"])
	jogador_atual = int(estado["jogador_atual"])
	tutorial_etapa = str(estado["tutorial_etapa"])
	tutorial_novo_primeira_fada = int(estado["tutorial_novo_primeira_fada"])
	tutorial_voo_fada_indice = int(estado["tutorial_voo_fada_indice"])
	tutorial_voo_fada_origem = estado["tutorial_voo_fada_origem"]
	tutorial_rotacao_pronta = bool(estado["tutorial_rotacao_pronta"])
	tutorial_rotacao_configurada = bool(estado["tutorial_rotacao_configurada"])
	tutorial_final_pendente = bool(estado["tutorial_final_pendente"])
	tutorial_pratica_livre = bool(estado["tutorial_pratica_livre"])
	sorteador.state = int(estado["sorteador_estado"])
	# Os temporizadores da cena anterior foram invalidados; reprogramar
	# somente as flores que realmente ainda aguardavam polen natural.
	for id_pendente in polen_inicial_pendente.keys():
		surgir_polen_apos_um_segundo(int(id_pendente), identificador_partida)
	tutorial_passo_consulta = -1
	tutorial_passo_maximo = passo_tutorial_atual()
	indice_cenario_em_revisao = -1
	tutorial_painel_arrastando = false
	toque_tabuleiro = false
	toque_arrastou = false
	mensagem = "Tutorial: jogada %d. Você pode refazer a partir deste ponto." % (turnos_jogados + 1)
	atualizar_interface_acoes_nova()
	sincronizar_botoes_menu()
	queue_redraw()

func pode_abrir_revisao_visual() -> bool:
	if animacao_compra_ativa or not juice_plantar.is_empty() or not juice_repor.is_empty():
		return false
	return (estado_tela == "partida" and not partida_encerrada
		and not turno_da_maquina() and not maquina_ocupada
		and etapa_fada == "" and not movimento_pendente
		and not aguardando_reposicao_automatica
		and not celebracao_objetivo_ativa and not duplicacao_ativa and not animacao_setup_ativa
		and origem_selecionada == CELULA_INVALIDA)

func sair_da_revisao_visual() -> void:
	# Em revisao pos-partida, Atual/Placar retorna ao resultado inalterado.
	if revisao_final_ativa:
		revisao_final_ativa = false
		estado_tela = "resultado"
	indice_cenario_em_revisao = -1
	toque_tabuleiro = false
	toque_arrastou = false
	sincronizar_botoes_menu()
	queue_redraw()

func colunas_historico() -> int:
	return maxi(1, floori((area_janela_conquistas.size.x - 24.0 + 7.0) / (tamanho_carta_historico() + 7.0)))

func tamanho_carta_historico() -> float:
	var largura: float = (area_janela_conquistas.size.x - 38.0) / 3.0
	return clampf(minf(largura, (area_janela_conquistas.size.y - 100.0) / 2.0), 34.0, 128.0)

func capacidade_pagina_historico() -> int:
	var lado: float = tamanho_carta_historico()
	var linhas: int = maxi(1, floori((area_janela_conquistas.size.y - 116.0 + 7.0) / (lado + 7.0)))
	return colunas_historico() * linhas

func pode_abrir_conquistas() -> bool:
	if animacao_compra_ativa or not juice_plantar.is_empty() or not juice_repor.is_empty():
		return false
	return estado_tela == "partida" and not jogadores.is_empty() and indice_cenario_em_revisao < 0 and not turno_da_maquina() and not animacao_setup_ativa and not celebracao_objetivo_ativa and not duplicacao_ativa and not escolha_objetivo_ativa and not escolhas_iniciais_pendentes and not tutorial_final_pendente and not partida_encerrada and not aguardando_reposicao_automatica and etapa_fada != "movendo" and not pintura_aguardando_cor()

func abrir_conquistas() -> void:
	if not pode_abrir_conquistas():
		return
	conquistas_abertas = true
	conquistas_jogador = jogador_atual
	toque_tabuleiro = false
	toque_arrastou = false
	pontos_multitoque.clear()
	gesto_multitoque_ativo = false
	# A janela é desenhada pelo Node2D principal; os Controls existentes
	# ficam atrás dele temporariamente, sem perder sua visibilidade/estado.
	for filho in get_children():
		if filho is Control:
			var controle: Control = filho as Control
			conquistas_controles_atras[controle] = controle.show_behind_parent
			controle.show_behind_parent = true
	queue_redraw()

func fechar_conquistas() -> void:
	conquistas_abertas = false
	conquistas_jogador = -1
	for filho in conquistas_controles_atras:
		if is_instance_valid(filho):
			var controle: Control = filho as Control
			controle.show_behind_parent = bool(conquistas_controles_atras[filho])
	conquistas_controles_atras.clear()
	queue_redraw()

func atualizar_botoes_historico() -> void:
	# Os botões antigos não aparecem mais no tabuleiro.
	if is_instance_valid(botao_historico_anterior):
		botao_historico_anterior.hide()
		botao_historico_proximo.hide()
	if conquistas_abertas and (not pode_abrir_conquistas() or conquistas_jogador != jogador_atual):
		fechar_conquistas()
	if estado_tela != "partida" or jogadores.is_empty() or jogador_atual >= pagina_historico.size():
		return
	var historico: Array = jogadores[jogador_atual].get("historico_objetivos", [])
	var total_paginas: int = maxi(1, ceili(float(historico.size()) / float(capacidade_pagina_historico())))
	pagina_historico[jogador_atual] = clampi(pagina_historico[jogador_atual], 0, total_paginas - 1)

func alterar_pagina_historico(direcao: int) -> void:
	if duplicacao_ativa or estado_tela != "partida" or jogadores.is_empty():
		return
	var historico: Array = jogadores[jogador_atual]["historico_objetivos"]
	var capacidade: int = capacidade_pagina_historico()
	var maximo: int = maxi(0, int(ceil(float(historico.size()) / float(capacidade))) - 1)
	pagina_historico[jogador_atual] = clampi(pagina_historico[jogador_atual] + direcao, 0, maximo)
	atualizar_botoes_historico()
	queue_redraw()

# Identifica o DESAFIO representado pela carta, sem depender do ID.
# Duas cartas sao iguais quando as mesmas flores/cores podem ser posicionadas
# por translacao e rotacao de 90 graus, segundo as regras de cada modelo.
# Nao considera espelhamento quando o modelo proibe espelhar.
func montar_catalogo_objetivos_grandes() -> void:
	catalogo_objetivos_grandes.clear()
	var assinaturas_catalogadas: Dictionary = {}
	# v104: o catálogo ATIVO contém apenas os Médios comprovadamente
	# inalcançáveis na primeira jogada e os Difíceis da fase posterior.
	# Os demais modelos permanecem em MODELOS_OBJETIVO e no arquivo de reserva.
	for tipo in [5, 11, 13, 14, 15, 17, 19, 21, 23, 24, 25, 26, 28, 29, 30]:
		var modelo: Dictionary = MODELOS_OBJETIVO[tipo]
		for cor_a in CORES:
			for cor_b in CORES:
				if cor_a == cor_b:
					continue
				var objetivo: Dictionary = {
					"id": "gamer:%d:%s:%s" % [tipo, cor_a, cor_b],
					"tipo": tipo, "cor_a": cor_a, "cor_b": cor_b,
					"pontos": int(modelo["pontos"]),
					"tamanho": "grande" # Tipo Medio ou Dificil; a fase nao depende dos pontos
				}
				objetivo["assinatura_rotacional"] = assinatura_rotacional_objetivo(objetivo)
				# Assinatura por fase preserva os catálogos Médio e Difícil.
				var fase: String = "dificil" if TIPOS_DIFICEIS_ATIVOS.has(tipo) else "medio"
				var assinatura: String = fase + "|" + str(objetivo["assinatura_rotacional"])
				if assinaturas_catalogadas.has(assinatura):
					continue
				assinaturas_catalogadas[assinatura] = true
				catalogo_objetivos_grandes.append(objetivo)
	print("Catálogo v116: %d cartas florais de Médios seguros e Difíceis (sem Pequenos)." %
		catalogo_objetivos_grandes.size())

# Diversidade obrigatoria por jogador: nunca manter dois objetivos ativos com
# o mesmo tipo (flor ou fada). Nas cartas florais, dois pares de cores iguais,
# independentemente da ordem A/B, tambem sao proibidos na mesma mao.
func quantidade_do_tipo_na_mao(objetivos_da_mao: Array[Dictionary], candidata: Dictionary) -> int:
	if candidata.is_empty():
		return 0
	var classe: String = str(candidata.get("classe", "flor"))
	var campo_tipo: String = "fada_id" if classe == "fada" else "tipo"
	var tipo: int = int(candidata.get(campo_tipo, -1))
	var quantidade: int = 0
	for existente in objetivos_da_mao:
		if existente.is_empty() or str(existente.get("classe", "flor")) != classe:
			continue
		if int(existente.get(campo_tipo, -2)) == tipo:
			quantidade += 1
	return quantidade

func preferir_tipos_diferentes(opcoes: Array[Dictionary], objetivos_da_mao: Array[Dictionary]) -> Array[Dictionary]:
	# Sem flexibilizacao: dois objetivos do mesmo tipo nao coexistem na mao.
	var preferidas: Array[Dictionary] = []
	for candidata in opcoes:
		if quantidade_do_tipo_na_mao(objetivos_da_mao, candidata) == 0:
			preferidas.append(candidata)
	return preferidas

func objetivo_repetiria_cores_na_mao(candidata: Dictionary, objetivos_da_mao: Array[Dictionary]) -> bool:
	# As cores A/B de cada desenho podem aparecer em ordem oposta; a ordem
	# nao muda o par que o jogador ja tem em suas cartas florais ativas.
	if candidata.is_empty() or str(candidata.get("classe", "flor")) == "fada":
		return false
	var par_candidato: String = assinatura_cores_objetivo(candidata)
	for ativa in objetivos_da_mao:
		if ativa.is_empty() or str(ativa.get("classe", "flor")) == "fada":
			continue
		if assinatura_cores_objetivo(ativa) == par_candidato:
			return true
	return false

# Sorteio de objetivos florais: Original e Expandida: Médios 3–4 / Difíceis 5–7.
func novo_objetivo_grande(excluir: Array[Dictionary] = [], objetivos_da_mao: Array[Dictionary] = [],
		faixa_pontos: int = 0) -> Dictionary:
	# Etiquetas de fase legadas: 46 = Médio, 78 = Difícil; classificação por tipo, não por estrelas.
	# Expandida: mesmas fases 46 / 78; depois da terceira conquista,
	# duas cartas Difíceis e duas cartas de Fada.
	if faixa_pontos == 34:
		faixa_pontos = 46
	if faixa_pontos == 0 and (eh_gamer() or eh_alternativa()):
		faixa_pontos = 78 if (jogador_atual >= 0 and jogador_atual < jogadores.size()
			and bool(jogadores[jogador_atual].get("fase_dificil_ativa", false))) else 46
	# O catalogo ja elimina repeticoes por rotacao. A validacao das
	# assinaturas ativas permanece como defesa adicional.
	var assinaturas_ativas: Dictionary = {}
	for carta_ativa in excluir:
		if carta_ativa.is_empty() or str(carta_ativa.get("classe", "flor")) == "fada":
			continue
		assinaturas_ativas[assinatura_rotacional_objetivo(carta_ativa)] = true
	var disponiveis: Array[Dictionary] = []
	for objetivo in catalogo_objetivos_grandes:
		# Avaliar a pontuação efetiva da modalidade, mesmo se o catálogo
		# tiver sido montado antes de abrir o menu dessa versão.
		var valor_objetivo: int = pontos_florais_na_versao(int(objetivo["tipo"]))
		if faixa_pontos == 23 and valor_objetivo not in [2, 3]:
			continue
		if faixa_pontos == 56 and valor_objetivo not in [5, 6]:
			continue
		if faixa_pontos == 46 and int(objetivo["tipo"]) not in TIPOS_MEDIOS_ABERTURA_SEGURA:
			continue
		if faixa_pontos == 78 and int(objetivo["tipo"]) not in TIPOS_DIFICEIS_ATIVOS:
			continue
		# Pequenos arquivados são excluídos nas duas versões públicas.
		if (eh_gamer() or eh_alternativa()) and (int(objetivo["tipo"]) not in TIPOS_MEDIOS_ABERTURA_SEGURA and int(objetivo["tipo"]) not in TIPOS_DIFICEIS_ATIVOS):
			continue
		# Não distribuir objetivos já integralmente formados no jardim.
		if objetivos_ja_sorteados.has(str(objetivo["id"])):
			continue
		# Em qualquer versao, objetivos novos exigem uma combinacao ainda nao formada.
		if objetivo_completo_no_setup(objetivo):
			continue
		if assinaturas_ativas.has(str(objetivo["assinatura_rotacional"])):
			continue
		# Nas partidas competitivas, o par de cores nunca se repete na mão.
		if objetivo_repetiria_cores_na_mao(objetivo, objetivos_da_mao):
			continue
		disponiveis.append(objetivo)
	var preferidas: Array[Dictionary] = []
	preferidas = preferir_tipos_diferentes(disponiveis, objetivos_da_mao)
	if preferidas.is_empty():
		push_error("Falha ao distribuir três objetivos na Original, fase %d." % faixa_pontos)
		return {}
	var escolhido: Dictionary = preferidas[sorteador.randi_range(0, preferidas.size() - 1)].duplicate(true)
	escolhido["pontos"] = pontos_florais_na_versao(int(escolhido["tipo"]))
	# Uma carta reciclada recebe ID único: IDs antigos permanecem em
	# linhas_pontuadas, e não podem impedir uma nova conquista legítima.
	if objetivos_ja_sorteados.has(str(escolhido["id"])):
		escolhido["id"] = "%s:reuso:%d" % [str(escolhido["id"]), objetivos_ja_sorteados.size()]
	objetivos_ja_sorteados[str(escolhido["id"])] = true
	return escolhido

# Ambas as versões: três primeiras conquistas com Médios (3–4);
# a partir da quarta conquista, Difíceis (5–7).
func faixa_objetivos_original(indice_jogador: int) -> int:
	if indice_jogador < 0 or indice_jogador >= jogadores.size():
		return 46
	return 78 if bool(jogadores[indice_jogador].get("fase_dificil_ativa", false)) else 46

func ativar_objetivos_grandes(indice_jogador: int) -> void:
	# Na Expandida, a terceira conquista abre dois Difíceis e dois de Fada.
	if indice_jogador < 0 or indice_jogador >= jogadores.size():
		return
	var jogador: Dictionary = jogadores[indice_jogador]
	if bool(jogador.get("fase_dificil_ativa", false)) or int(jogador["objetivos_concluidos"]) < 3:
		return
	# A terceira conquista descarta TODOS os objetivos restantes.
	# A nova mão não preserva cartas antigas, mesmo as quase concluídas.
	var objetivos_novos: Array[Dictionary] = []
	var faixas: Array[String] = []
	var totais_florais: int = 2 if eh_alternativa() else 3
	for _i in range(totais_florais):
		objetivos_novos.append(novo_objetivo_grande(objetivos_novos, objetivos_novos, 78))
		faixas.append("dificil")
	for _i in range(2):
		var fada_nova: Dictionary = sortear_objetivo_fada(objetivos_novos)
		objetivos_novos.append(fada_nova)
		faixas.append("fada")
		registrar_objetivo_fada_entregue(fada_nova, indice_jogador)
	jogador["fadas_desbloqueadas"] = true
	# O painel, a IA e a reposição passam a consultar a fase avançada.
	jogador["objetivos"] = objetivos_novos
	jogador.erase("aula_previa_objetivos")
	jogador["faixas_objetivos"] = faixas
	jogador["fase_grandes_ativa"] = true
	jogador["fase_dificil_ativa"] = true
	mensagem = "%s entraram na fase Difícil (5–7 estrelas) e desbloquearam 2 Objetivos de Fada!" % str(jogador["nome"])
	queue_redraw()

func assinatura_cores_objetivo(objetivo: Dictionary) -> String:
	if objetivo.is_empty() or str(objetivo.get("classe", "flor")) == "fada":
		return ""
	var cor_a: String = str(objetivo.get("cor_a", ""))
	var cor_b: String = str(objetivo.get("cor_b", ""))
	if cor_a == cor_b:
		push_error("Objetivo floral sem segunda cor: " + str(objetivo.get("id", "")))
		return cor_a
	if cor_a < cor_b:
		return cor_a + "+" + cor_b
	return cor_b + "+" + cor_a

func objetivo_completo_no_setup(objetivo: Dictionary) -> bool:
	# Valida TODO o jardim atual, tanto no setup quanto na reposicao de cartas.
	if objetivo.is_empty():
		return false
	var casas_iniciais: Array[Vector2i] = []
	for chave in tabuleiro:
		var casa: Vector2i = chave
		if CORES.has(str(tabuleiro[casa])):
			casas_iniciais.append(casa)
	return not listar_combinacoes_objetivo(casas_iniciais, objetivo, tabuleiro).is_empty()

func sortear_faixas_objetivos() -> Array[String]:
	# Original e Expandida começam com três Médios (3–4 pontos).
	return ["medio", "medio", "medio"]

func pontos_florais_na_versao(tipo: int) -> int:
	# v116: o tipo 23 vale 4 pontos nas duas versões; não há exceção de pontuação.
	return int(MODELOS_OBJETIVO[tipo]["pontos"])

func atualizar_pontos_catalogos_da_versao() -> void:
	for carta in catalogo_objetivos_grandes:
		carta["pontos"] = pontos_florais_na_versao(int(carta["tipo"]))

func pontuacao_fada_na_partida(modelo: Dictionary) -> int:
	if modelo.has("pontos_base"):
		var x: int = int(modelo["pontos_base"])
		var total: int = quantidade_jogadores()
		# Evitar alinhamento com TODAS as adversarias e mais dificil com mais jogadores.
		if bool(modelo.get("formula_soma", false)):
			return x + total
		return maxi(1, x - total)
	return int(modelo.get("pontos", 0))

func sortear_objetivo_fada(objetivos_da_mao: Array[Dictionary] = []) -> Dictionary:
	var disponiveis: Array[Dictionary] = []
	for chave in OBJETIVOS_FADA_MODELOS:
		var numero: int = int(chave)
		if numero >= 60 and (quantidade_jogadores() < 2 or modo_partida not in ["duelo", "maquina"]):
			continue # Nunca entregar objetivos de inimigo nos tutoriais.
		var copias: int = int(OBJETIVOS_FADA_COPIAS.get(numero, 1))
		for copia in range(1, copias + 1):
			var id_carta: String = "fada:%d:%d" % [numero, copia]
			if not objetivos_fada_sorteados.has(id_carta):
				var modelo: Dictionary = OBJETIVOS_FADA_MODELOS[numero]
				disponiveis.append({
					"id": id_carta, "classe": "fada", "fada_id": numero,
					"copia": copia, "titulo": str(modelo["titulo"]),
					"descricao": str(modelo["descricao"]),
					"pontos": pontuacao_fada_na_partida(modelo)
				})
	var preferidas: Array[Dictionary] = preferir_tipos_diferentes(disponiveis, objetivos_da_mao)
	if preferidas.is_empty():
		return {}
	var sorteada: Dictionary = preferidas[sorteador.randi_range(0, preferidas.size() - 1)]
	objetivos_fada_sorteados[str(sorteada["id"])] = true
	return sorteada

func objetivo_fada_atendido(numero: int, dados: Dictionary) -> bool:
	var total: int = int(dados.get("coletados", 0))
	var por_cor: Dictionary = dados.get("coletados_por_cor", {})
	match numero:
		2: return total >= 3
		3: return total >= 4
		8: return int(dados.get("maior_coleta_flor", 0)) >= 3
		10: return int(dados.get("flores_coletadas", 0)) >= 3
		11: return int(por_cor.get("vermelha", 0)) >= 1 and int(por_cor.get("amarela", 0)) >= 1
		12: return int(por_cor.get("vermelha", 0)) >= 1 and int(por_cor.get("lilas", 0)) >= 1
		13: return int(por_cor.get("amarela", 0)) >= 1 and int(por_cor.get("lilas", 0)) >= 1
		14: return int(por_cor.get("vermelha", 0)) >= 1 and int(por_cor.get("amarela", 0)) >= 1 and int(por_cor.get("lilas", 0)) >= 1
		15: return int(por_cor.get("vermelha", 0)) >= 2
		16: return int(por_cor.get("amarela", 0)) >= 2
		17: return int(por_cor.get("lilas", 0)) >= 2
		25: return int(dados.get("flores_visitadas", 0)) >= 4
		26: return int(dados.get("flores_visitadas", 0)) >= 5
		27: return int(dados.get("flores_coletadas", 0)) >= 4
	return false

func melhor_objetivo_de_fada_da_jogada(indice_jogador: int) -> Dictionary:
	if not registro_voo_fada.is_empty() and int(registro_voo_fada.get("dono", -1)) != indice_jogador:
		return {}
	if indice_jogador < 0 or indice_jogador >= jogadores.size():
		return {}
	var melhor: Dictionary = {}
	var objetivos: Array[Dictionary] = jogadores[indice_jogador]["objetivos"]
	for indice in range(objetivos.size()):
		var objetivo: Dictionary = objetivos[indice]
		if objetivo.is_empty() or str(objetivo.get("classe", "flor")) != "fada":
			continue
		if linhas_pontuadas.has(str(objetivo["id"])):
			continue
		var numero_fada: int = int(objetivo["fada_id"])
		if not objetivo_fada_comprovado(objetivo, indice_jogador):
			continue
		var pontos: int = int(objetivo["pontos"])
		if melhor.is_empty() or pontos > int(melhor["pontos"]):
			var chave: String = "fada"
			for casa in (casas_das_fadas_do_jogador(indice_jogador) if numero_fada >= 41 else registro_voo_fada.get("casas_flores", [])):
				chave += "|%d,%d" % [int(casa.x), int(casa.y)]
			melhor = {"indice": indice, "id": str(objetivo["id"]), "chave": chave, "pontos": pontos, "classe": "fada"}
	return melhor

# v128: sorteio independente de 6 permutações das cores e 2 orientações (0°/90°).
# Preserva três flores por cor, com a diagonal monocromática em qualquer sentido.
# A casa central é sempre uma flor FIXA, mas sua cor varia.
func preparar_setup_fixo_nove_flores() -> Array[String]:
	if aula_duelo:
		var desenho: Array[String] = []
		for cor in AULA_SETUP_NOVE_FLORES:
			desenho.append(str(cor))
			baralho.erase(str(cor))
		return desenho
	var cores_sorteadas: Array[String] = []
	for cor in CORES:
		cores_sorteadas.append(str(cor))
	for i in range(cores_sorteadas.size() - 1, 0, -1):
		var j: int = sorteador.randi_range(0, i)
		var temporaria: String = cores_sorteadas[i]
		cores_sorteadas[i] = cores_sorteadas[j]
		cores_sorteadas[j] = temporaria
	var correspondencia: Dictionary = {}
	for i in range(CORES.size()):
		correspondencia[str(CORES[i])] = cores_sorteadas[i]
	# Verifica a reserva antes de retirar qualquer carta.
	for cor in CORES:
		if baralho.count(str(cor)) < 3:
			push_error("Sem três flores %s suficientes para o setup inicial." % str(cor))
			return []
	var flores: Array[String] = []
	var girar: bool = sorteador.randi_range(0, 1) == 1
	# Ordem de leitura após rotação horária de todo o quadrado, não das cartas.
	var indices: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
	if girar:
		indices.assign([6, 3, 0, 7, 4, 1, 8, 5, 2])
	for indice in indices:
		var cor: String = str(correspondencia[str(SETUP_FIXO_NOVE_FLORES[indice])])
		baralho.erase(cor)
		flores.append(cor)
	return flores

# Setup v101 LEGADO, preservado somente para testes históricos.
# As quatro posições de canto só podem repetir cor em diagonais opostas;
# cada uma das três cores aparece pelo menos duas vezes nas oito flores.
# Gera a distribuição diretamente, sem sorteios por rejeição. Todas as
# flores retiradas para o setup são removidas do baralho real.
func novo_jogo() -> void:
	juice_limpar()
	aula_nav_limpar()
	aula_fechar_aviso_licao()
	aula_ultima_instrucao = ""
	aula_limpar_ajuda()
	aula_fechar_aviso_fada()
	if conquistas_abertas:
		fechar_conquistas()
	atualizar_pontos_catalogos_da_versao()
	# Recomeça no modo escolhido e invalida qualquer timer anterior.
	fechar_painel_escolha_de_objetivos()
	escolhas_iniciais_pendentes = false
	metricas_objetivos_fada.clear()
	metricas_partida_gravadas = false
	polens_gastos_no_voo_pendente = 0
	pontos_multitoque.clear()
	gesto_multitoque_ativo = false
	identificador_partida += 1
	identificador_movimento += 1
	# Uma nova partida interrompe imediatamente o setup anterior.
	animacao_setup_ativa = false
	animacao_setup_etapa = 0
	animacao_setup_tempo = 0.0
	celebracao_objetivo_ativa = false
	celebracao_objetivo_casas.clear()
	celebracao_objetivo_indice = -1
	celebracao_objetivo_jogador = -1
	polens_novos_ampliados.clear()
	polens_em_tamanho_duplo = false
	duplicacao_ativa = false
	duplicacao_indice_jogador = -1
	duplicacao_indice_historico = -1
	duplicacao_voo_ativo = false
	duplicacao_voo_cor = ""
	duplicacao_voo_tempo = 0.0
	duplicacao_polen_ultimo_indice = -1
	duplicacao_polen_ultimo_tempo = 0.0
	tabuleiro.clear()
	baralho.clear()
	jogadores.clear()
	linhas_pontuadas.clear()
	objetivos_ja_sorteados.clear()
	objetivos_fada_sorteados.clear()
	registro_voo_fada.clear()
	inimigo_deslocado_na_jogada = false
	deslocamento_inimigo_pendente = false
	sorteando_objetivos_iniciais = false
	fadas.clear()
	polens_por_casa.clear()
	ids_cartas.clear()
	polen_inicial_pendente.clear()
	proximo_id_carta = 0
	fada_em_movimento = -1
	limpar_etapa_fadas()
	zoom = 1.0
	deslocamento = Vector2.ZERO
	toque_tabuleiro = false
	toque_arrastou = false
	arrastando = false
	flor_na_mao = ""
	origem_carta_selecionada = ""
	aguardando_reposicao_automatica = false
	jogador_atual = 0
	turnos_jogados = 0
	partida_encerrada = false
	rodada_bonus_ativa = false
	rodada_bonus_etapa = 0
	rodada_bonus_autor = -1
	rodada_bonus_fila.clear()
	celula_mouse = CELULA_INVALIDA
	mouse_pos = Vector2(-9999.0, -9999.0)
	modo_movimento = false
	limpar_estado_movimento()
	pagina_historico.clear()
	for _indice_pagina in range(quantidade_jogadores()):
		pagina_historico.append(0)
	cenarios_anteriores.clear()
	indice_cenario_em_revisao = -1
	indice_estado_tutorial = -1
	revisao_final_ativa = false
	pagina_resultado = 0
	maquina_ocupada = false
	alvo_transformacao = CELULA_INVALIDA
	fada_diagonal_pendente = -1
	acao_nova = ""
	tutorial_novo_primeira_fada = -1
	tutorial_voo_fada_indice = -1
	tutorial_voo_fada_origem = Vector2i(3, 1)
	tutorial_rotacao_pronta = false
	tutorial_rotacao_configurada = false
	tutorial_final_pendente = false
	# Original/Expandida praticam na mesa normal de nove flores, com dicas breves;
	tutorial_pratica_livre = (eh_gamer() or eh_alternativa()) and modo_partida in ["aprender", "aprender_novo"]
	animacoes_coleta_aula.clear()
	tutorial_painel_posicao = Vector2(-1.0, -1.0)
	tutorial_painel_arrastando = false
	tutorial_painel_retangulo = Rect2()
	tutorial_painel_titulo = Rect2()
	fada_poder_preselecionada = -1
	tutorial_etapa = "pratica" if modo_partida == "aprender" else ""
	tutorial_passo_consulta = -1
	tutorial_passo_maximo = 1

	for cor in CORES:
		for _i in range(CARTAS_POR_COR):
			baralho.append(cor)
	for i in range(baralho.size() - 1, 0, -1):
		var j: int = sorteador.randi_range(0, i)
		var temporaria: String = baralho[i]
		baralho[i] = baralho[j]
		baralho[j] = temporaria

	# v128: Original e Expandida usam o molde 3x3 com cores permutadas
	# e orientação 0°/90° sorteada. A flor central fixa pode ser de qualquer cor.
	var flores_iniciais: Array[String] = []
	var posicoes_iniciais: Array[Vector2i] = []
	posicoes_iniciais = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	flores_iniciais = preparar_setup_fixo_nove_flores()

	# o centro é a quinta flor do setup e recebe ID e pólen como as demais.
	for i in range(posicoes_iniciais.size()):
		var casa: Vector2i = posicoes_iniciais[i]
		tabuleiro[casa] = flores_iniciais[i]
		proximo_id_carta += 1
		ids_cartas[casa] = proximo_id_carta
		polens_por_casa[casa] = 1
	flor_aberta = aula_retirar_cor(aula_cor_coletiva_a_partir_de(0)) if aula_duelo else comprar_do_baralho()

	# Objetivos nunca se repetem na partida, inclusive entre jogadores.
	var distribuidos: Array[Dictionary] = []
	if aula_duelo:
		for id_aula in ["gamer:11:lilas:vermelha", "gamer:15:vermelha:lilas"]:
			objetivos_ja_sorteados[id_aula] = true
			var reservada: Dictionary = aula_carta_objetivo(id_aula)
			if not reservada.is_empty():
				distribuidos.append(reservada)
	sorteando_objetivos_iniciais = eh_gamer() or eh_alternativa() or modo_partida not in ["aprender", "aprender_novo"]
	for n in range(quantidade_jogadores()):
		var objetivos: Array[Dictionary] = [{}, {}, {}]
		# Inicializacao explicita evita atribuir um Array generico a Array[String].
		var faixas_objetivos: Array[String] = sortear_faixas_objetivos()
		# Original e Expandida recebem 3 Médios (3–4).
		var ordem_sorteio: Array[int] = [0, 1, 2]
		for indice_slot in ordem_sorteio:
			if aula_duelo and n == 0:
				continue # A primeira mão branca é entregue abaixo.
			var carta: Dictionary = novo_objetivo_grande(distribuidos, objetivos, 46)
			objetivos[indice_slot] = carta
			if not carta.is_empty():
				distribuidos.append(carta)
		jogadores.append({
			"faixas_objetivos": faixas_objetivos,
			"nome": nome_cor_fada_plural(n),
			"cor_fada": nome_cor_fada_singular(n),
			"pontos": 0,
			"objetivos_concluidos": 0,
			"turnos_proprios": 0,
			"fadas_desbloqueadas": false,
			"fase_grandes_ativa": eh_gamer() or eh_alternativa(), # Ambas começam na fase Média.
			"fase_dificil_ativa": false,
			"polens": {"vermelha": 0, "amarela": 0, "lilas": 0},
			"objetivos": objetivos,
			"historico_objetivos": [],
			"pontos_base": 0,
			"bonus_objetivos": 0,
			"bonus_trios": 0,
			"polens_aplicados_total": 0,
			"trios_convertidos": 0,
			"polens_coletados_total": 0
		})

	sorteando_objetivos_iniciais = false
	if aula_duelo:
		var maos: Array = AULA_ALTERNATIVA_INICIAL
		aula_entregar_mao(0, maos[0])
	escolhas_iniciais_pendentes = false # Não há escolha de objetivos em nenhuma versão.

	# Partidas normais começam com as fadas na flor central.
	# A aula posiciona as duas fadas na fileira inferior, para os voos reto e diagonal.
	for dono in range(quantidade_jogadores()):
		for numero in range(2):
			fadas.append({
				"dono": dono,
				"numero": numero + 1,
				"casa": AULA_FADAS_INICIAIS[numero] if aula_duelo and dono == 0 else Vector2i.ZERO
			})

	mensagem = "Escolha a carta indicada." if aula_duelo else "Escolha uma carta ou mova uma flor da borda."
	atualizar_layout()
	if aula_duelo:
		aula_enquadrar_jardim()
	iniciar_animacao_setup() # Flores imediatas; anima apenas a chegada das fadas.
	# Aprender começa diretamente no jardim, sem leitura obrigatória.
	queue_redraw()

func comprar_do_baralho() -> String:
	# Uma cor pouco presente no jardim tem chance maior de ser sorteada.
	# A quantidade de cartas da cor no baralho NAO multiplica essa chance:
	# primeiro sorteamos a cor disponivel; depois retiramos uma carta real.
	if baralho.is_empty():
		return ""

	var quantidades_na_mesa: Dictionary = {}
	var indices_disponiveis: Dictionary = {}
	for cor in CORES:
		quantidades_na_mesa[cor] = 0
		indices_disponiveis[cor] = []

	for valor in tabuleiro.values():
		var cor: String = str(valor)
		if quantidades_na_mesa.has(cor):
			quantidades_na_mesa[cor] = int(quantidades_na_mesa[cor]) + 1

	for i in range(baralho.size()):
		var cor: String = baralho[i]
		if indices_disponiveis.has(cor):
			indices_disponiveis[cor].append(i)

	# Peso da cor = 1 / (1 + flores desta cor na mesa).
	# Cores empatadas na mesa tem probabilidades iguais, desde que
	# ainda existam cartas de ambas disponiveis no baralho.
	var pesos: Dictionary = {}
	var peso_total: float = 0.0
	for cor in CORES:
		var indices: Array = indices_disponiveis[cor]
		if indices.is_empty():
			continue
		var peso: float = 1.0 / float(1 + int(quantidades_na_mesa[cor]))
		pesos[cor] = peso
		peso_total += peso

	if peso_total <= 0.0:
		return baralho.pop_back()

	var sorteio: float = sorteador.randf() * peso_total
	for cor in CORES:
		if not pesos.has(cor):
			continue
		sorteio -= float(pesos[cor])
		if sorteio <= 0.0:
			var indices: Array = indices_disponiveis[cor]
			var indice: int = int(indices[sorteador.randi_range(0, indices.size() - 1)])
			var carta: String = baralho[indice]
			baralho.remove_at(indice)
			return carta

	# Defesa contra erro de arredondamento na soma dos pesos.
	return baralho.pop_back()

func listar_combinacoes_objetivo(celulas_interesse: Array[Vector2i], objetivo: Dictionary, estado: Dictionary) -> Array[String]:
	# Encontra todas as combinacoes que contenham alguma casa alterada.
	# Usar o estado anterior impede pontuar um formato que ja existia.
	var encontradas: Array[String] = []
	if objetivo.is_empty() or celulas_interesse.is_empty():
		return encontradas

	var tipo: int = int(objetivo["tipo"])
	var modelo: Dictionary = MODELOS_OBJETIVO[tipo]
	var base: Array[Vector2i] = posicoes_do_modelo(modelo)
	var padrao: Array = modelo["padrao"]
	var quantidade_rotacoes: int = 4 if bool(modelo.get("rotacionar", true)) else 1
	var quantidade_espelhos: int = 2 if bool(modelo.get("espelhar", false)) else 1

	for indice_espelho in range(quantidade_espelhos):
		for rotacao in range(quantidade_rotacoes):
			var posicoes: Array[Vector2i] = []
			for posicao in base:
				posicoes.append(transformar_posicao(posicao, rotacao, indice_espelho == 1))

			for casa_alterada in celulas_interesse:
				# A casa alterada pode ser qualquer uma das casas do formato.
				for indice_ancora in range(posicoes.size()):
					var origem: Vector2i = casa_alterada - posicoes[indice_ancora]
					var casas: Array[Vector2i] = []
					var correto: bool = true
					for i in range(posicoes.size()):
						var casa: Vector2i = origem + posicoes[i]
						var esperada: String = cor_da_marca(objetivo, str(padrao[i]))
						if not estado.has(casa) or str(estado[casa]) != esperada:
							correto = false
							break
						casas.append(casa)

					if correto:
						var chave: String = chave_da_combinacao(tipo, casas)
						if not encontradas.has(chave):
							encontradas.append(chave)
	return encontradas

func pode_colocar(c: Vector2i) -> bool:
	if tabuleiro.has(c):
		return false
	for d in VIZINHOS:
		if tabuleiro.has(c + d):
			return true
	return false

# ============================================================================
# FADAS - DUAS MINIATURAS POR JOGADOR
# ============================================================================
# ============================================================================
# POLEN MAGICO: SURGIMENTO, TRANSPORTE E COLETA
# ============================================================================
func registrar_nova_flor(casa: Vector2i) -> void:
	if not tabuleiro.has(casa) or not CORES.has(str(tabuleiro[casa])):
		return
	proximo_id_carta += 1
	var id_carta: int = proximo_id_carta
	ids_cartas[casa] = id_carta
	# Regra: a flor nasce com 1 polen LOGICO, mesmo que seu desenho
	# so apareca depois de 1 s. Uma fada rapida ja pode coleta-lo.
	polens_por_casa[casa] = 1
	polen_inicial_pendente[id_carta] = true
	# O temporizador revela esse polen; nunca fabrica um segundo.
	surgir_polen_apos_um_segundo(id_carta, identificador_partida)

func surgir_polen_apos_um_segundo(id_carta: int, token_partida: int) -> void:
	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree() or token_partida != identificador_partida:
		return
	# Se esta flor participa de uma celebracao, adiar SOMENTE a aparicao
	# visual do seu primeiro polen. Ele ja existe no estado do jogo;
	# os polens conquistados podem aparecer ampliados normalmente.
	while celebracao_objetivo_ativa:
		var flor_na_celebracao: bool = false
		for casa_atual in ids_cartas:
			if int(ids_cartas[casa_atual]) == id_carta:
				flor_na_celebracao = celebracao_objetivo_casas.has(casa_atual)
				break
		if not flor_na_celebracao:
			break
		await get_tree().create_timer(0.12, false).timeout
		if not is_inside_tree() or token_partida != identificador_partida:
			return
	# Uma coleta ou transformacao anterior pode ter retirado o polen.
	# Nesses casos, a animacao deve ser cancelada sem recriar nada.
	if not polen_inicial_pendente.has(id_carta):
		return
	# O ID acompanha a flor em caso de deslocamento.
	for casa in ids_cartas:
		if int(ids_cartas[casa]) != id_carta:
			continue
		polen_inicial_pendente.erase(id_carta)
		if tabuleiro.has(casa) and CORES.has(str(tabuleiro[casa])):
			juice_onda(casa, cor_polen_vivo(str(tabuleiro[casa])))
			juice_nascer(casa)
			tocar_som("polen_nascer")
			queue_redraw()
		return
	# A flor saiu do jardim: descartar somente o efeito visual.
	polen_inicial_pendente.erase(id_carta)

func adicionar_polens_a_carta(casa: Vector2i, quantidade: int = 1) -> int:
	# Toda fonte de polen (fada ou objetivo) respeita o mesmo limite.
	# O polen natural ja foi registrado ao colocar a flor.
	if quantidade <= 0 or not tabuleiro.has(casa):
		return 0
	if not CORES.has(str(tabuleiro[casa])):
		return 0
	var antes: int = clampi(int(polens_por_casa.get(casa, 0)), 0, MAX_POLENS_POR_CARTA)
	var depois: int = mini(MAX_POLENS_POR_CARTA, antes + quantidade)
	polens_por_casa[casa] = depois
	if depois > antes:
		juice_nascer(casa)
		juice_onda(casa, cor_polen_vivo(str(tabuleiro[casa])))
	# Nao cancelar a revelacao do primeiro polen: somas por objetivo
	# sao independentes dele e devem contar como polens adicionais.
	return depois - antes

func transportar_elementos_da_flor(origem: Vector2i, destino: Vector2i) -> void:
	# Preserva a quantidade de polens e o timer associado a carta movida.
	if polens_por_casa.has(origem):
		polens_por_casa[destino] = int(polens_por_casa[origem])
		polens_por_casa.erase(origem)
	if ids_cartas.has(origem):
		ids_cartas[destino] = int(ids_cartas[origem])
		ids_cartas.erase(origem)

func coletar_polens_da_casa(indice_fada: int, casa: Vector2i) -> int:
	# Retorna 0 sem evento, -1 quando poliniza e N quando coleta N polens.
	# Essa informacao permite distinguir cada acontecimento no som do voo.
	if not tabuleiro.has(casa):
		return 0
	var cor: String = str(tabuleiro[casa])
	if not CORES.has(cor):
		return 0
	var quantidade: int = int(polens_por_casa.get(casa, 0))
	# Regra unica para todas as fadas, inclusive na Familia:
	# SOMENTE uma flor sem polens pode ser polinizada pela fada.
	if quantidade <= 0:
		if adicionar_polens_a_carta(casa, 1) > 0:
			juice_serie += 1
			tocar_som("polinizar")
			mensagem = "A fada produziu 1 pólen %s na flor vazia." % nome_cor(cor)
			queue_redraw()
			return -1
		return 0
	# Ao recolher o primeiro polen antes de ele aparecer, cancelar apenas
	# sua revelacao visual. O timer jamais cria polen novo.
	if ids_cartas.has(casa):
		polen_inicial_pendente.erase(int(ids_cartas[casa]))
	var dono: int = int(fadas[indice_fada]["dono"])
	var inventario: Dictionary = jogadores[dono]["polens"]
	var antes_reserva: Dictionary = inventario.duplicate()
	var primeiro_polen: int = int(inventario.get(cor, 0))
	inventario[cor] = primeiro_polen + quantidade
	var bonus_novo: int = juice_bonus_trincas(primeiro_polen, quantidade)
	juice_registrar_ganho(dono, quantidade + bonus_novo, bonus_novo)
	juice_vibrar(12 if bonus_novo == 0 else 28)
	juice_reserva_refluxo[dono] = {"antes": antes_reserva, "inicio": juice_relogio}
	jogadores[dono]["polens_coletados_total"] = int(jogadores[dono].get("polens_coletados_total", 0)) + quantidade
	var origens: Array[Vector2] = []
	var centro_carta: Vector2 = posicao_celula(casa)
	var lado_carta: float = maxf(1.0, tamanho_carta_base_jardim() * zoom)
	for ponto in posicoes_visiveis_dos_polens_na_casa(casa, quantidade):
		origens.append((ponto - centro_carta) / lado_carta)
	polens_por_casa[casa] = 0
	juice_serie += 1
	# As unidades são creditadas já; a animação tem uma chegada por unidade.
	var fator_coleta: float = maxf(0.75, juice_fator_tempo())
	animacoes_coleta_aula.append({
		"inicio": centro_carta, "casa": casa, "origens": origens, "dono": dono,
		"cor": cor, "quantidade": quantidade, "tempo": 0.0, "primeiro_polen": primeiro_polen,
		"duracao_unidade": 0.48 * fator_coleta, "intervalo": 0.072 * fator_coleta, "chegados": 0
	})
	if quantidade >= 5:
		tocar_som("coleta_5")
	elif quantidade >= 3:
		tocar_som("coleta_4")
	elif quantidade >= 2:
		tocar_som("coleta_2")
	else:
		tocar_som("coleta_1")
	mensagem = "%s coletaram %d pólen(s) %s!" % [str(jogadores[dono]["nome"]), quantidade, nome_cor(cor)]
	queue_redraw()
	return quantidade

func cor_polen_vivo(cor: String) -> Color:
	if cor == "branca":
		return Color("f4f2ee")
	match cor:
		"vermelha": return Color("db4a5e")
		"amarela": return Color("d6a328")
		"lilas": return Color("9d63db")
	return Color.WHITE

func desenhar_polen_brilhante(p: Vector2, raio: float, cor: String) -> void:
	var chave_cache: String = cor
	if PERF_POLENS.has(chave_cache):
		var lado_cache: float = raio * (128.0 / 48.0)
		draw_texture_rect(PERF_POLENS[chave_cache], Rect2(p - Vector2.ONE * lado_cache * 0.5, Vector2.ONE * lado_cache), false)
		return
	# O polen agora se parece com uma pequena peca redonda de tabuleiro,
	# sem halos ou raios luminosos. O relevo vem apenas de sombra e brilho.
	var base: Color = cor_polen_vivo(cor)
	var sombra: Color = Color(0.0, 0.0, 0.0, 0.18)
	draw_circle(p + Vector2(raio * 0.10, raio * 0.19), raio * 1.02, sombra)
	draw_circle(p, raio, base.darkened(0.22))
	draw_circle(p + Vector2(0.0, -raio * 0.06), raio * 0.86, base)
	draw_circle(p + Vector2(-raio * 0.22, -raio * 0.28), raio * 0.46, base.lightened(0.24))
	draw_circle(p + Vector2(raio * 0.20, raio * 0.24), raio * 0.68, Color(base.r * 0.72, base.g * 0.72, base.b * 0.72, 0.45))
	draw_circle(p + Vector2(-raio * 0.31, -raio * 0.35), raio * 0.13, Color(1.0, 1.0, 1.0, 0.88))

func posicoes_visiveis_dos_polens_na_casa(casa: Vector2i, quantidade_visivel: int) -> Array[Vector2]:
	var pontos: Array[Vector2] = []
	if quantidade_visivel <= 0:
		return pontos
	var lado: float = tamanho_carta_base_jardim() * zoom
	var intervalo: float = minf(lado * 0.17, lado * 0.76 / maxf(1.0, float(quantidade_visivel - 1)))
	var centro: Vector2 = posicao_celula(casa)
	var x_inicial: float = centro.x - float(quantidade_visivel - 1) * intervalo * 0.5
	var y: float = centro.y - lado * 0.405
	for i in range(quantidade_visivel):
		pontos.append(Vector2(x_inicial + float(i) * intervalo, y))
	return pontos

func desenhar_polens_do_jardim() -> void:
	var lado: float = tamanho_carta_base_jardim() * zoom
	for casa in polens_por_casa:
		var quantidade: int = int(polens_por_casa[casa])
		if quantidade <= 0 or not tabuleiro.has(casa):
			continue
		# A primeira unidade da flor recem-plantada ja e coletavel,
		# mas so fica visivel depois de 1 s. Polens extras aparecem ja.
		var ocultos: int = 0
		if ids_cartas.has(casa) and polen_inicial_pendente.has(int(ids_cartas[casa])):
			ocultos = 1
		var quantidade_visivel: int = maxi(0, quantidade - ocultos)
		if quantidade_visivel == 0:
			continue
		var cor_flor: String = str(tabuleiro[casa])
		if not CORES.has(cor_flor):
			continue
		var centro: Vector2 = posicao_celula(casa) + juice_desvio_carta(casa)
		var r_carta: Rect2 = Rect2(centro - Vector2.ONE * lado * 0.5, Vector2.ONE * lado)
		if not area_tabuleiro.grow(-1.0).intersects(r_carta):
			continue
		var pontos: Array[Vector2] = posicoes_visiveis_dos_polens_na_casa(casa, quantidade_visivel)
		var intervalo: float = minf(lado * 0.17, lado * 0.76 / maxf(1.0, float(quantidade_visivel - 1)))
		var raio: float = minf(lado * 0.066, maxf(0.7, intervalo * 0.32))
		for i in range(ocultos, quantidade):
			var novo_ampliado: bool = (celebracao_objetivo_ativa
				and polens_em_tamanho_duplo
				and polens_novos_ampliados.has(casa)
				and i >= int(polens_novos_ampliados[casa]))
			var raio_desenho: float = raio * (2.0 if novo_ampliado else 1.0)
			var indice_visivel: int = i - ocultos
			if indice_visivel >= 0 and indice_visivel < pontos.size():
				var nascimento: float = float(juice_efeitos.get("n:%s" % str(casa), -10.0))
				var t_nascer: float = clampf((juice_relogio - nascimento) / (0.42 * juice_fator_tempo()), 0.0, 1.0)
				var escala_nascer: float = lerpf(0.35, 1.0, t_nascer) + sin(t_nascer * PI) * 0.65 if i == quantidade - 1 else 1.0
				desenhar_polen_brilhante(juice_posicao_sobre_carta(casa, pontos[indice_visivel]), raio_desenho * escala_nascer, cor_flor)
				if novo_ampliado and aula_aviso_licao_ativo() and aula_aviso_licao_tipo == "polens_objetivo":
					var pulso_aula: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.008)
					draw_arc(pontos[indice_visivel], raio_desenho + 3.5, 0.0, TAU, 24, Color(0.40, 0.80, 1.0, 0.6 + 0.4 * pulso_aula), 2.0, true)

func desenhar_efeito_coleta_aula() -> void:
	# Cada pólen se desprende do ponto em que estava; as trajetórias se sobrepõem.
	for efeito in animacoes_coleta_aula:
		var cor: String = str(efeito["cor"])
		var dono: int = int(efeito["dono"])
		if dono < 0 or dono >= jogadores.size():
			continue
		var reserva_visivel: bool = dono == jogador_atual and not (modo_partida == "maquina" and dono >= 1)
		var raio_final: float = 8.0
		var origens: Array = efeito.get("origens", [])
		var lado: float = tamanho_carta_base_jardim() * zoom
		var centro: Vector2 = posicao_celula(efeito["casa"]) if efeito.has("casa") else efeito["inicio"]
		var duracao: float = float(efeito.get("duracao_unidade", DURACAO_BRILHO_COLETA_AULA))
		var intervalo: float = float(efeito.get("intervalo", 0.0))
		var quantidade: int = int(efeito["quantidade"])
		for i in range(int(efeito.get("chegados", 0)), quantidade):
			var origem: Vector2 = centro + Vector2(origens[i]) * lado if i < origens.size() else centro
			var destino: Vector2 = posicao_polen_reserva(dono, cor)
			if not reserva_visivel:
				# A reserva rival é oculta; conservar a saída lateral da versão anterior.
				destino = Vector2(minf(area_tabuleiro.position.x - 28.0, origem.x - 48.0), origem.y - minf(26.0, area_tabuleiro.size.y * 0.065))
			var t: float = clampf((float(efeito["tempo"]) - float(i) * intervalo) / duracao, 0.0, 1.0)
			var avancar: float = interpolar_suave(t)
			var p: Vector2 = origem.lerp(destino, avancar)
			p.y -= sin(t * PI) * minf(38.0, 14.0 + origem.distance_to(destino) * 0.065)
			var espacamento: float = minf(lado * 0.17, lado * 0.76 / maxf(1.0, float(quantidade - 1)))
			var raio_inicio: float = minf(lado * 0.066, maxf(0.7, espacamento * 0.32))
			var raio: float = lerpf(raio_inicio, raio_final if reserva_visivel else 2.5, avancar)
			desenhar_polen_brilhante(p, raio, cor)

func limpar_etapa_fadas() -> void:
	parar_audio_voo()
	juice_voo.clear()
	animacoes_coleta_aula.clear()
	etapa_fada = ""
	fadas_elegiveis.clear()
	destino_da_fada = CELULA_INVALIDA
	fada_em_movimento = -1
	jogada_alteradas_pendentes.clear()
	jogada_estado_anterior_pendente.clear()
	jogada_casa_reposta_pendente = CELULA_INVALIDA

func indice_textura_por_jogador(indice_jogador: int) -> int:
	# Jogador principal branco; maquinas preta, marrom e cinza, nessa ordem.
	match indice_jogador:
		0: return 1 # Branca - jogador principal.
		1: return 0 # Preta - maquina 1 ou adversario local.
		2: return 3 # Marrom clara - maquina 2.
		3: return 2 # Cinza - maquina 3.
	return 1

func nome_cor_fada_plural(indice_jogador: int) -> String:
	match indice_jogador:
		0: return "Brancas"
		1: return "Pretas"
		2: return "Marrons"
		3: return "Cinzas"
	return "Fadas"

func nome_cor_fada_singular(indice_jogador: int) -> String:
	match indice_jogador:
		0: return "Branco"
		1: return "Preto"
		2: return "Marrom"
		3: return "Cinza"
	return "Branco"

func cor_visual_da_fada(indice_jogador: int) -> Color:
	match indice_jogador:
		0: return Color("fbfbfc") # Branca mais clara - jogador principal.
		1: return Color("303037") # Preta - primeira maquina.
		2: return Color("94613f") # Marrom clara - segunda maquina.
		3: return Color("9a9fa5") # Cinza - terceira maquina.
	return Color.WHITE

func fadas_que_podem_chegar(destino: Vector2i, dono: int) -> Array[int]:
	# Após jogar flor, voo reto ou diagonal sem custo na Original e Expandida.
	var opcoes: Array[int] = []
	if not tabuleiro.has(destino):
		return opcoes
	for i in range(fadas.size()):
		var fada: Dictionary = fadas[i]
		if int(fada["dono"]) != dono:
			continue
		var origem: Vector2i = fada["casa"]
		if trajetoria_ortogonal(origem, destino) or (permite_diagonal_ao_jogar_flor() and trajetoria_diagonal(origem, destino)):
			opcoes.append(i)
	return opcoes

func contar_polens_no_percurso_da_fada(indice_fada: int, destino: Vector2i) -> int:
	if indice_fada < 0 or indice_fada >= fadas.size():
		return 0
	var origem: Vector2i = fadas[indice_fada]["casa"]
	if not trajetoria_ortogonal(origem, destino) and not (permite_diagonal_ao_jogar_flor() and trajetoria_diagonal(origem, destino)):
		return 0
	var diferenca: Vector2i = destino - origem
	var direcao: Vector2i = Vector2i(clampi(diferenca.x, -1, 1), clampi(diferenca.y, -1, 1))
	var numero_passos: int = maxi(absi(diferenca.x), absi(diferenca.y))
	var total_polens: int = 0
	for passo in range(1, numero_passos + 1):
		var casa: Vector2i = origem + direcao * passo
		if tabuleiro.has(casa) and CORES.has(str(tabuleiro[casa])):
			total_polens += maxi(0, int(polens_por_casa.get(casa, 0)))
	return total_polens

func oferecer_movimento_fada(destino: Vector2i, alteradas: Array[Vector2i], anterior: Dictionary,
		casa_reposta: Vector2i = CELULA_INVALIDA) -> void:
	# A carta ja entrou no jardim. A escolha de mover ou nao mover a fada
	# e independente do turno de colocacao e nunca devolve a flor escolhida.
	flor_na_mao = ""

	# Preservar os dados da jogada mesmo se nenhuma fada puder voar:
	# na versao nova ainda pode haver uma transformacao floral.
	jogada_alteradas_pendentes = alteradas.duplicate()
	jogada_estado_anterior_pendente = anterior.duplicate()
	jogada_casa_reposta_pendente = casa_reposta
	fadas_elegiveis = fadas_que_podem_chegar(destino, jogador_atual)
	# As primeiras demonstrações mostram somente a fada indicada.
	# A partir da quarta jogada, toda rota legal é oferecida.
	if aula_demonstracao_ativa():
		var fada_demonstracao: int = int(aula_plano().get("fada", -1))
		if fada_demonstracao < 0:
			fadas_elegiveis.clear()
		elif fadas_elegiveis.has(fada_demonstracao):
			fadas_elegiveis.assign([fada_demonstracao])
	if fadas_elegiveis.is_empty():
		limpar_etapa_fadas()
		finalizar_jogada(alteradas, anterior, casa_reposta)
		return

	# Ativa imediatamente contornos nas fadas, na flor de destino e
	# trajetos azuis. O jogo aguarda uma decisao consciente do jogador.
	etapa_fada = "oferta"
	destino_da_fada = destino
	jogada_alteradas_pendentes = alteradas.duplicate()
	jogada_estado_anterior_pendente = anterior.duplicate()
	jogada_casa_reposta_pendente = casa_reposta
	if turno_da_maquina():
		mensagem = "%s estão escolhendo se vão voar." % nome_cor_fada_plural(jogador_atual)
		atualizar_botoes_de_movimento()
		queue_redraw()
		resolver_decisao_fada_maquina(identificador_partida, turnos_jogados)
		return

	mensagem = "Escolha uma fada azul ou toque em Cancelar Voo." if permite_diagonal_ao_jogar_flor() else "Escolha uma fada azul ou toque em Cancelar Voo."
	atualizar_botoes_de_movimento()
	queue_redraw()

func escolher_fada_para_maquina(destino: Vector2i) -> int:
	# Na vez efetiva, o tabuleiro ja inclui o plantio/deslocamento.
	# Avaliar ambos os percursos pela MESMA regra usada no planejamento.
	var melhor: int = -1
	var maior: float = -999999.0
	for indice in fadas_elegiveis:
		if int(fadas[indice]["dono"]) != jogador_atual:
			continue
		var origem: Vector2i = fadas[indice]["casa"]
		var plano: Dictionary = {"tipo":"normal","casa":destino}
		var dados: Dictionary = prever_voo_fada_maquina(origem,destino,plano,str(tabuleiro.get(destino,"")))
		var valor: float = ganho_coleta_rota_maquina(dados)
		valor += valor_objetivos_fada_maquina(tabuleiro,{},indice,origem,destino,dados)
		valor += ganho_posicao_fada_maquina(origem, destino, tabuleiro)
		# Quando a flor ja foi deslocada, 66 pode ser concluido com o voo.
		if inimigo_deslocado_na_jogada and eh_alternativa():
			for obj in jogadores[jogador_atual]["objetivos"]:
				if str(obj.get("classe","flor")) == "fada" and int(obj.get("fada_id",-1)) == 66:
					valor = maxf(valor,float(obj["pontos"])*52.0)
		if valor > maior:
			maior = valor
			melhor = indice
	return melhor

func resolver_decisao_fada_maquina(token_partida: int, numero_turno: int) -> void:
	await get_tree().create_timer(0.65, false).timeout
	if not maquina_pode_agir(token_partida,numero_turno) or etapa_fada != "oferta":
		return
	if fadas_elegiveis.is_empty():
		concluir_etapa_fadas()
		return
	var indice: int = escolher_fada_para_maquina(destino_da_fada)
	if indice < 0:
		recusar_movimento_fada()
		return
	var origem: Vector2i = fadas[indice]["casa"]
	var plano: Dictionary = {"tipo":"normal","casa":destino_da_fada}
	var resumo: Dictionary = prever_voo_fada_maquina(origem,destino_da_fada,plano,str(tabuleiro.get(destino_da_fada,"")))
	var utilidade: float = ganho_coleta_rota_maquina(resumo)
	utilidade += valor_objetivos_fada_maquina(tabuleiro,{},indice,origem,destino_da_fada,resumo)
	utilidade += ganho_posicao_fada_maquina(origem, destino_da_fada, tabuleiro)
	# Apos deslocar inimiga, preservar a oportunidade real da Manobra Combinada.
	if inimigo_deslocado_na_jogada and eh_alternativa():
		for obj in jogadores[jogador_atual]["objetivos"]:
			if str(obj.get("classe","flor")) == "fada" and int(obj.get("fada_id",-1)) == 66:
				utilidade += float(obj["pontos"])*52.0
	# Normal considera beneficios imediatos; Dificil tambem preserva boas
	# posicoes futuras. Sem recusa aleatoria de voos vantajosos.
	var deve_voar: bool = utilidade > (3.0 if dificuldade_maquina == "medio" else 0.01)
	if dificuldade_maquina == "dificil" and not deve_voar:
		var novas_rotas: int = 0
		var rotas_anteriores: int = 0
		for casa in tabuleiro:
			if not CORES.has(str(tabuleiro[casa])):
				continue
			if casa != destino_da_fada and (trajetoria_ortogonal(destino_da_fada,casa) or trajetoria_diagonal(destino_da_fada,casa)):
				novas_rotas += 1
			if casa != origem and (trajetoria_ortogonal(origem,casa) or trajetoria_diagonal(origem,casa)):
				rotas_anteriores += 1
		deve_voar = novas_rotas >= rotas_anteriores + 2
	if deve_voar:
		mover_fada_escolhida(indice)
	else:
		recusar_movimento_fada()

func mover_fada_escolhida(indice_fada: int) -> void:
	if etapa_fada != "oferta" and etapa_fada != "escolha":
		return
	if aula_demonstracao_ativa() and fadas_elegiveis.has(int(aula_plano().get("fada", -1))) and indice_fada != int(aula_plano().get("fada", -1)):
		# Todas as rotas são mostradas; o exemplo guiado mantém a decisão
		# necessária às próximas lições. Um toque diferente não muda o estado.
		queue_redraw()
		return
	if not fadas_elegiveis.has(indice_fada):
		return
	# A única forma de voar é após jogar uma flor; diagonais são gratuitas.
	iniciar_voo_fada(indice_fada)

func iniciar_voo_fada(indice_fada: int) -> void:
	juice_vibrar(14)
	juice_serie = 0
	juice_notas_voo = 0
	var origem_voo: Vector2i = fadas[indice_fada]["casa"]
	var diferenca_voo: Vector2i = destino_da_fada - origem_voo
	registro_voo_fada = {
		"dono": int(fadas[indice_fada]["dono"]),
		"fada_numero": int(fadas[indice_fada]["numero"]),
		"fada_indice": indice_fada,
		"origem": origem_voo,
		"destino": destino_da_fada,
		"adversarios_antes": casas_das_fadas_inimigas(jogador_atual),
		"minhas_antes": casas_das_fadas_do_jogador(jogador_atual),
		"coletados": 0, "produzidos": 0,
		"polens_gastos": polens_gastos_no_voo_pendente,
		"coletados_por_cor": {"vermelha": 0, "amarela": 0, "lilas": 0},
		"produzidos_por_cor": {"vermelha": 0, "amarela": 0, "lilas": 0},
		"maior_coleta_flor": 0, "flores_coletadas": 0,
		"flores_visitadas": 0, "passos": maxi(absi(diferenca_voo.x), absi(diferenca_voo.y)),
		"casas_flores": []
	}
	polens_gastos_no_voo_pendente = 0
	etapa_fada = "movendo"
	fada_em_movimento = indice_fada
	var quantidade: int = contar_polens_no_percurso_da_fada(indice_fada, destino_da_fada)
	mensagem = "Fada %d em voo; %d pólen(s) disponíveis no trajeto." % [
		int(fadas[indice_fada]["numero"]), quantidade]
	atualizar_botoes_de_movimento()
	queue_redraw()
	movimentar_fada_passo_a_passo(indice_fada, destino_da_fada, identificador_partida)

# O voo é uma única animação contínua. A lógica de coleta continua por casa,
# mas só acontece quando a miniatura realmente chega à flor.
func voo_em_andamento(indice_fada: int, token: int) -> bool:
	return is_inside_tree() and token == identificador_partida and estado_tela == "partida" and not partida_encerrada and etapa_fada == "movendo" and fada_em_movimento == indice_fada and not juice_voo.is_empty()

func voo_definir_trecho(origem: Vector2i, destino: Vector2i, duracao: float, fase: String, frear_inicio: bool = false, frear_fim: bool = false) -> void:
	juice_voo["origem"] = origem
	juice_voo["destino"] = destino
	juice_voo["inicio"] = juice_relogio
	juice_voo["duracao"] = duracao
	juice_voo["fase"] = fase
	juice_voo["frear_inicio"] = frear_inicio
	juice_voo["frear_fim"] = frear_fim
	queue_redraw()

func voo_aguardar_trecho(indice_fada: int, token: int) -> bool:
	while voo_em_andamento(indice_fada, token) and juice_progresso(juice_voo) < 1.0:
		await aguardar_frame_jogo()
	return voo_em_andamento(indice_fada, token)

func movimentar_fada_passo_a_passo(indice_fada: int, destino: Vector2i, token_partida: int) -> void:
	if indice_fada < 0 or indice_fada >= fadas.size():
		return
	var casa_atual: Vector2i = fadas[indice_fada]["casa"]
	var diferenca: Vector2i = destino - casa_atual
	var direcao: Vector2i = Vector2i(clampi(diferenca.x, -1, 1), clampi(diferenca.y, -1, 1))
	var numero_passos: int = maxi(absi(diferenca.x), absi(diferenca.y))
	if numero_passos == 0:
		concluir_etapa_fadas()
		return
	# Os offsets são relativos ao tamanho da carta: zoom e rotação de tela
	# continuam corretos, inclusive quando há várias fadas na mesma flor.
	var lado: float = maxf(1.0, tamanho_carta_base_jardim() * zoom)
	var offset_inicio: Vector2 = (centro_visual_da_fada(indice_fada) - posicao_celula(casa_atual)) / lado
	var escala_inicio: float = escala_fada_na_casa(indice_fada) / lado
	fadas[indice_fada]["casa"] = destino
	var offset_fim: Vector2 = (centro_visual_da_fada(indice_fada) - posicao_celula(destino)) / lado
	var escala_fim: float = escala_fada_na_casa(indice_fada) / lado
	fadas[indice_fada]["casa"] = casa_atual
	var fator: float = juice_fator_tempo()
	var prontidao: float = float(juice_fada_prontidao.get(indice_fada, 0.0))
	juice_voo = {"indice": indice_fada, "inicio_global": juice_relogio, "offset_inicio": offset_inicio, "offset_fim": offset_fim, "escala_inicio": escala_inicio, "escala_fim": escala_fim, "passo": 0, "total": numero_passos,
		"direcao": Vector2(direcao).normalized(), "fase_asas": fposmod(juice_relogio * TAU * 2.6 + float(indice_fada) * 1.7, TAU), "ritmo_asas": 2.6, "prontidao_inicial": prontidao}
	juice_fada_prontidao.erase(indice_fada)
	voo_definir_trecho(casa_atual, casa_atual, 0.25 * fator, "decolar")
	if not (await voo_aguardar_trecho(indice_fada, token_partida)):
		return
	# Um único trecho contínuo, independente de quantos pólens existem na rota.
	var duracao_rota: float = 0.34 * float(numero_passos) * fator * (1.32 if direcao.x != 0 and direcao.y != 0 else 1.0)
	voo_definir_trecho(casa_atual, destino, duracao_rota, "viajar", true, true)
	for passo in range(numero_passos):
		if not voo_em_andamento(indice_fada, token_partida):
			return
		var limite: float = float(passo + 1) / float(numero_passos)
		while voo_em_andamento(indice_fada, token_partida) and voo_progresso_espacial(juice_progresso(juice_voo), numero_passos) < limite:
			await aguardar_frame_jogo()
		if not voo_em_andamento(indice_fada, token_partida):
			return
		casa_atual += direcao
		fadas[indice_fada]["casa"] = casa_atual
		var cor_visitada: String = str(tabuleiro.get(casa_atual, ""))
		var evento_polen: int = coletar_polens_da_casa(indice_fada, casa_atual)
		if CORES.has(cor_visitada):
			registro_voo_fada["flores_visitadas"] = int(registro_voo_fada["flores_visitadas"]) + 1
			var casas_visitas: Array = registro_voo_fada["casas_flores"]
			casas_visitas.append(casa_atual)
			if evento_polen > 0:
				registro_voo_fada["coletados"] = int(registro_voo_fada["coletados"]) + evento_polen
				registro_voo_fada["flores_coletadas"] = int(registro_voo_fada["flores_coletadas"]) + 1
				registro_voo_fada["maior_coleta_flor"] = maxi(int(registro_voo_fada["maior_coleta_flor"]), evento_polen)
				var colhidos: Dictionary = registro_voo_fada["coletados_por_cor"]
				colhidos[cor_visitada] = int(colhidos[cor_visitada]) + evento_polen
			elif evento_polen == -1:
				registro_voo_fada["produzidos"] = int(registro_voo_fada["produzidos"]) + 1
				var gerados: Dictionary = registro_voo_fada["produzidos_por_cor"]
				gerados[cor_visitada] = int(gerados[cor_visitada]) + 1
		# A coleta não interrompe o movimento nem altera a velocidade das asas.
		queue_redraw()
	juice_voo["passo"] = numero_passos
	voo_definir_trecho(destino, destino, 0.25 * fator, "pousar")
	if not (await voo_aguardar_trecho(indice_fada, token_partida)):
		return
	juice_voo.clear()
	parar_audio_voo()
	juice_onda(destino, Color("efd08a"))
	tocar_som("pouso_fada")
	queue_redraw()
	# A fada já pousou. Deixar os últimos pólens chegarem antes de trocar
	# o painel de jogador, sem reter a fada no ar.
	while not animacoes_coleta_aula.is_empty():
		if not is_inside_tree() or token_partida != identificador_partida or estado_tela != "partida" or partida_encerrada or etapa_fada != "movendo":
			return
		await aguardar_frame_jogo()
	if token_partida == identificador_partida and estado_tela == "partida" and not partida_encerrada and etapa_fada == "movendo":
		concluir_etapa_fadas()

func recusar_movimento_fada() -> void:
	if aula_demonstracao_ativa() and not turno_da_maquina() and fadas_elegiveis.has(int(aula_plano().get("fada", -1))):
		return
	juice_cancelar_casa = destino_da_fada
	juice_cancelar_tempo = juice_relogio
	if etapa_fada != "oferta" and etapa_fada != "escolha":
		return
	# O jogador recusou o movimento, mas a flor continua colocada:
	# apenas termina esta etapa e verifica objetivos normalmente.
	tocar_som("cancelar")
	mensagem = "Voo cancelado."
	concluir_etapa_fadas()

func concluir_etapa_fadas() -> void:
	encerrar_etapa_magia()

func encerrar_etapa_magia() -> void:
	var alteradas: Array[Vector2i] = jogada_alteradas_pendentes.duplicate()
	var anterior: Dictionary = jogada_estado_anterior_pendente.duplicate()
	var casa_reposta: Vector2i = jogada_casa_reposta_pendente
	limpar_etapa_fadas()
	alvo_transformacao = CELULA_INVALIDA
	fada_diagonal_pendente = -1
	atualizar_interface_poder()
	finalizar_jogada(alteradas, anterior, casa_reposta)

func flores_transformaveis(_dono: int) -> Array[Vector2i]:
	var candidatas: Array[Vector2i] = []
	return candidatas

func selecionar_flor_para_transformacao(casa: Vector2i) -> void:
	if not (acao_nova == "pintar_alvo" or etapa_fada == "magia") or not flores_transformaveis(jogador_atual).has(casa):
		return
	alvo_transformacao = casa
	if acao_nova == "pintar_alvo":
		jogada_estado_anterior_pendente = tabuleiro.duplicate()
		acao_nova = "pintar_cor"
	else:
		etapa_fada = "cor_nova"
	mensagem = "Transformar flor %s: escolha a nova cor. Custo: 2 pólens %s." % [nome_cor(str(tabuleiro[casa])), nome_cor(str(tabuleiro[casa]))]
	atualizar_interface_poder()
	atualizar_interface_acoes_nova()
	queue_redraw()

func escolher_cor_do_poder(cor: String) -> void:
	if not versao_nova or not CORES.has(cor) or jogadores.is_empty():
		return
	var estoque: Dictionary = jogadores[jogador_atual]["polens"]
	if etapa_fada == "pagar_diagonal":
		if fada_diagonal_pendente < 0 or str(tabuleiro.get(destino_da_fada, "")) != cor:
			return
		var indice: int = fada_diagonal_pendente
		if not fadas_elegiveis.has(indice) or not trajetoria_diagonal(fadas[indice]["casa"], destino_da_fada):
			return
		if not consumir_polens_do_pouso(jogador_atual, destino_da_fada):
			return
		fada_diagonal_pendente = -1
		iniciar_voo_fada(indice)
		atualizar_interface_poder()
		return
	if etapa_fada == "cor_nova" or acao_nova == "pintar_cor":
		if alvo_transformacao == CELULA_INVALIDA or not flores_transformaveis(jogador_atual).has(alvo_transformacao):
			return
		var cor_original: String = str(tabuleiro[alvo_transformacao])
		if cor == cor_original or (tutorial_novo_ativo() and passo_tutorial_novo() == 10 and cor == "vermelha") or int(estoque.get(cor_original, 0)) < 2:
			return
		estoque[cor_original] = int(estoque[cor_original]) - 2
		# Polens da flor retornam a reserva geral, nao mudam de cor.
		polens_por_casa[alvo_transformacao] = 0
		if ids_cartas.has(alvo_transformacao):
			polen_inicial_pendente.erase(int(ids_cartas[alvo_transformacao]))
		tabuleiro[alvo_transformacao] = cor
		if not jogada_alteradas_pendentes.has(alvo_transformacao):
			jogada_alteradas_pendentes.append(alvo_transformacao)
		mensagem = "A fada transformou a flor %s em %s!" % [nome_cor(cor_original), nome_cor(cor)]
		tocar_som("pontos")
		if acao_nova == "pintar_cor":
			var alvo: Vector2i = alvo_transformacao
			var anterior: Dictionary = jogada_estado_anterior_pendente.duplicate()
			var casas_modificadas: Array[Vector2i] = [alvo]
			concluir_poder_sem_plantio(casas_modificadas, anterior)
		else:
			encerrar_etapa_magia()

func cancelar_poder_novo() -> void:
	if not versao_nova or turno_da_maquina():
		return
	if etapa_fada == "pagar_diagonal":
		fada_diagonal_pendente = -1
		etapa_fada = "oferta"
		mensagem = "Escolha outra fada ou toque em Cancelar Voo."
	elif etapa_fada == "cor_nova":
		alvo_transformacao = CELULA_INVALIDA
		etapa_fada = "magia"
		mensagem = "Escolha uma flor verde para transformar, ou pule a magia."
	elif etapa_fada == "magia":
		encerrar_etapa_magia()
		return
	atualizar_interface_poder()
	queue_redraw()

func mover_fadas_com_a_carta(origem: Vector2i, destino: Vector2i) -> void:
	# Uma miniatura sobre uma flor deslocada acompanha aquela carta.
	for fada in fadas:
		if fada["casa"] == origem:
			fada["casa"] = destino

func pode_deslocar_origem(c: Vector2i) -> bool:
	# Somente cartas da borda; a flor CENTRAL v104 fica fixa (assim como
	# ficava o gramado central nas versões anteriores).
	if c == Vector2i.ZERO:
		return false
	if not tabuleiro.has(c) or not CORES.has(str(tabuleiro[c])):
		return false
	for direcao in VIZINHOS:
		if not tabuleiro.has(c + direcao):
			return true
	return false

func destino_valido_para_movimento(origem: Vector2i, destino: Vector2i) -> bool:
	var distancia: int = absi(destino.x - origem.x) + absi(destino.y - origem.y)
	return distancia == 1 and not tabuleiro.has(destino)

func limpar_estado_movimento() -> void:
	origem_selecionada = CELULA_INVALIDA
	movimento_pendente = false
	origem_movimento = CELULA_INVALIDA
	destino_movimento = CELULA_INVALIDA
	cor_movida = ""
	tabuleiro_antes_movimento.clear()

func desfazer_deslocamento() -> void:
	juice_mover.clear()
	# Restaura a mesa e miniaturas transportadas com a flor.
	if movimento_pendente:
		tabuleiro.erase(destino_movimento)
		tabuleiro[origem_movimento] = cor_movida
		transportar_elementos_da_flor(destino_movimento, origem_movimento)
		mover_fadas_com_a_carta(destino_movimento, origem_movimento)
	deslocamento_inimigo_pendente = false
	limpar_estado_movimento()

func cancelar_movimento() -> void:
	if animacao_compra_ativa or not juice_plantar.is_empty():
		return
	if origem_selecionada != CELULA_INVALIDA:
		juice_cancelar_casa = origem_selecionada
		juice_cancelar_tempo = juice_relogio
	if celebracao_objetivo_ativa:
		return
	if turno_da_maquina():
		return
	if etapa_fada == "movendo":
		return # O trajeto em andamento nao pode ser interrompido.
	if etapa_fada in ["oferta", "escolha"]:
		recusar_movimento_fada()
		return
	if etapa_fada != "":
		return
	if partida_encerrada:
		return

	var movimento_desfeito: bool = false
	if movimento_pendente:
		# Invalida o temporizador para impedir que uma flor volte a ser
		# colocada automaticamente depois do cancelamento.
		identificador_movimento += 1
		desfazer_deslocamento()
		aguardando_reposicao_automatica = false
		movimento_desfeito = true

	if modo_movimento or origem_selecionada != CELULA_INVALIDA:
		modo_movimento = false
		origem_selecionada = CELULA_INVALIDA
		movimento_desfeito = true

	# Compra irreversível: desfazer a seleção ou deslocamento nunca devolve a flor.
	if flor_na_mao != "":
		mensagem = "Movimento desfeito. A flor permanece na mão." if movimento_desfeito else "A flor da mão deve ser plantada neste turno."
	elif movimento_desfeito:
		mensagem = "Movimento desfeito. Escolha como continuar a jogada."
	else:
		mensagem = "Não há movimento para cancelar."
	if movimento_desfeito:
		tocar_som("cancelar")
	atualizar_botoes_de_movimento()
	queue_redraw()

func executar_acao_no_tabuleiro(c: Vector2i, _posicao_clique: Vector2) -> void:
	if animacao_compra_ativa or not juice_plantar.is_empty() or not juice_repor.is_empty():
		return
	if aula_guiada_ativa() and not turno_da_maquina() and etapa_fada == "" and not partida_encerrada:
		if not animacao_setup_ativa and not celebracao_objetivo_ativa and not escolha_objetivo_ativa and not conquistas_abertas and not aguardando_reposicao_automatica:
			aula_clique_tabuleiro(c)
		return
	if turno_da_maquina() or etapa_fada == "movendo" or partida_encerrada or escolhas_iniciais_pendentes:
		return
	if (versao_nova or (eh_gamer() and acao_nova.begins_with("diagonal"))) and etapa_fada == "":
		# Ação legada de voo independente está desativada em todos os modos.
		if acao_nova == "diagonal_fada":
			var indice: int = indice_fada_clicada(_posicao_clique)
			if indice < 0 and tabuleiro.has(c):
				# Se as duas fadas estão na mesma carta, tocar nela escolhe
				# uma delas (priorizando aquela que tenha um voo possível).
				var fada_sem_rota: int = -1
				for i in range(fadas.size()):
					if int(fadas[i]["dono"]) != jogador_atual or fadas[i]["casa"] != c:
						continue
					if fada_sem_rota < 0:
						fada_sem_rota = i
					if not destinos_diagonais_da_fada(i).is_empty():
						indice = i
						break
				if indice < 0:
					indice = fada_sem_rota
			if indice >= 0:
				escolher_fada_para_voo_diagonal(indice)
			else:
				mensagem = "Escolha uma de suas fadas destacadas em azul para iniciar o voo."
				queue_redraw()
			return
		if acao_nova == "diagonal_destino":
			realizar_voo_diagonal_novo(c)
			return
		if acao_nova == "pintar_alvo":
			selecionar_flor_para_transformacao(c)
			return
		if acao_nova in ["pintar_cor", "poderes"]:
			return
		if acao_nova == "":
			if flor_na_mao != "":
				acao_nova = "plantar"
			elif pode_deslocar_origem(c) and acao_permitida_no_tutorial_novo("mover"):
				acao_nova = "mover"
			else:
				return
			atualizar_interface_acoes_nova()
		if acao_nova == "plantar":
			# Mesmo depois de comprar do baralho, tocar numa flor da borda
			# muda automaticamente para o deslocamento.
			# A carta comprada permanece na mão, pronta para repor a origem.
			if pode_deslocar_origem(c) and acao_permitida_no_tutorial_novo("mover"):
				acao_nova = "mover"
				mensagem = "Flor selecionável: escolha para onde movê-la. A carta comprada será usada na reposição."
				atualizar_interface_acoes_nova()
			else:
				if flor_na_mao != "" and pode_colocar(c):
					colocar_carta(c)
				return
		if acao_nova == "mover" and tutorial_novo_ativo() and not movimento_pendente:
			var origens_guiadas: Dictionary = {4: Vector2i(-1, 0), 5: Vector2i(0, -1), 6: Vector2i(2, 0)}
			var destinos_guiados: Dictionary = {4: Vector2i(-1, 1), 5: TUTORIAL_POSICAO_X, 6: Vector2i(2, 1)}
			var alvo: Vector2i = origens_guiadas.get(passo_tutorial_novo(), CELULA_INVALIDA)
			var destino: Vector2i = destinos_guiados.get(passo_tutorial_novo(), CELULA_INVALIDA)
			if (origem_selecionada == CELULA_INVALIDA and c != alvo) or (origem_selecionada != CELULA_INVALIDA and c != destino):
				mensagem = "Siga o destaque azul para deslocar a flor indicada."
				queue_redraw()
				return

	# Primeiras sete jogadas guiadas para as duas versões, sem bloquear
	# os cliques diretos que são válidos nas partidas normais.
	# Apos colocar a flor, a decisao sobre as fadas e feita NA MESA:
	# clique numa miniatura azul, ou no fundo marrom para nao mover.
	# O clique no destino tambem aceita quando ha uma so fada possivel.
	if etapa_fada in ["oferta", "escolha"]:
		var indice_escolhido: int = indice_fada_clicada(_posicao_clique)
		if indice_escolhido >= 0:
			mover_fada_escolhida(indice_escolhido)
		elif c == destino_da_fada and not fadas_elegiveis.is_empty():
			if aula_demonstracao_ativa():
				# Na demonstração, toque no quadrado de origem indicado.
				queue_redraw()
				return
			# Ao compartilhar a origem, as duas fadas sao equivalentes para esta escolha.
			var mesma_origem: bool = true
			var casa_referencia: Vector2i = fadas[fadas_elegiveis[0]]["casa"]
			for outra in fadas_elegiveis:
				if fadas[outra]["casa"] != casa_referencia:
					mesma_origem = false
					break
			if fadas_elegiveis.size() == 1 or mesma_origem:
				mover_fada_escolhida(fadas_elegiveis[0])
			else:
				mensagem = "As fadas estão em posições diferentes. Escolha o quadrado de uma fada azul."
				queue_redraw()
		elif not tabuleiro.has(c):
			recusar_movimento_fada()
		else:
			mensagem = "Toque na fada azul ou em Cancelar Voo."
			queue_redraw()
		return

	# No modo novo, a magia substitui a manipulacao normal do tabuleiro.
	if versao_nova and etapa_fada == "magia":
		if flores_transformaveis(jogador_atual).has(c):
			selecionar_flor_para_transformacao(c)
		elif not tabuleiro.has(c):
			encerrar_etapa_magia()
		else:
			mensagem = "Escolha uma das flores verdes ou use Pular magia."
			queue_redraw()
		return
	if versao_nova and etapa_fada in ["pagar_diagonal", "cor_nova"]:
		return

	# Nas primeiras jogadas, a aula mostra UMA acao por vez. Depois libera
	# o jardim completo para a pratica sem restricoes.

	# Enquanto a fada percorre a rota, nao sao permitidas outras jogadas.
	if etapa_fada != "":
		return

	# Enquanto se espera a carta que vai ocupar a origem, o fundo marrom
	# permite desfazer o deslocamento sem qualquer botao na interface.
	if movimento_pendente:
		if not tabuleiro.has(c):
			cancelar_movimento()
		else:
			mensagem = "Escolha CARTA COLETIVA ou BARALHO, ou clique no fundo marrom para cancelar."
			queue_redraw()
		return

	# Uma flor movivel e escolhida diretamente sobre o jardim, mesmo
	# quando o jogador ainda nao selecionou uma carta para comprar.
	if origem_selecionada == CELULA_INVALIDA:
		if pode_deslocar_origem(c):
			modo_movimento = true
			origem_selecionada = c
			mensagem = "Flor da borda selecionada. Toque ou arraste até um destino azul."
			queue_redraw()
			return
		if not tabuleiro.has(c):
			# Uma casa vazia ADJACENTE ainda pode receber uma carta normalmente;
			# so as demais partes marrons da mesa funcionam como cancelar.
			if flor_na_mao != "" and pode_colocar(c):
				colocar_carta(c)
			elif modo_movimento or (flor_na_mao != "" and origem_carta_selecionada != ""):
				cancelar_movimento()
			return
		if modo_movimento:
			mensagem = "Clique numa flor sinalizada ou no fundo marrom para cancelar."
		elif flor_na_mao != "":
			mensagem = "Escolha um espaço vazio ao lado do jardim para colocar a carta."
		else:
			mensagem = "Escolha uma carta ou uma flor sinalizada para mover."
		queue_redraw()
		return

	# A flor ja foi selecionada para deslocamento: escolha destino azul,
	# outra flor, ou clique no marrom para desistir.
	if c == origem_selecionada:
		origem_selecionada = CELULA_INVALIDA
		modo_movimento = false
		mensagem = "Seleção da flor desfeita."
	elif destino_valido_para_movimento(origem_selecionada, c):
		iniciar_deslocamento(origem_selecionada, c)
	elif pode_deslocar_origem(c):
		origem_selecionada = c
		mensagem = "Outra flor selecionada. Escolha uma casa azul vizinha."
	elif not tabuleiro.has(c):
		cancelar_movimento()
		return
	else:
		mensagem = "Escolha um destino azul ou clique no fundo marrom para cancelar."
	atualizar_botoes_de_movimento()
	queue_redraw()

func iniciar_deslocamento(origem: Vector2i, destino: Vector2i) -> void:
	if animacao_compra_ativa:
		return
	if celebracao_objetivo_ativa or partida_encerrada or movimento_pendente:
		return
	if not pode_deslocar_origem(origem) or not destino_valido_para_movimento(origem, destino):
		return

	juice_vibrar(18)
	# A carta movida pode ficar temporariamente desconectada.
	# Depois da escolha a carta nova ocupando a origem reconecta o jardim.
	tabuleiro_antes_movimento = tabuleiro.duplicate()
	cor_movida = str(tabuleiro[origem])
	deslocamento_inimigo_pendente = false
	for fada_na_flor in fadas:
		if fada_na_flor["casa"] == origem and int(fada_na_flor["dono"]) != jogador_atual:
			deslocamento_inimigo_pendente = true
	var elevacao_origem: float = juice_desvio_carta(origem).y / maxf(1.0, tamanho_carta_base_jardim() * zoom)
	juice_mover = {"origem": origem, "destino": destino, "inicio": juice_relogio, "duracao": 0.64 * juice_fator_tempo(), "elevacao_origem": elevacao_origem, "escala_origem": juice_escala_carta(origem)}
	if not feel_inicio_deslocamento.is_empty():
		juice_mover["inicio_rel"] = feel_inicio_deslocamento["rel"]
		juice_mover["angulo_arrasto"] = feel_inicio_deslocamento["angulo"]
		juice_mover["escala_origem"] = 0.98
		juice_mover["duracao"] = 0.30 * juice_fator_tempo()
		feel_inicio_deslocamento.clear()
	tabuleiro.erase(origem)
	tabuleiro[destino] = cor_movida
	transportar_elementos_da_flor(origem, destino)
	mover_fadas_com_a_carta(origem, destino)
	origem_movimento = origem
	destino_movimento = destino
	origem_selecionada = CELULA_INVALIDA
	movimento_pendente = true
	modo_movimento = true
	aguardando_reposicao_automatica = true
	identificador_movimento += 1
	var token_movimento: int = identificador_movimento
	var token_partida: int = identificador_partida
	tocar_som("papel_mover")
	if flor_na_mao == "":
		mensagem = "Casa original vazia por 1 segundo. Escolha CARTA COLETIVA ou BARALHO."
	else:
		mensagem = "Casa original vazia por 1 segundo; sua carta entrara automaticamente."
	atualizar_botoes_de_movimento()
	queue_redraw()

	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree() or token_partida != identificador_partida or token_movimento != identificador_movimento:
		return
	if not movimento_pendente or not aguardando_reposicao_automatica:
		return

	aguardando_reposicao_automatica = false
	if flor_na_mao == "":
		# A casa continua reservada ate escolher a carta.
		mensagem = "Agora escolha a CARTA COLETIVA ou o BARALHO para preencher a casa vazia."
	else:
		finalizar_deslocamento()
	atualizar_botoes_de_movimento()
	queue_redraw()

func tabuleiro_esta_conectado() -> bool:
	# Checa a conexao ortogonal de todas as cartas somente ao concluir a vez.
	if not tabuleiro.has(Vector2i.ZERO):
		return false
	var visitados: Dictionary = {}
	visitados[Vector2i.ZERO] = true
	var fila: Array[Vector2i] = [Vector2i.ZERO]
	var atual: int = 0
	while atual < fila.size():
		var casa: Vector2i = fila[atual]
		atual += 1
		for direcao in VIZINHOS:
			var vizinha: Vector2i = casa + direcao
			if tabuleiro.has(vizinha) and not visitados.has(vizinha):
				visitados[vizinha] = true
				fila.append(vizinha)
	return visitados.size() == tabuleiro.size()

func finalizar_deslocamento() -> void:
	if celebracao_objetivo_ativa or not movimento_pendente or flor_na_mao == "" or aguardando_reposicao_automatica:
		return
	tabuleiro[origem_movimento] = flor_na_mao
	if not tabuleiro_esta_conectado():
		# Salvaguarda: repoe a carta movida e conserva a carta comprada.
		tabuleiro.erase(origem_movimento)
		desfazer_deslocamento()
		modo_movimento = false
		mensagem = "Movimento desfeito: o jardim deve terminar conectado."
		atualizar_botoes_de_movimento()
		queue_redraw()
		return
	registrar_nova_flor(origem_movimento)
	var alteradas: Array[Vector2i] = [origem_movimento, destino_movimento]
	var anterior: Dictionary = tabuleiro_antes_movimento.duplicate()
	# Essa casa foi efetivamente esvaziada e recebeu uma NOVA carta.
	# Preservar a informacao mesmo depois de limpar_estado_movimento().
	var casa_reposta: Vector2i = origem_movimento
	modo_movimento = false
	aguardando_reposicao_automatica = false
	limpar_estado_movimento()
	inimigo_deslocado_na_jogada = deslocamento_inimigo_pendente
	deslocamento_inimigo_pendente = false
	juice_iniciar_plantio(casa_reposta)
	var token_encaixe: int = identificador_partida
	await get_tree().create_timer(0.30 * juice_fator_tempo(), false).timeout
	if not is_inside_tree() or token_encaixe != identificador_partida:
		return
	juice_plantar.clear()
	juice_efeitos["encaixe:%s" % str(casa_reposta)] = juice_relogio
	tocar_som("plantar_terra")
	juice_onda(casa_reposta, Color("a8d985"))
	oferecer_movimento_fada(alteradas[0], alteradas, anterior, casa_reposta)

func escolher_carta(da_aberta: bool, arrasto_direto: bool = false) -> void:
	if flor_na_mao != "" or origem_carta_selecionada != "":
		return
	if animacao_compra_ativa or (not juice_repor.is_empty() and not turno_da_maquina()):
		return
	juice_repor.clear()
	if aula_guiada_ativa() and not turno_da_maquina():
		if not aula_pode_comprar(da_aberta):
			return
	# A carta pode ser escolhida antes ou depois de mover uma flor na versao original.
	if versao_nova and not turno_da_maquina():
		if acao_nova == "":
			var chave_automatica: String = acao_automatica_compra()
			if not acao_permitida_no_tutorial_novo(chave_automatica):
				mensagem = "Nesta lição, siga o tipo de ação indicado em azul."
				queue_redraw()
				return
			acao_nova = chave_automatica
			atualizar_interface_acoes_nova()
		if acao_nova not in ["plantar", "mover"]:
			return
	if celebracao_objetivo_ativa or etapa_fada != "" or partida_encerrada or flor_na_mao != "" or escolhas_iniciais_pendentes:
		return

	if da_aberta:
		if flor_aberta == "":
			return
		flor_na_mao = flor_aberta
		flor_aberta = ""  # Compra coletiva definitiva.
		origem_carta_selecionada = "aberta"
		if arrasto_direto:
			tocar_som("papel_coletiva")
		else:
			iniciar_animacao_compra("aberta", flor_na_mao)
	else:
		var carta_comprada: String = aula_retirar_cor(str(aula_plano().get("cor", ""))) if aula_demonstracao_ativa() else comprar_do_baralho()
		if carta_comprada == "":
			mensagem = "Nao ha mais cartas no BARALHO."
			queue_redraw()
			return
		# Compra preparada para a aula de movimento das fadas.
		# No tutorial, a carta do baralho vira lilás para criar uma rota didática.
		if tutorial_guiado_ativo() and (passo_tutorial_novo() in [3, 4, 5, 6, 7] or (versao_nova and not PINTURA_GAMER_ATIVA and passo_tutorial_novo() == 8)):
			var cor_didatica: String = ""
			match passo_tutorial_novo():
				3, 5, 6: cor_didatica = "lilas"
				4: cor_didatica = "amarela"
				7: cor_didatica = "vermelha"
				8, 10:
					cor_didatica = "amarela"
			if cor_didatica != "" and carta_comprada != cor_didatica and baralho.has(cor_didatica):
				baralho.append(carta_comprada)
				baralho.erase(cor_didatica)
				carta_comprada = cor_didatica
		flor_na_mao = carta_comprada
		origem_carta_selecionada = "baralho"
		iniciar_animacao_compra("baralho", flor_na_mao)


	# Comprar uma carta NÃO desfaz uma flor já selecionada para movimento.
	# primeiro ou depois de escolher/deslocar uma flor da borda.

	if movimento_pendente:
		# Tanto a CARTA COLETIVA quanto a carta revelada do BARALHO passam
		# 1 segundo inteiro em CARTA ESCOLHIDA depois da compra, SEM
		# desfazer a flor deslocada. A origem fica vazia durante a espera.
		# Invalida o timer do deslocamento para ele nao antecipar o encaixe.
		identificador_movimento += 1
		var token_movimento: int = identificador_movimento
		var token_partida: int = identificador_partida
		aguardando_reposicao_automatica = true
		mensagem = "Carta escolhida. Em 1 segundo ela preenchera a casa vazia do jardim."
		atualizar_botoes_de_movimento()
		queue_redraw()
		await get_tree().create_timer(1.0, false).timeout
		if not is_inside_tree() or token_partida != identificador_partida or token_movimento != identificador_movimento:
			return
		if not movimento_pendente or not aguardando_reposicao_automatica:
			return
		aguardando_reposicao_automatica = false
		finalizar_deslocamento()
		atualizar_botoes_de_movimento()
		queue_redraw()
		return
	else:
		mensagem = "Carta %s selecionada. Você pode plantá-la ou mover uma flor da borda antes de repor o espaço." % nome_cor(flor_na_mao)

	atualizar_botoes_de_movimento()
	queue_redraw()

func colocar_carta(c: Vector2i) -> void:
	if animacao_compra_ativa or not juice_plantar.is_empty() or (not juice_repor.is_empty() and not turno_da_maquina()):
		return
	if celebracao_objetivo_ativa or partida_encerrada or flor_na_mao == "" or movimento_pendente or aguardando_reposicao_automatica:
		return
	if not pode_colocar(c):
		juice_erro_casa = c
		juice_erro_tempo = juice_relogio
		tocar_som("invalido")
		mensagem = "Posicao invalida: use uma casa vazia ao lado de outra carta."
		queue_redraw()
		return

	var estado_anterior: Dictionary = tabuleiro.duplicate()
	tabuleiro[c] = flor_na_mao
	registrar_nova_flor(c)
	var alteradas: Array[Vector2i] = [c]
	juice_iniciar_plantio(c)
	var token_encaixe: int = identificador_partida
	await get_tree().create_timer(0.30 * juice_fator_tempo(), false).timeout
	if not is_inside_tree() or token_encaixe != identificador_partida:
		return
	juice_plantar.clear()
	juice_efeitos["encaixe:%s" % str(c)] = juice_relogio
	tocar_som("plantar_terra")
	juice_onda(c, Color("a8d985"))
	oferecer_movimento_fada(c, alteradas, estado_anterior)


# --- ESCOLHA ESTRATÉGICA: FLORES E OBJETIVOS DA VERSÃO EXPANDIDA ---
func casas_das_fadas_do_jogador(dono: int) -> Array[Vector2i]:
	var resultado: Array[Vector2i] = []
	for fada in fadas:
		if int(fada["dono"]) == dono:
			resultado.append(fada["casa"])
	return resultado

func cartas_entre_fadas(a: Vector2i, b: Vector2i) -> int:
	var dx: int = absi(b.x - a.x)
	var dy: int = absi(b.y - a.y)
	if not (dx == 0 or dy == 0 or dx == dy) or (dx == 0 and dy == 0):
		return -1
	var passos: int = maxi(dx, dy)
	var direcao: Vector2i = Vector2i(signi(b.x - a.x), signi(b.y - a.y))
	var entre: int = 0
	for passo in range(1, passos):
		if tabuleiro.has(a + direcao * passo):
			entre += 1
	return entre

func objetivo_posicao_fadas_atendido(tipo: int, dono: int) -> bool:
	var casas: Array[Vector2i] = casas_das_fadas_do_jogador(dono)
	if casas.size() != 2:
		return false
	var a: Vector2i = casas[0]
	var b: Vector2i = casas[1]
	var cor_a: String = str(tabuleiro.get(a, ""))
	var cor_b: String = str(tabuleiro.get(b, ""))
	if not CORES.has(cor_a) or not CORES.has(cor_b):
		return false # As duas fadas devem estar sobre FLORES, não no gramado.
	var dx: int = absi(a.x - b.x)
	var dy: int = absi(a.y - b.y)
	var distancia: int = maxi(dx, dy)
	var intermediarias: int = cartas_entre_fadas(a, b)
	match tipo:
		41: return cor_a == "vermelha" and cor_b == "vermelha" and a != b
		42: return cor_a == "amarela" and cor_b == "amarela" and a != b
		43: return cor_a == "lilas" and cor_b == "lilas" and a != b
		44: return (dx == 0 or dy == 0) and intermediarias >= 2
		45: return (dx == 0 or dy == 0) and intermediarias >= 4
		46: return dx == dy and dx > 0 and intermediarias >= 2
		47: return dx == dy and dx > 0 and intermediarias >= 3
		48: return cor_a != cor_b and distancia >= 3
		49:
			var min_x: int = 2147483647
			var max_x: int = -2147483647
			var min_y: int = 2147483647
			var max_y: int = -2147483647
			for casa_tabuleiro in tabuleiro.keys():
				var casa: Vector2i = casa_tabuleiro
				if not CORES.has(str(tabuleiro[casa])):
					continue
				min_x = mini(min_x, casa.x)
				max_x = maxi(max_x, casa.x)
				min_y = mini(min_y, casa.y)
				max_y = maxi(max_y, casa.y)
			if distancia < 4:
				return false
			return (a.x == min_x and b.x == max_x and min_x < max_x) or (a.x == max_x and b.x == min_x and min_x < max_x) or (a.y == min_y and b.y == max_y and min_y < max_y) or (a.y == max_y and b.y == min_y and min_y < max_y)
	return false

func casas_das_fadas_inimigas(dono: int) -> Array[Vector2i]:
	var resultado: Array[Vector2i] = []
	for fada in fadas:
		if int(fada["dono"]) != dono:
			resultado.append(fada["casa"])
	return resultado

func segmento_continuo_de_flores(a: Vector2i, b: Vector2i) -> bool:
	var dx: int = absi(b.x - a.x)
	var dy: int = absi(b.y - a.y)
	if (dx != 0 and dy != 0 and dx != dy) or (dx == 0 and dy == 0):
		return false
	var direcao: Vector2i = Vector2i(signi(b.x-a.x), signi(b.y-a.y))
	for passo in range(maxi(dx, dy) + 1):
		if not CORES.has(str(tabuleiro.get(a + direcao * passo, ""))):
			return false
	return true

func inimigo_entre_minhas_fadas(dono: int, diagonal: bool) -> bool:
	var minhas: Array[Vector2i] = casas_das_fadas_do_jogador(dono)
	if minhas.size() != 2:
		return false
	var a: Vector2i = minhas[0]
	var b: Vector2i = minhas[1]
	var dx: int = absi(a.x - b.x)
	var dy: int = absi(a.y - b.y)
	if diagonal and not (dx == dy and dx >= 2):
		return false
	if not diagonal and not ((dx == 0 or dy == 0) and maxi(dx,dy) >= 2):
		return false
	if not segmento_continuo_de_flores(a, b):
		return false
	var direcao: Vector2i = Vector2i(signi(b.x-a.x), signi(b.y-a.y))
	for passo in range(1, maxi(dx,dy)):
		var pos: Vector2i = a + direcao * passo
		for fada in fadas:
			if int(fada["dono"]) != dono and fada["casa"] == pos:
				return true
	return false

func interposicao_entre_fadas_adversarias(dono: int, pouso: Vector2i) -> bool:
	for adversario in range(jogadores.size()):
		if adversario == dono:
			continue
		var inimigas: Array[Vector2i] = casas_das_fadas_do_jogador(adversario)
		if inimigas.size() != 2:
			continue
		var a: Vector2i = inimigas[0]
		var b: Vector2i = inimigas[1]
		if not ((a.x == b.x or a.y == b.y) or absi(a.x - b.x) == absi(a.y - b.y)) or not segmento_continuo_de_flores(a,b):
			continue
		var d: Vector2i = Vector2i(signi(b.x-a.x), signi(b.y-a.y))
		for passo in range(1, maxi(absi(b.x-a.x),absi(b.y-a.y))):
			if pouso == a + d * passo:
				return true
	return false

func esta_alinhado_com_inimigo(casa: Vector2i, inimigos: Array[Vector2i]) -> bool:
	for pos in inimigos:
		if casa.x == pos.x or casa.y == pos.y:
			return true
	return false

func objetivo_inimigo_atendido(tipo: int, dono: int, _carta: Dictionary) -> bool:
	if modo_partida not in ["duelo", "maquina"] or quantidade_jogadores() < 2:
		return false
	if tipo == 65:
		return inimigo_deslocado_na_jogada
	var houve_voo: bool = not registro_voo_fada.is_empty() and int(registro_voo_fada.get("dono", -1)) == dono and int(registro_voo_fada.get("passos", 0)) > 0
	if not houve_voo:
		return false
	var pouso: Vector2i = registro_voo_fada.get("destino", CELULA_INVALIDA)
	var origem: Vector2i = registro_voo_fada.get("origem", CELULA_INVALIDA)
	var inimigos: Array[Vector2i] = casas_das_fadas_inimigas(dono)
	var antes: Array[Vector2i] = []
	antes.assign(registro_voo_fada.get("adversarios_antes", []))
	match tipo:
		61: return inimigo_entre_minhas_fadas(dono, false) or inimigo_entre_minhas_fadas(dono, true)
		64:
			for inimigo in inimigos:
				if absi(inimigo.x-pouso.x) + absi(inimigo.y-pouso.y) == 1:
					return true
			return false
		66: return inimigo_deslocado_na_jogada
		67:
			if not esta_alinhado_com_inimigo(origem, antes):
				return false
			for minha in casas_das_fadas_do_jogador(dono):
				if esta_alinhado_com_inimigo(minha, inimigos):
					return false
			return true
		69:
			for pos in inimigos:
				if absi(pos.x-pouso.x) == absi(pos.y-pouso.y) and absi(pos.x-pouso.x) >= 3:
					return true
			return false
		70: return interposicao_entre_fadas_adversarias(dono, pouso)
	return false

func objetivo_fada_comprovado(carta: Dictionary, dono: int) -> bool:
	if carta.is_empty() or str(carta.get("classe", "flor")) != "fada":
		return false
	var tipo: int = int(carta.get("fada_id", -1))
	if tipo >= 60:
		return objetivo_inimigo_atendido(tipo, dono, carta)
	if tipo >= 41:
		# A condição so vale após voo nesta vez, não ao receber uma carta
		# já compatível com a posição das fadas.
		return (not registro_voo_fada.is_empty()
			and int(registro_voo_fada.get("dono", -1)) == dono
			and int(registro_voo_fada.get("passos", 0)) > 0
			and objetivo_posicao_fadas_atendido(tipo, dono))
	return (not registro_voo_fada.is_empty()
		and int(registro_voo_fada.get("dono", -1)) == dono
		and int(registro_voo_fada.get("passos", 0)) > 0
		and objetivo_fada_atendido(tipo, registro_voo_fada))

# O catálogo reutiliza a mesma função de desenho das cartas quadradas da partida.
# Ordenação pública: florais primeiro, pontos crescentes; objetivos com fórmula por último.
# Classes distintas usam identificadores independentes e não podem ser misturadas.
func dimensoes_grade_catalogo() -> Vector2i:
	var tela: Vector2 = get_viewport_rect().size
	var painel_h: float = v200_altura_painel_menu(tela)
	var painel_w: float = minf(540.0, tela.x - 28.0)
	var linhas: int = 3 if painel_h >= 535.0 else (2 if painel_h >= 410.0 else 1)
	var colunas: int = 3 if painel_w >= 450.0 else 2
	return Vector2i(colunas, linhas)

func itens_por_pagina_catalogo() -> int:
	var grade: Vector2i = dimensoes_grade_catalogo()
	return grade.x * grade.y

func mudar_pagina_catalogo(direcao: int) -> void:
	if estado_tela != "catalogo_objetivos":
		return
	var capacidade: int = itens_por_pagina_catalogo()
	var ultima: int = maxi(0, int(ceil(float(cartas_catalogo_visual.size()) / float(capacidade))) - 1)
	pagina_catalogo = clampi(pagina_catalogo + direcao, 0, ultima)
	sincronizar_botoes_menu()
	queue_redraw()

func desenhar_cartas_catalogo(painel: Rect2) -> void:
	var grade: Vector2i = dimensoes_grade_catalogo()
	var capacidade: int = grade.x * grade.y
	var ultima: int = maxi(0, int(ceil(float(cartas_catalogo_visual.size()) / float(capacidade))) - 1)
	pagina_catalogo = clampi(pagina_catalogo, 0, ultima)
	var topo: float = painel.position.y + (54.0 if painel.size.y < 410.0 else 64.0)
	var limite: float = botao_catalogo_anterior.position.y - 34.0
	var altura_util: float = maxf(44.0, limite - topo)
	var largura_util: float = painel.size.x - 32.0
	var espaco: float = 7.0
	var lado: float = minf((largura_util - float(grade.x - 1) * espaco) / float(grade.x),
		(altura_util - float(grade.y - 1) * espaco) / float(grade.y))
	lado = maxf(27.0, lado)
	var total_w: float = lado * float(grade.x) + float(grade.x - 1) * espaco
	var inicio_x: float = painel.get_center().x - total_w * 0.5
	for i in range(capacidade):
		var indice: int = pagina_catalogo * capacidade + i
		if indice >= cartas_catalogo_visual.size():
			break
		var carta: Dictionary = cartas_catalogo_visual[indice]
		var coluna: int = i % grade.x
		var linha: int = floori(float(i) / float(grade.x))
		var area: Rect2 = Rect2(inicio_x + float(coluna) * (lado + espaco),
			topo + float(linha) * (lado + espaco), lado, lado)
		# Reutiliza exatamente a arte das cartas exibidas na partida.
		desenhar_objetivo(carta, area, indice, false, false)
		if carta.has("formula"):
			var faixa: Rect2 = Rect2(area.position.x + 2.0, area.end.y - 19.0,
				area.size.x - 4.0, 17.0)
			draw_rect(faixa, Color("1c3444", 0.95))
			escrever_ajustado(str(carta["formula"]), faixa.position.x + 3.0,
				faixa.position.y + 12.0, faixa.size.x - 6.0, 9, Color("fff2bd"))
	var texto_pag: String = "Página %d/%d  ·  %d cartas" % [pagina_catalogo + 1, ultima + 1, cartas_catalogo_visual.size()]
	escrever_centralizado(texto_pag, painel.get_center().x,
		botao_catalogo_anterior.position.y - 8.0, 12, COR_TEXTO_FRACO)

func voltar_do_catalogo() -> void:
	if estado_tela == "catalogo_objetivos":
		estado_tela = "inicio"
	else:
		estado_tela = "inicio"
	sincronizar_botoes_menu()
	queue_redraw()


# --- ESCOLHA DE OBJETIVOS SIMULTANEOS ---
# O menu apresenta ate quatro objetivos e nao altera o tabuleiro: so define
# qual unica carta recebera os pontos daquela jogada.
func criar_painel_escolha_de_objetivos() -> void:
	painel_escolha_objetivo = ColorRect.new()
	painel_escolha_objetivo.color = Color(0.02, 0.02, 0.02, 0.70)
	painel_escolha_objetivo.mouse_filter = Control.MOUSE_FILTER_STOP
	painel_escolha_objetivo.visible = false
	add_child(painel_escolha_objetivo)
	caixa_escolha_objetivo = PanelContainer.new()
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = UI_SUPERFICIE
	estilo.border_color = Color("a98a5f")
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(12)
	estilo.shadow_color = Color(0.04, 0.025, 0.015, 0.48)
	estilo.shadow_size = 7
	estilo.shadow_offset = Vector2(0, 3)
	estilo.content_margin_left = 18.0
	estilo.content_margin_right = 18.0
	estilo.content_margin_top = 15.0
	estilo.content_margin_bottom = 15.0
	caixa_escolha_objetivo.add_theme_stylebox_override("panel", estilo)
	painel_escolha_objetivo.add_child(caixa_escolha_objetivo)
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 9)
	caixa_escolha_objetivo.add_child(coluna)
	titulo_escolha_objetivo = Label.new()
	titulo_escolha_objetivo.text = "Escolha o objetivo concluído"
	titulo_escolha_objetivo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_escolha_objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titulo_escolha_objetivo.add_theme_color_override("font_color", COR_OURO)
	titulo_escolha_objetivo.add_theme_font_override("font", fonte_destaque)
	titulo_escolha_objetivo.add_theme_font_size_override("font_size", 23)
	coluna.add_child(titulo_escolha_objetivo)
	var explicacao: Label = Label.new()
	explicacao.text = "Escolha apenas uma carta para render estrelas nesta jogada."
	explicacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explicacao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explicacao.add_theme_color_override("font_color", COR_TEXTO)
	explicacao.add_theme_font_size_override("font_size", 19)
	coluna.add_child(explicacao)
	for indice in range(4):
		var botao: Button = criar_botao_menu("Objetivo", Callable(self, "escolher_objetivo_concluido").bind(indice))
		botao.visible = false
		botao.custom_minimum_size = Vector2(250.0, 43.0)
		botao.add_theme_font_size_override("font_size", 14)
		# criar_botao_menu coloca no Node2D; transferir para o contêiner.
		remove_child(botao)
		coluna.add_child(botao)
		botoes_escolha_objetivo.append(botao)
	atualizar_posicao_escolha_de_objetivos()

func atualizar_posicao_escolha_de_objetivos() -> void:
	if not is_instance_valid(painel_escolha_objetivo):
		return
	var tela: Vector2 = get_viewport_rect().size
	painel_escolha_objetivo.position = Vector2.ZERO
	painel_escolha_objetivo.size = tela
	var largura: float = minf(540.0, ui_area_segura().size.x - 24.0)
	var altura: float = minf(530.0, ui_area_segura().size.y - 24.0)
	caixa_escolha_objetivo.position = (tela - Vector2(largura, altura)) * 0.5
	caixa_escolha_objetivo.size = Vector2(largura, altura)
	for botao in botoes_escolha_objetivo:
		botao.custom_minimum_size = Vector2(
			maxf(120.0, largura - 40.0), 48.0 if tela.y < 490.0 else 74.0)
		botao.add_theme_font_size_override("font_size", 16 if tela.x < 380.0 else 19)
		botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func fechar_painel_escolha_de_objetivos() -> void:
	escolha_objetivo_ativa = false
	escolha_objetivo_opcoes.clear()
	escolha_objetivo_jogador = -1
	if is_instance_valid(painel_escolha_objetivo):
		painel_escolha_objetivo.visible = false

func opcoes_florais_concluidas_na_jogada(indice_jogador: int,
		celulas_alteradas: Array[Vector2i], estado_anterior: Dictionary,
		estado_depois: Dictionary, _casa_reposta: Vector2i) -> Array[Dictionary]:
	var candidatos: Array[Dictionary] = []
	if indice_jogador < 0 or indice_jogador >= jogadores.size() or celulas_alteradas.is_empty():
		return candidatos
	var objetivos: Array[Dictionary] = jogadores[indice_jogador]["objetivos"]
	for indice in range(objetivos.size()):
		var objetivo: Dictionary = objetivos[indice]
		if objetivo.is_empty() or str(objetivo.get("classe", "flor")) == "fada":
			continue
		var id_objetivo: String = str(objetivo["id"])
		if linhas_pontuadas.has(id_objetivo):
			continue
		var antes: Array[String] = listar_combinacoes_objetivo(celulas_alteradas, objetivo, estado_anterior)
		var depois: Array[String] = listar_combinacoes_objetivo(celulas_alteradas, objetivo, estado_depois)
		for chave in depois:
			# A combinacao deve ter surgido nesta jogada; trocar carta pela
			# MESMA cor nao permite reivindicar algo que ja estava pronto.
			if antes.has(chave):
				continue
			candidatos.append({"indice": indice, "id": id_objetivo, "chave": chave,
				"pontos": int(objetivo["pontos"]), "classe": "flor"})
			break
	return candidatos

func opcoes_fada_concluidas_na_jogada(indice_jogador: int) -> Array[Dictionary]:
	var candidatos: Array[Dictionary] = []
	if not eh_alternativa() or indice_jogador < 0 or indice_jogador >= jogadores.size():
		return candidatos
	if not registro_voo_fada.is_empty() and int(registro_voo_fada.get("dono", -1)) != indice_jogador:
		return candidatos
	var objetivos: Array[Dictionary] = jogadores[indice_jogador]["objetivos"]
	for indice in range(objetivos.size()):
		var objetivo: Dictionary = objetivos[indice]
		if objetivo.is_empty() or str(objetivo.get("classe", "flor")) != "fada":
			continue
		var id_objetivo: String = str(objetivo.get("id", ""))
		var tipo_fada: int = int(objetivo["fada_id"])
		if linhas_pontuadas.has(id_objetivo) or not objetivo_fada_comprovado(objetivo, indice_jogador):
			continue
		var chave: String = "fada"
		for casa in (casas_das_fadas_do_jogador(indice_jogador) if tipo_fada >= 41 else registro_voo_fada.get("casas_flores", [])):
			chave += "|%d,%d" % [int(casa.x), int(casa.y)]
		candidatos.append({"indice": indice, "id": id_objetivo, "chave": chave,
			"pontos": int(objetivo["pontos"]), "classe": "fada"})
	return candidatos

func abrir_escolha_de_objetivos(opcoes: Array[Dictionary]) -> void:
	escolha_objetivo_opcoes = opcoes.duplicate(true)
	escolha_objetivo_jogador = jogador_atual
	escolha_objetivo_ativa = true
	var objetivos: Array[Dictionary] = jogadores[jogador_atual]["objetivos"]
	for indice in range(botoes_escolha_objetivo.size()):
		var botao: Button = botoes_escolha_objetivo[indice]
		botao.visible = indice < escolha_objetivo_opcoes.size()
		if not botao.visible:
			continue
		var opcao: Dictionary = escolha_objetivo_opcoes[indice]
		var carta: Dictionary = objetivos[int(opcao["indice"])]
		var rotulo: String = ""
		if str(opcao.get("classe", "flor")) == "fada":
			rotulo = ("Fada · " + str(carta.get("descricao", ""))) if eh_alternativa() else "Fada · %s" % str(carta.get("titulo", "Objetivo"))
		else:
			rotulo = "Floral · %s + %s" % [nome_cor(str(carta.get("cor_a", ""))), nome_cor(str(carta.get("cor_b", "")))]
		botao.text = "%s  ·  %s" % [rotulo, rotulo_estrela_compacto(int(opcao["pontos"]))]
		for estado_cor in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			botao.add_theme_color_override(estado_cor, COR_PRATA)
		if str(opcao.get("classe", "flor")) == "fada":
			registrar_objetivo_fada_em_disputa(carta)
	atualizar_posicao_escolha_de_objetivos()
	painel_escolha_objetivo.visible = true
	mensagem = "Mais de um objetivo concluído. Escolha qual carta renderá as estrelas desta jogada."
	queue_redraw()

func escolher_objetivo_concluido(indice: int) -> void:
	if not escolha_objetivo_ativa or indice < 0 or indice >= escolha_objetivo_opcoes.size():
		return
	if escolha_objetivo_jogador != jogador_atual:
		fechar_painel_escolha_de_objetivos()
		return
	var opcao: Dictionary = escolha_objetivo_opcoes[indice].duplicate(true)
	var carta: Dictionary = jogadores[jogador_atual]["objetivos"][int(opcao["indice"])]
	if str(opcao.get("classe", "flor")) == "fada":
		registrar_objetivo_fada_escolhido(carta)
	fechar_painel_escolha_de_objetivos()
	celebrar_objetivo_concluido(opcao, jogador_atual, identificador_partida)

func finalizar_jogada(celulas_alteradas: Array[Vector2i], estado_anterior: Dictionary,
		casa_reposta: Vector2i = CELULA_INVALIDA) -> void:
	# A flor ja entrou fisicamente no jardim. Se o movimento criou um objetivo,
	# a vez espera a celebracao visual acabar; a pontuacao vem em seguida.
	if celebracao_objetivo_ativa:
		return
	# Todas as modalidades permitem concluir objetivos na primeira jogada.
	var melhor: Dictionary = melhor_objetivo_da_jogada(
		jogador_atual, celulas_alteradas, estado_anterior, tabuleiro, casa_reposta)
	var melhor_fada: Dictionary = melhor_objetivo_de_fada_da_jogada(jogador_atual)
	if not melhor_fada.is_empty() and (melhor.is_empty() or int(melhor_fada["pontos"]) > int(melhor["pontos"])):
		melhor = melhor_fada
	# Grande coleta é exclusivamente uma aula de pólens: não conclui
	# objetivo mesmo que uma combinação incidental apareça no tabuleiro.
	if not melhor.is_empty():
		var humano: bool = modo_partida != "maquina" or jogador_atual == 0
		if humano and not tutorial_guiado_ativo():
			var opcoes: Array[Dictionary] = opcoes_florais_concluidas_na_jogada(
				jogador_atual, celulas_alteradas, estado_anterior, tabuleiro, casa_reposta)
			opcoes.append_array(opcoes_fada_concluidas_na_jogada(jogador_atual))
			if opcoes.size() > 1:
				abrir_escolha_de_objetivos(opcoes)
				return
		celebrar_objetivo_concluido(melhor, jogador_atual, identificador_partida)
		return
	# v217: pontuação dos pólens explicada durante o voo e no placar.
	finalizar_jogada_apos_celebracao(0)


func finalizar_jogada_apos_celebracao(ganhos: int) -> void:
	# Ultima fase obrigatoria da jogada, SEM alterar a vez antes da conversao.
	# Uma carta concluida entra no historico antes deste momento.
	if duplicacao_ativa:
		return
	# A distribuição de pólens da Original é feita exclusivamente no encerramento.
	concluir_turno_apos_duplicacao(ganhos)

func concluir_turno_apos_duplicacao(ganhos: int) -> void:
	# Esta rotina é executada APÓS a conquista, reposição e eventual duplicação.
	# Um objetivo concluido concede uma rodada bonus de uma jogada por
	# participante em todos os duelos. A ordem e sempre alternada:
	# adversario primeiro, autor da conquista depois. Objetivos obtidos
	# durante esses dois turnos nao disparam novo bonus.
	var nome: String = str(jogadores[jogador_atual]["nome"])
	var autor_jogada: int = jogador_atual
	var repor_aberta: bool = origem_carta_selecionada == "aberta"
	flor_na_mao = ""
	origem_carta_selecionada = ""
	aguardando_reposicao_automatica = false
	registro_voo_fada.clear()
	inimigo_deslocado_na_jogada = false
	deslocamento_inimigo_pendente = false
	if repor_aberta:
		flor_aberta = aula_retirar_cor(aula_cor_coletiva_a_partir_de(aula_passo_humano() + 1)) if aula_demonstracao_ativa() else comprar_do_baralho()
		if flor_aberta != "":
			juice_repor = {"inicio": juice_relogio, "duracao": 0.48 * juice_fator_tempo(), "cor": flor_aberta, "som_virada": false}
			tocar_som("papel_saque")
	modo_movimento = false
	limpar_estado_movimento()
	acao_nova = ""
	fada_poder_preselecionada = -1
	turnos_jogados += 1
	aula_limpar_ajuda()
	jogadores[autor_jogada]["turnos_proprios"] = int(jogadores[autor_jogada].get("turnos_proprios", 0)) + 1

	polens_gastos_no_voo_pendente = 0
	maquina_ocupada = false
	if aula_duelo_ativa() and autor_jogada == 0 and aula_passo_humano() == AULA_TURNOS_GUIADOS:
		aula_liberar_mao_normal()

	var duelo_real: bool = modo_partida in ["duelo", "maquina"]
	var mensagem_bonus: String = ""
	if duelo_real:
		if ganhos > 0 and not rodada_bonus_ativa:
			rodada_bonus_ativa = true
			rodada_bonus_autor = autor_jogada
			rodada_bonus_fila.clear()
			for deslocamento_bonus in range(1, quantidade_jogadores()):
				rodada_bonus_fila.append((autor_jogada + deslocamento_bonus) % quantidade_jogadores())
			rodada_bonus_fila.append(autor_jogada)
			rodada_bonus_etapa = 0
		if rodada_bonus_ativa:
			if not rodada_bonus_fila.is_empty():
				jogador_atual = rodada_bonus_fila.pop_front()
				rodada_bonus_etapa += 1
				var total_bonus: int = quantidade_jogadores()
				if rodada_bonus_etapa == 1:
					mensagem_bonus = "%s concluíram um objetivo! Rodada bônus: vez das %s (%d/%d)." % [nome, str(jogadores[jogador_atual]["nome"]), rodada_bonus_etapa, total_bonus]
				else:
					mensagem_bonus = "Rodada bônus: vez das %s (%d/%d)." % [str(jogadores[jogador_atual]["nome"]), rodada_bonus_etapa, total_bonus]
			else:
				rodada_bonus_ativa = false
				rodada_bonus_etapa = 0
				jogador_atual = (rodada_bonus_autor + 1) % quantidade_jogadores()
				rodada_bonus_autor = -1
				mensagem_bonus = "Rodada bônus concluída. Vez das %s." % str(jogadores[jogador_atual]["nome"])
		else:
			jogador_atual = (autor_jogada + 1) % quantidade_jogadores()

	# Alcançar seis objetivos encerra o duelo apenas após a rodada bônus.
	# Objetivos são o gatilho de encerramento, NÃO o critério de vitória:
	# vence quem tiver mais pontos após os bônus finais de pólens.
	var meta_atingida_no_duelo: bool = false
	if duelo_real:
		for participante in jogadores:
			if int(participante["objetivos_concluidos"]) >= DUELO_META_OBJETIVOS:
				meta_atingida_no_duelo = true
				break
	var duelo_vencido: bool = duelo_real and meta_atingida_no_duelo and not rodada_bonus_ativa
	# No Aprender individual, seis objetivos encerram sem rodada bônus.
	var treino_vencido: bool = not duelo_real and (aula_duelo or modo_partida in ["aprender", "aprender_novo"]) and int(jogadores[autor_jogada]["objetivos_concluidos"]) >= DUELO_META_OBJETIVOS
	var aula_concluida: bool = not tutorial_pratica_livre and ((modo_partida == "aprender" and turnos_jogados >= APRENDER_MAX_JOGADAS) or (modo_partida == "aprender_novo" and turnos_jogados >= (TUTORIAL_GAMER_ETAPAS if versao_gamer_progressiva else TUTORIAL_NOVO_JOGADAS)))
	var cartas_esgotadas: bool = baralho.is_empty() and flor_aberta == ""
	if duelo_vencido or treino_vencido or cartas_esgotadas:
		encerrar_partida(ganhos == 0, true)
		if ganhos > 0:
			tocar_final_depois_da_conquista(identificador_partida)
	elif aula_concluida:
		# As orientacoes terminam, mas a mesma partida continua sem pausa nem escolha.
		tutorial_final_pendente = true
		continuar_apos_tutorial()
	else:
		if duelo_real:
			mensagem = mensagem_bonus if mensagem_bonus != "" else ("%s jogaram. Vez das %s." % [nome, jogadores[jogador_atual]["nome"]])
		else:
			jogador_atual = (autor_jogada + 1) % quantidade_jogadores()
			mensagem = ("%s ganharam %s!" % [nome, rotulo_estrela_compacto(ganhos)] if ganhos > 0 else "%s jogaram." % nome)
	preparar_poder_do_tutorial_novo()
	if aula_duelo_ativa():
		aula_nav_indice = -1
		aula_nav_animando = false
		aula_nav_cancelar_gesto()
		aula_preparar_rotacao()
		atualizar_layout()
		aula_enquadrar_jardim()
	atualizar_botoes_de_movimento()
	sincronizar_botoes_menu()
	queue_redraw()
	if not partida_encerrada:
		iniciar_turno_maquina()

# Retorna APENAS o objetivo de MAIOR valor que a jogada realmente concluiu.
# A identificacao de um objetivo concluido usa o ID da CARTA, nao so
# o formato/posicao: padroes diferentes podem ocupar a mesma regiao.
# Substituicoes que NAO alteram a combinacao de cores nao pontuam:
# a conquista exige uma formacao nova no estado final.
# Objetivos ja concluidos na partida nunca voltam a pontuar.
func melhor_objetivo_da_jogada(indice_jogador: int, celulas_alteradas: Array[Vector2i],
		estado_anterior: Dictionary, estado_depois: Dictionary,
		_casa_reposta: Vector2i = CELULA_INVALIDA) -> Dictionary:
	var melhor: Dictionary = {}
	if indice_jogador < 0 or indice_jogador >= jogadores.size() or celulas_alteradas.is_empty():
		return melhor
	var objetivos: Array[Dictionary] = jogadores[indice_jogador]["objetivos"]
	for indice in range(objetivos.size()):
		var objetivo: Dictionary = objetivos[indice]
		if objetivo.is_empty() or str(objetivo.get("classe", "flor")) == "fada":
			continue
		# Cada ID de carta de objetivo so pode ser concluido uma vez,
		# independentemente das coordenadas e de futuras substituicoes.
		var id_objetivo: String = str(objetivo["id"])
		if linhas_pontuadas.has(id_objetivo):
			continue
		var antes: Array[String] = listar_combinacoes_objetivo(
			celulas_alteradas, objetivo, estado_anterior)
		var depois: Array[String] = listar_combinacoes_objetivo(
			celulas_alteradas, objetivo, estado_depois)
		for chave in depois:
			# A combinacao precisa ser NOVA neste estado do jardim.
			# Mesmo uma reposicao fisica nao pontua se conservar as mesmas cores.
			if antes.has(chave):
				continue
			var pontos: int = int(objetivo["pontos"])
			# Maior pontuacao prevalece. No empate, permanece o primeiro
			# objetivo visivel (indice menor) para nao haver sorteio extra.
			if melhor.is_empty() or pontos > int(melhor["pontos"]):
				melhor = {"indice": indice, "id": id_objetivo, "chave": chave, "pontos": pontos}
			break
	return melhor

# --- ESTATISTICAS LOCAIS DOS OBJETIVOS DE FADA ---
# Ferramenta de balanceamento: nao exibe dados nem altera as regras do jogo.
func registrar_metricas_fada_habilitadas() -> bool:
	return not aula_duelo and modo_partida not in ["aprender", "aprender_novo"]

func linha_de_metricas_fada(numero: int) -> Dictionary:
	var chave: String = str(numero)
	if not metricas_objetivos_fada.has(chave):
		metricas_objetivos_fada[chave] = {
			"distribuidos": 0, "concluidos": 0, "nao_concluidos": 0,
			"turnos_ate_conclusao": 0, "polens_coletados": 0,
			"polens_gastos": 0, "polens_liquidos": 0,
			"disputas": 0, "escolhidos_em_disputa": 0
		}
	return metricas_objetivos_fada[chave]

func registrar_objetivo_fada_entregue(objetivo: Dictionary, indice_jogador: int) -> void:
	if not registrar_metricas_fada_habilitadas() or objetivo.is_empty():
		return
	if str(objetivo.get("classe", "flor")) != "fada":
		return
	var linha: Dictionary = linha_de_metricas_fada(int(objetivo.get("fada_id", -1)))
	linha["distribuidos"] = int(linha["distribuidos"]) + 1
	objetivo["turno_recebido"] = int(jogadores[indice_jogador].get("turnos_proprios", 0))

func registrar_objetivo_fada_concluido(objetivo: Dictionary, indice_jogador: int) -> void:
	if not registrar_metricas_fada_habilitadas() or str(objetivo.get("classe", "flor")) != "fada":
		return
	var linha: Dictionary = linha_de_metricas_fada(int(objetivo["fada_id"]))
	linha["concluidos"] = int(linha["concluidos"]) + 1
	var idade: int = maxi(1, int(jogadores[indice_jogador].get("turnos_proprios", 0)) - int(objetivo.get("turno_recebido", 0)) + 1)
	linha["turnos_ate_conclusao"] = int(linha["turnos_ate_conclusao"]) + idade
	var coletados: int = int(registro_voo_fada.get("coletados", 0))
	var gastos: int = int(registro_voo_fada.get("polens_gastos", 0))
	linha["polens_coletados"] = int(linha["polens_coletados"]) + coletados
	linha["polens_gastos"] = int(linha["polens_gastos"]) + gastos
	linha["polens_liquidos"] = int(linha["polens_liquidos"]) + coletados - gastos

func registrar_objetivo_fada_em_disputa(objetivo: Dictionary) -> void:
	if not registrar_metricas_fada_habilitadas() or str(objetivo.get("classe", "flor")) != "fada":
		return
	var linha: Dictionary = linha_de_metricas_fada(int(objetivo["fada_id"]))
	linha["disputas"] = int(linha["disputas"]) + 1

func registrar_objetivo_fada_escolhido(objetivo: Dictionary) -> void:
	if not registrar_metricas_fada_habilitadas() or str(objetivo.get("classe", "flor")) != "fada":
		return
	var linha: Dictionary = linha_de_metricas_fada(int(objetivo["fada_id"]))
	linha["escolhidos_em_disputa"] = int(linha["escolhidos_em_disputa"]) + 1

func registrar_objetivos_fada_nao_concluidos() -> void:
	if not registrar_metricas_fada_habilitadas():
		return
	for jogador in jogadores:
		var objetivos: Array[Dictionary] = jogador["objetivos"]
		for objetivo in objetivos:
			if objetivo.is_empty() or str(objetivo.get("classe", "flor")) != "fada":
				continue
			var linha: Dictionary = linha_de_metricas_fada(int(objetivo["fada_id"]))
			linha["nao_concluidos"] = int(linha["nao_concluidos"]) + 1

func gravar_metricas_objetivos_fada() -> void:
	if metricas_partida_gravadas or not registrar_metricas_fada_habilitadas():
		return
	metricas_partida_gravadas = true
	registrar_objetivos_fada_nao_concluidos()
	var caminho: String = "user://jardim_fadas_balanceamento_fadas.csv"
	var existe: bool = FileAccess.file_exists(caminho)
	var arquivo: FileAccess = FileAccess.open(caminho, FileAccess.READ_WRITE if existe else FileAccess.WRITE)
	if arquivo == null:
		push_warning("Nao foi possivel gravar estatisticas de balanceamento: %s" % FileAccess.get_open_error())
		return
	if existe:
		arquivo.seek_end()
	else:
		arquivo.store_csv_line(PackedStringArray([
			"partida", "versao", "modo", "jogadores", "tipo_fada", "nome",
			"distribuidos", "concluidos", "nao_concluidos", "turnos_ate_conclusao",
			"polens_coletados", "polens_gastos", "polens_liquidos",
			"disputas", "escolhidos_em_disputa"]), ";")
	var identificador: String = str(int(Time.get_unix_time_from_system()))
	for chave in metricas_objetivos_fada.keys():
		var numero: int = int(chave)
		var linha: Dictionary = metricas_objetivos_fada[chave]
		var modelo: Dictionary = OBJETIVOS_FADA_MODELOS.get(numero, {})
		arquivo.store_csv_line(PackedStringArray([
			identificador, nome_versao_atual(), modo_partida, str(jogadores.size()), str(numero),
			str(modelo.get("titulo", "")), str(linha["distribuidos"]), str(linha["concluidos"]),
			str(linha["nao_concluidos"]), str(linha["turnos_ate_conclusao"]),
			str(linha["polens_coletados"]), str(linha["polens_gastos"]),
			str(linha["polens_liquidos"]), str(linha["disputas"]),
			str(linha["escolhidos_em_disputa"])]), ";")
	arquivo.close()
	print("[Jardim] Estatisticas de objetivos de fada: ", ProjectSettings.globalize_path(caminho))

func gravar_resumo_pontuacao_balanceamento() -> void:
	# O bonus final nao pode ser atribuido diretamente a um unico objetivo de
	# Fada. Por isso registramos separadamente o resultado agregado de cada
	# jogador, para cruzar depois com as estatisticas por tipo de carta.
	if not registrar_metricas_fada_habilitadas():
		return
	var caminho: String = "user://jardim_fadas_resultados_balanceamento.csv"
	var existe: bool = FileAccess.file_exists(caminho)
	var arquivo: FileAccess = FileAccess.open(caminho, FileAccess.READ_WRITE if existe else FileAccess.WRITE)
	if arquivo == null:
		push_warning("Nao foi possivel gravar resumo de balanceamento: %s" % FileAccess.get_open_error())
		return
	if existe:
		arquivo.seek_end()
	else:
		arquivo.store_csv_line(PackedStringArray([
			"partida", "versao", "modo", "jogador", "objetivos_fada_concluidos",
			"objetivos_totais_concluidos", "polens_coletados_total",
			"bonus_duplicacoes", "bonus_pares", "pontuacao_final"]), ";")
	var identificador: String = str(int(Time.get_unix_time_from_system()))
	for i in range(jogadores.size()):
		var jogador: Dictionary = jogadores[i]
		var fadas_concluidas: int = 0
		for carta in jogador.get("historico_objetivos", []):
			if str(carta.get("classe", "flor")) == "fada":
				fadas_concluidas += 1
		arquivo.store_csv_line(PackedStringArray([
			identificador, nome_versao_atual(), modo_partida, str(jogador.get("nome", "Jogador %d" % (i + 1))),
			str(fadas_concluidas), str(jogador.get("objetivos_concluidos", 0)),
			str(jogador.get("polens_coletados_total", 0)), str(jogador.get("bonus_objetivos", 0)),
			str(jogador.get("bonus_trios", 0)), str(jogador.get("pontos", 0))]), ";")
	arquivo.close()

# Retira as coordenadas da combinacao REAL reconhecida, inclusive girada.
# Todas elas recebem borda amarela durante a conquista.
func casas_do_objetivo_concluido(chave: String) -> Array[Vector2i]:
	var casas: Array[Vector2i] = []
	var partes: PackedStringArray = chave.split("|")
	for i in range(1, partes.size()):
		var xy: PackedStringArray = partes[i].split(",")
		if xy.size() != 2:
			continue
		casas.append(Vector2i(int(xy[0]), int(xy[1])))
	# A chave usa uma ordem estavel; assim os polens surgem 1 por 1
	# com uma progressao visual previsivel, da esquerda para a direita.
	casas.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y if a.x == b.x else a.x < b.x)
	return casas


# Politica unica de polinizacao: Pequenos e Grandes concedem 1 polen por flor,
# inclusive na Expandida. O limite fisico fica em MAX_POLENS_POR_CARTA.
func polens_gerados_por_flor_ao_concluir_objetivo(_objetivo: Dictionary) -> int:
	return 1

func celebrar_objetivo_concluido(resultado: Dictionary, indice_jogador: int, token_partida: int) -> void:
	# A celebracao inteira dura 2 segundos, com os retangulos amarelos.
	# Todos os polens do objetivo entram SIMULTANEAMENTE no instante inicial.
	# Apenas esses novos polens ficam com 2x o raio por 1 segundo; depois
	# voltam ao tamanho padrao enquanto o objetivo segue destacado por 1 s.
	var indice: int = int(resultado["indice"])
	var id_objetivo: String = str(resultado["id"])
	# Antes de qualquer efeito ou polen, verificar que a carta pertence
	# ao jogador da vez. Formatos exclusivos do adversario nao pontuam.
	if indice_jogador != jogador_atual or indice_jogador < 0 or indice_jogador >= jogadores.size():
		finalizar_jogada_apos_celebracao(0)
		return
	var objetivos_do_dono: Array[Dictionary] = jogadores[indice_jogador]["objetivos"]
	if indice < 0 or indice >= objetivos_do_dono.size() or objetivos_do_dono[indice].is_empty():
		finalizar_jogada_apos_celebracao(0)
		return
	if str(objetivos_do_dono[indice].get("id", "")) != id_objetivo or linhas_pontuadas.has(id_objetivo):
		finalizar_jogada_apos_celebracao(0)
		return
	var pontos: int = int(resultado["pontos"])
	var casas: Array[Vector2i] = casas_do_objetivo_concluido(str(resultado["chave"]))
	if casas.is_empty():
		finalizar_jogada_apos_celebracao(0)
		return
	celebracao_objetivo_ativa = true
	mobile_constelacao_floral = str(resultado.get("classe", "flor")) != "fada"
	juice_efeitos["celebrar"] = juice_relogio
	celebracao_objetivo_casas = casas.duplicate()
	celebracao_objetivo_indice = indice
	celebracao_objetivo_jogador = indice_jogador
	polens_novos_ampliados.clear()
	polens_em_tamanho_duplo = true

	# Objetivos FLORAIS produzem 1 polen por flor em TODAS as versoes.
	# Os de FADA concedem pontos pela acao do voo e nao geram polen floral.
	if str(resultado.get("classe", "flor")) != "fada":
		var polens_por_flor: int = polens_gerados_por_flor_ao_concluir_objetivo(objetivos_do_dono[indice])
		for casa in casas:
			if not tabuleiro.has(casa) or not CORES.has(str(tabuleiro[casa])):
				continue
			var recebidos: int = adicionar_polens_a_carta(casa, polens_por_flor)
			if recebidos > 0:
				# Primeira unidade recém-criada, para que ambas possam pulsar.
				polens_novos_ampliados[casa] = int(polens_por_casa[casa]) - recebidos

	mensagem = "Objetivo de fada concluído!" if str(resultado.get("classe", "flor")) == "fada" else "Objetivo concluído! Os novos pólens aparecem juntos e maiores."
	tocar_conquista_em_sequencia(token_partida, indice_jogador)
	queue_redraw()

	# Fase 1: todos os novos polens permanecem ampliados durante 1 s.
	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree() or token_partida != identificador_partida or estado_tela != "partida":
		return
	if not celebracao_objetivo_ativa:
		return
	polens_em_tamanho_duplo = false
	polens_novos_ampliados.clear()
	queue_redraw()

	# Fase 2: mais 1 s com polens no tamanho normal e realces amarelos.
	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree() or token_partida != identificador_partida or estado_tela != "partida":
		return
	if not celebracao_objetivo_ativa:
		return

	# Somente depois de 2 s o objetivo passa de ATUAIS para CONCLUIDOS.
	if indice_jogador < 0 or indice_jogador >= jogadores.size():
		return
	var jogador: Dictionary = jogadores[indice_jogador]
	var objetivos: Array[Dictionary] = jogador["objetivos"]
	if indice < 0 or indice >= objetivos.size() or objetivos[indice].is_empty():
		return
	if str(objetivos[indice].get("id", "")) != id_objetivo:
		return
	var objetivo: Dictionary = objetivos[indice]
	jogador["pontos_base"] = int(jogador["pontos_base"]) + pontos
	jogador["pontos"] = int(jogador["pontos"]) + pontos
	juice_registrar_ganho(indice_jogador, pontos, 0)
	feel_lancar_estrelas(indice_jogador, retangulo_objetivo_ativo(indice).get_center(), pontos)
	juice_vibrar(42)
	jogador["objetivos_concluidos"] = int(jogador["objetivos_concluidos"]) + 1
	linhas_pontuadas[id_objetivo] = true
	var historico: Array = jogador["historico_objetivos"]
	var entrada_historico: Dictionary = objetivo.duplicate(true)
	entrada_historico["duplicado"] = false
	entrada_historico["pontos_finais"] = pontos
	entrada_historico["polens_aplicados"] = {"vermelha": 0, "amarela": 0, "lilas": 0}
	historico.append(entrada_historico)
	tocar_som("papel_arquivo")
	juice_arquivo = {"carta": entrada_historico.duplicate(true), "indice": indice, "dono": indice_jogador, "inicio": juice_relogio, "duracao": 0.44 * juice_fator_tempo()}
	registrar_objetivo_fada_concluido(objetivo, indice_jogador)
	# O historico pode ter mais de 5 cartas. Ir para a
	# pagina mais recente sempre que uma nova conquista for registrada.
	var cartas_por_pagina: int = capacidade_pagina_historico()
	pagina_historico[indice_jogador] = maxi(0,
		int(ceil(float(historico.size()) / float(cartas_por_pagina))) - 1)
	atualizar_botoes_historico()
	# Original: manter a carta conquistada visível até sua substituição,
	# para que o painel nunca mostre menos de 3 objetivos durante a animação.
	# A pontuação já foi registrada, então linhas_pontuadas impede reconquista.
	objetivos[indice] = {}
	# O realce termina em 2 s, mas a jogada so passa de turno apos a
	# reposicao de 1 s: quem conquistou ve a carta ir para o historico.
	celebracao_objetivo_casas.clear()
	celebracao_objetivo_indice = -1
	celebracao_objetivo_jogador = -1
	polens_novos_ampliados.clear()
	polens_em_tamanho_duplo = false
	queue_redraw()
	var indices: Array[int] = [indice]
	await repor_objetivos_apos_um_segundo(indice_jogador, indices, token_partida)
	if not is_inside_tree() or token_partida != identificador_partida or estado_tela != "partida":
		return
	celebracao_objetivo_ativa = false
	finalizar_jogada_apos_celebracao(pontos)


func repor_objetivos_apos_um_segundo(indice_jogador: int, indices: Array[int], id_partida: int) -> void:
	# A celebracao ja durou 2 segundos. Somente agora se inicia a espera
	# de mais 1 segundo com o slot visualmente vazio.
	await get_tree().create_timer(1.0, false).timeout
	if not is_inside_tree() or id_partida != identificador_partida or estado_tela != "partida":
		return
	if indice_jogador < 0 or indice_jogador >= jogadores.size():
		return

	if aula_demonstracao_ativa():
		var reposicoes: Dictionary = AULA_ALTERNATIVA_REPOSICOES
		if reposicoes.has(aula_passo_humano()):
			# Detectar a transição da terceira conquista, antes de substituir a mão.
			var nova_etapa: bool = int(jogadores[indice_jogador]["objetivos_concluidos"]) == 3 and not bool(jogadores[indice_jogador].get("fase_dificil_ativa", false))
			var apresentar_fadas: bool = eh_alternativa() and indice_jogador == 0 and nova_etapa
			if nova_etapa:
				juice_iniciar_transicao_objetivos(indice_jogador)
			aula_entregar_mao(indice_jogador, reposicoes[aula_passo_humano()])
			if int(jogadores[indice_jogador]["objetivos_concluidos"]) == 2:
				aula_preparar_previa_objetivos(indice_jogador)
			atualizar_botoes_historico()
			queue_redraw()
			if nova_etapa:
				await juice_aguardar_transicao_objetivos(id_partida)
				if not is_inside_tree() or id_partida != identificador_partida or estado_tela != "partida":
					return
			if apresentar_fadas:
				await aula_apresentar_objetivos_fada(id_partida)
			return

	# Cada jogador progride individualmente. A Original troca a mão
	# após a terceira conquista; a Expandida mantém sua regra anterior.
	if int(jogadores[indice_jogador]["objetivos_concluidos"]) >= 3 and not bool(jogadores[indice_jogador].get("fase_dificil_ativa", false)):
		juice_iniciar_transicao_objetivos(indice_jogador)
		ativar_objetivos_grandes(indice_jogador)
		atualizar_botoes_historico()
		queue_redraw()
		await juice_aguardar_transicao_objetivos(id_partida)
		if not is_inside_tree() or id_partida != identificador_partida or estado_tela != "partida":
			return
		# A faixa contextual explica a nova mão sem interromper o duelo.
		return
	var objetivos: Array[Dictionary] = jogadores[indice_jogador]["objetivos"]
	# Mantém as categorias Médio/Difícil/Fada e evita cartas repetidas no painel.
	var ativos: Array[Dictionary] = []
	for dados in jogadores:
		var cartas: Array[Dictionary] = dados["objetivos"]
		for carta in cartas:
			if not carta.is_empty() and not linhas_pontuadas.has(str(carta.get("id", ""))):
				ativos.append(carta)

	for indice in indices:
		if indice < 0 or indice >= objetivos.size():
			continue
		# A Original preserva visualmente a carta concluída durante a espera.
		# Só esta carta (já registrada em linhas_pontuadas) pode ser substituída.
		if not objetivos[indice].is_empty():
			continue
		var substituta: Dictionary = {}
		var faixa: String = str(jogadores[indice_jogador]["faixas_objetivos"][indice])
		if faixa == "fada":
			substituta = sortear_objetivo_fada(objetivos)
		else:
			# Original e Expandida: 3–4 / 5–7.
			var faixa_pontos_atual: int = (faixa_objetivos_original(indice_jogador)
				if eh_gamer() else (78 if bool(jogadores[indice_jogador].get("fase_dificil_ativa", false)) else 46))
			substituta = novo_objetivo_grande(ativos, objetivos, faixa_pontos_atual)
		objetivos[indice] = substituta
		registrar_objetivo_fada_entregue(substituta, indice_jogador)
		if not substituta.is_empty():
			ativos.append(substituta)
	if aula_duelo_ativa() and int(jogadores[indice_jogador]["objetivos_concluidos"]) == 2:
		aula_preparar_previa_objetivos(indice_jogador)
	atualizar_botoes_historico()
	queue_redraw()

# ============================================================================
# PONTUACAO FINAL: OTIMIZACAO EXATA DE POLEN POR JOGADOR
# ============================================================================
# ==========================================================================
# ROTINAS LEGADAS DE DUPLICACAO (DESATIVADAS; GAMER USA SOMENTE O FINAL)
# ==========================================================================
func retangulo_objetivo_historico(indice_objetivo: int) -> Rect2:
	var capacidade: int = capacidade_pagina_historico()
	var lado: float = tamanho_carta_historico()
	var local: int = indice_objetivo % capacidade
	var colunas: int = colunas_historico()
	var largura: float = float(colunas) * lado + float(colunas - 1) * 7.0
	return Rect2(area_janela_conquistas.get_center().x - largura * 0.5 + float(local % colunas) * (lado + 7.0),
		area_janela_conquistas.position.y + 57.0 + float(floori(float(local) / float(colunas))) * (lado + 7.0), lado, lado)

func posicoes_de_polens_no_objetivo(objetivo: Dictionary, r: Rect2, no_centro_da_flor: bool = false) -> Array[Vector2]:
	# Repete a mesma geometria do desenho da miniatura no historico.
	var posicoes: Array[Vector2] = []
	var escala: float = r.size.x / 204.0
	var margem: float = clampf(r.size.x * 0.07, 4.0, 13.0)
	var altura_cabecalho: float = clampf(r.size.y * 0.235, 15.0, 43.0)
	var area_desenho: Rect2 = Rect2(
		r.position + Vector2(margem, altura_cabecalho + 3.0),
		Vector2(r.size.x - 2.0 * margem, r.size.y - altura_cabecalho - margem - 5.0))
	var modelo: Dictionary = MODELOS_OBJETIVO[int(objetivo["tipo"])]
	var casas: Array[Vector2i] = posicoes_do_modelo(modelo)
	var giro: int = int(objetivo.get("rotacao_visual", 0)) % 4
	for i in range(casas.size()):
		casas[i] = transformar_posicao(casas[i], giro, false)
	var minimo_x: int = 999
	var maximo_x: int = -999
	var minimo_y: int = 999
	var maximo_y: int = -999
	for casa in casas:
		minimo_x = mini(minimo_x, casa.x)
		maximo_x = maxi(maximo_x, casa.x)
		minimo_y = mini(minimo_y, casa.y)
		maximo_y = maxi(maximo_y, casa.y)
	var intervalo: float = clampf(5.0 * escala, 1.5, 5.0)
	var lado_quadrado: float = minf(52.0, minf(
		(area_desenho.size.x - 2.0 * intervalo) / 3.0,
		(area_desenho.size.y - 2.0 * intervalo) / 3.0))
	lado_quadrado = maxf(1.0, lado_quadrado)
	var passo: float = lado_quadrado + intervalo
	var centro_modelo: Vector2 = Vector2(float(minimo_x + maximo_x) * 0.5,
		float(minimo_y + maximo_y) * 0.5)
	for casa in casas:
		var centro: Vector2 = area_desenho.get_center() + (Vector2(casa) - centro_modelo) * passo
		# Na distribuicao final, o polen voa ate o CENTRO da flor.
		# Nas demais telas, permanece acima da flor como no desenho anterior.
		posicoes.append(centro if no_centro_da_flor else centro + Vector2(lado_quadrado * 0.23, -lado_quadrado * 0.27))
	return posicoes

func geometria_reserva_polens(quantidade: int, slots: int = 0) -> Vector3:
	var quantidade_slots: int = quantidade_slots_objetivos() if slots <= 0 else slots
	var ultimo: Rect2 = retangulo_objetivo_com_slots(quantidade_slots - 1, quantidade_slots)
	var largura: float = maxf(15.0, area_objetivos.size.x - 20.0)
	var inicio_y: float = ultimo.end.y + 5.0
	var altura: float = maxf(6.0, area_objetivos.end.y - 5.0 - inicio_y)
	var colunas: int = mini(maxi(1, quantidade), maxi(1, ceili(sqrt(float(maxi(1, quantidade)) * largura / altura))))
	var linhas: int = maxi(1, ceili(float(quantidade) / float(colunas)))
	var intervalo: float = minf(19.0, minf(largura / float(colunas), altura / float(linhas)))
	return Vector3(float(colunas), intervalo, inicio_y)

func centro_polen_reserva(indice: int, quantidade: int, slots: int = 0) -> Vector2:
	var geo: Vector3 = geometria_reserva_polens(quantidade, slots)
	var colunas: int = int(geo.x)
	return Vector2(area_objetivos.position.x + 10.0 + (float(indice % colunas) + 0.5) * geo.y,
		geo.z + (float(floori(float(indice) / float(colunas))) + 0.5) * geo.y)

func centro_grupo_polen(cor: String) -> Vector2:
	var coluna: int = maxi(0, CORES.find(cor))
	var largura_celula: float = area_contadores_polens.size.x / float(CORES.size())
	return Vector2(area_contadores_polens.position.x + float(coluna) * largura_celula + 8.0, area_contadores_polens.get_center().y)

func posicao_polen_reserva(_indice_jogador: int, cor: String) -> Vector2:
	return centro_grupo_polen(cor)

func desenhar_voo_do_polen_automatico() -> void:
	if not duplicacao_ativa or not duplicacao_voo_ativo:
		return
	var proporcao: float = clampf(duplicacao_voo_tempo / INTERVALO_DUPLICACAO_POLEN, 0.0, 1.0)
	var suavizada: float = proporcao * proporcao * (3.0 - 2.0 * proporcao)
	var inicio: Vector2 = duplicacao_voo_inicio
	var fim: Vector2 = duplicacao_voo_destino
	var pos: Vector2 = inicio.lerp(fim, suavizada) + Vector2(0.0, -sin(proporcao * PI) * 13.0)
	draw_line(inicio, fim, Color(0.98, 0.85, 0.40, 0.16), 1.3)
	draw_circle(pos, 9.0, Color(1.0, 0.90, 0.55, 0.17))
	desenhar_polen_brilhante(pos, 5.6, duplicacao_voo_cor)

func demanda_de_polen(objetivo: Dictionary) -> Dictionary:
	# A demanda depende das FLORES DESENHADAS na carta, nao da posicao
	# espacial em que o objetivo foi cumprido. Serve para futuros modelos.
	var demanda: Dictionary = {"vermelha": 0, "amarela": 0, "lilas": 0}
	var tipo: int = int(objetivo.get("tipo", -1))
	if not MODELOS_OBJETIVO.has(tipo):
		return demanda
	var padrao: Array = MODELOS_OBJETIVO[tipo]["padrao"]
	for marca in padrao:
		var cor: String = cor_da_marca(objetivo, str(marca))
		if demanda.has(cor):
			demanda[cor] = int(demanda[cor]) + 1
	return demanda

# Mochila 0/1 exata com três recursos (cores de pólen). Cada objetivo só
# pode ser duplicado uma vez. Não usa seleção gulosa; considera combinações.
func distribuir_polens_na_pontuacao_final() -> void:
	for indice_jogador in range(jogadores.size()):
		var jogador: Dictionary = jogadores[indice_jogador]
		var estoque: Dictionary = jogador["polens"]
		var grupos_total: int = 0
		# Cada pólen = 1; cada trinca completa da MESMA cor soma +2.
		for cor in CORES:
			var quantidade: int = int(estoque.get(cor, 0))
			grupos_total += quantidade + 2 * floori(float(quantidade) / 3.0)
		jogador["bonus_trios"] = grupos_total
		jogador["trios_convertidos"] = grupos_total
		jogador["pontos"] = int(jogador["pontos_base"]) + int(jogador["bonus_objetivos"]) + grupos_total

func altura_botoes_resultado() -> float:
	var h: float = v200_altura_painel_menu(get_viewport_rect().size)
	return 48.0 if h < 600.0 else 56.0

func jogadores_por_pagina_resultado() -> int:
	var h: float = minf(860.0, ui_area_segura().size.y - 24.0)
	return 2 if jogadores.size() > 1 and h >= 710.0 else 1

func total_paginas_resultado() -> int:
	if jogadores.is_empty():
		return 1
	return maxi(1, int(ceil(float(jogadores.size()) / float(jogadores_por_pagina_resultado()))))

func mudar_pagina_resultado(direcao: int) -> void:
	if estado_tela != "resultado":
		return
	pagina_resultado = clampi(pagina_resultado + direcao, 0, total_paginas_resultado() - 1)
	sincronizar_botoes_menu()
	queue_redraw()

func desenhar_polens_coletados_no_placar(estoque: Dictionary, grupo: Rect2, escala: float) -> void:
	# Totais por cor permanecem legíveis mesmo quando há dezenas de pólens.
	var x: float = grupo.position.x + 16.0
	var largura: float = grupo.size.x - 32.0
	var y: float = grupo.position.y + 185.0 * escala
	var fonte_contador: int = maxi(14, roundi(20.0 * escala))
	var largura_coluna: float = largura / 3.0
	for i in range(CORES.size()):
		var cor: String = CORES[i]
		var centro: Vector2 = Vector2(x + float(i) * largura_coluna + 10.0 * escala, y)
		desenhar_polen_brilhante(centro, 8.5 * escala, cor)
		escrever_ajustado("× %d" % int(estoque.get(cor, 0)), centro.x + 13.0 * escala,
			y + 6.0 * escala, largura_coluna - 27.0 * escala, fonte_contador, COR_TEXTO)
	# Em cartões altos, mostrar também as trincas visualmente, sem reduzir os contadores.
	var topo: float = y + 21.0 * escala
	var altura: float = grupo.end.y - 12.0 - topo
	if altura >= 25.0:
		juice_desenhar_trincas(estoque, Rect2(x, topo, largura, altura))

func desenhar_resumo_pontuacao_final(painel: Rect2) -> void:
	if jogadores.is_empty():
		return
	var compacto: bool = painel.size.y < 500.0
	var titulo_fonte: int = 26 if compacto else 34
	v200_texto_central_ajustado(resultado_titulo, painel.get_center().x,
		painel.position.y + (33.0 if compacto else 41.0), painel.size.x - 32.0, titulo_fonte, COR_OURO)
	var paginas: int = total_paginas_resultado()
	var subtitulo: String = "Pontuação final"
	if modo_partida in ["aprender_novo", "aula"]:
		subtitulo = "%d jogadas · %d/6 objetivos" % [turnos_jogados, int(jogadores[0].get("objetivos_concluidos", 0))]
	elif aula_duelo:
		subtitulo = "Aprender · placar final" if feel_final_por_regra else "Aprender · encerramento antecipado"
	elif paginas > 1:
		subtitulo = "Placar · %d de %d" % [pagina_resultado + 1, paginas]
	elif not feel_final_por_regra:
		subtitulo = "Encerramento antecipado"
	v200_texto_central_ajustado(subtitulo, painel.get_center().x, painel.position.y + (67.0 if compacto else 81.0),
		painel.size.x - (118.0 if paginas > 1 else 28.0), 19 if compacto else 21, COR_TEXTO)
	var por_pagina: int = jogadores_por_pagina_resultado()
	var primeiro: int = pagina_resultado * por_pagina
	var quantidade: int = mini(por_pagina, jogadores.size() - primeiro)
	if quantidade <= 0:
		return
	var topo: float = painel.position.y + (87.0 if compacto else 108.0)
	var limite: float = botao_pontuacao_entenda.position.y - 14.0
	var altura_util: float = maxf(1.0, limite - topo)
	var espaco: float = 12.0
	var altura_grupo: float = (altura_util - float(quantidade - 1) * espaco) / float(quantidade)
	if quantidade == 1:
		altura_grupo = minf(355.0, altura_grupo)
		topo += maxf(0.0, (altura_util - altura_grupo) * 0.30)
	var melhor_final: int = -1
	for participante in jogadores:
		melhor_final = maxi(melhor_final, int(participante.get("pontos", 0)))
	for i in range(quantidade):
		var dono: int = primeiro + i
		var dados: Dictionary = jogadores[dono]
		var total: int = int(dados.get("pontos", 0))
		var base: int = int(dados.get("pontos_base", 0))
		var estoque: Dictionary = dados.get("polens", {})
		var polens: int = 0
		for cor in CORES:
			polens += int(estoque.get(cor, 0))
		var bonus: int = int(dados.get("bonus_trios", 0)) - polens
		var grupo: Rect2 = Rect2(painel.position.x + 14.0, topo + float(i) * (altura_grupo + espaco), painel.size.x - 28.0, altura_grupo)
		var vencedor: bool = jogadores.size() > 1 and total == melhor_final and feel_final_por_regra
		ui_superficie(grupo, Color("493c32") if vencedor else Color("41352e"), COR_PRATA if vencedor else Color("987c58"), 12, true)
		if vencedor:
			draw_rect(Rect2(grupo.position + Vector2(0, 0), Vector2(grupo.size.x, 6.0)), Color(0.95, 0.90, 0.74, 0.16))
		var escala: float = minf(1.0, altura_grupo / 224.0)
		var x: float = grupo.position.x + 16.0
		var direita: float = grupo.end.x - 16.0
		var y: float = grupo.position.y
		var tamanho_nome: int = maxi(13, roundi(24.0 * escala))
		var tamanho_total: int = maxi(18, roundi(37.0 * escala))
		var t_total: float = clampf((juice_relogio - juice_fim - 0.20 * juice_fator_tempo()) / (0.85 * juice_fator_tempo()), 0.0, 1.0)
		var valor: String = rotulo_estrela_compacto(roundi(lerpf(0.0, float(total), interpolar_suave(t_total))))
		var w_total: float = ui_fonte_para(COR_PRATA, tamanho_total).get_string_size(valor, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_total).x
		while tamanho_total > 18 and w_total > (direita - x) * 0.42:
			tamanho_total -= 1
			w_total = ui_fonte_para(COR_PRATA, tamanho_total).get_string_size(valor, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_total).x
		var centro_cor: Vector2 = Vector2(x + 7.0 * escala, y + 29.0 * escala)
		draw_circle(centro_cor, 7.0 * escala, Color("b4a595"))
		draw_circle(centro_cor, 5.5 * escala, cor_visual_da_fada(dono))
		escrever_ajustado(str(dados.get("nome", "Jogador %d" % (dono + 1))), x + 20.0 * escala,
			y + 36.0 * escala, maxf(12.0, direita - x - w_total - 28.0 * escala), tamanho_nome, COR_OURO)
		escrever(valor, Vector2(direita - w_total, y + 40.0 * escala), tamanho_total, COR_PRATA)
		var linha: float = y + 58.0 * escala
		draw_line(Vector2(x, linha), Vector2(direita, linha), Color("ae936f"), 1.0)
		var rotulos: Array[String] = ["Objetivos", "Pólens guardados", "Bônus de trincas"]
		var valores: Array[int] = [base, polens, bonus]
		var tam: int = maxi(12, roundi(21.0 * escala))
		for j in range(rotulos.size()):
			var linha_y: float = y + (85.0 + 31.0 * float(j)) * escala
			var numero: String = str(valores[j])
			var w_numero: float = ui_fonte_para(COR_PRATA, tam).get_string_size(numero, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
			escrever_ajustado(rotulos[j], x, linha_y, direita - x - w_numero - 16.0, tam, COR_TEXTO)
			escrever(numero, Vector2(direita - w_numero, linha_y), tam, COR_PRATA)
		draw_line(Vector2(x, y + 162.0 * escala), Vector2(direita, y + 162.0 * escala), Color("796149"), 1.0)
		desenhar_polens_coletados_no_placar(estoque, grupo, escala)

func v200_texto_central_ajustado(texto: String, centro_x: float, y: float, largura: float, tamanho: int, cor: Color) -> void:
	while tamanho > 12 and ui_fonte_para(cor, tamanho).get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x > largura:
		tamanho -= 1
	escrever_centralizado(texto, centro_x, y, tamanho, cor)

func desenhar_tela_regras(painel: Rect2) -> void:
	var titulo_painel: String = "OBJETIVOS" if estado_tela == "catalogo_objetivos" else "REGRAS DO JOGO"
	v200_texto_central_ajustado(titulo_painel, painel.get_center().x, painel.position.y + 40.0,
		painel.size.x - 28.0, 32, COR_OURO)

func desenhar_explicacao_pontuacao(painel: Rect2) -> void:
	v200_texto_central_ajustado("Entenda as estrelas", painel.get_center().x,
		painel.position.y + 42.0, painel.size.x - 28.0, 32, COR_OURO)
	if painel.size.y >= 370.0:
		escrever_centralizado("Como sua pontuação é formada", painel.get_center().x, painel.position.y + 75.0, 18, COR_TEXTO)

func contar_polens_total_da_partida() -> int:
	var total: int = 0
	for jogador in jogadores:
		var estoque: Dictionary = jogador.get("polens", {})
		for cor in CORES:
			total += maxi(0, int(estoque.get(cor, 0)))
	for casa in polens_por_casa:
		if tabuleiro.has(casa) and CORES.has(str(tabuleiro[casa])):
			total += maxi(0, int(polens_por_casa[casa]))
	return total

func encerrar_partida(tocar_final_agora: bool = true, concluida_por_regra: bool = false) -> void:
	if partida_encerrada:
		return
	juice_limpar()
	aula_nav_limpar()
	aula_limpar_ajuda()
	aula_fechar_aviso_licao()
	aula_fechar_aviso_fada()
	fechar_painel_escolha_de_objetivos()
	# Medição antes da duplicação final (apenas Original).
	print("[Jardim] Polens ao encerrar (todos os jogadores + todas as flores): %d" % contar_polens_total_da_partida())
	# Encerramento voluntario tem prioridade sobre voos, espera
	# de reposicao e turno da maquina. As rotinas assicronas usam estes
	# identificadores para nao modificar a partida ja terminada.
	identificador_partida += 1
	identificador_movimento += 1
	animacao_setup_ativa = false
	duplicacao_ativa = false
	duplicacao_voo_ativo = false
	celebracao_objetivo_ativa = false
	polens_em_tamanho_duplo = false
	maquina_ocupada = false
	if movimento_pendente:
		desfazer_deslocamento()
	movimento_pendente = false
	aguardando_reposicao_automatica = false
	origem_selecionada = CELULA_INVALIDA
	alvo_transformacao = CELULA_INVALIDA
	fada_diagonal_pendente = -1
	acao_nova = ""
	limpar_etapa_fadas()
	tutorial_painel_arrastando = false
	janela_pintura_retangulo = Rect2()
	escolhas_flores_pintura.clear()
	modo_movimento = false
	partida_encerrada = true
	rodada_bonus_ativa = false
	rodada_bonus_etapa = 0
	rodada_bonus_autor = -1
	rodada_bonus_fila.clear()
	maquina_ocupada = false
	tutorial_final_pendente = false
	# Apenas a Original (e seu fluxo próprio) duplica objetivos florais.
	# A Expandida soma pontos individuais e trincas de polens sem animacao.
	estado_tela = "distribuicao_final"
	juice_final_expandida_inicio = juice_relogio
	juice_final_expandida_duracao = 2.8 * juice_fator_tempo()
	sincronizar_botoes_menu()
	queue_redraw()
	animar_final_expandida(identificador_partida, tocar_final_agora, concluida_por_regra)
	return

func finalizar_resultado_partida(tocar_final_agora: bool, concluida_por_regra: bool) -> void:
	# Apurar vencedor apenas depois dos bônus por pólens da versão.
	fechar_painel_escolha_de_objetivos()
	distribuir_polens_na_pontuacao_final()
	gravar_metricas_objetivos_fada()
	gravar_resumo_pontuacao_balanceamento()
	pagina_resultado = 0
	flor_na_mao = ""
	origem_carta_selecionada = ""
	if modo_partida in ["aprender_novo", "aula"]:
		var meta_aula: bool = int(jogadores[0]["objetivos_concluidos"]) >= DUELO_META_OBJETIVOS
		resultado_titulo = "TUTORIAL CONCLUÍDO!" if meta_aula else ("CARTAS ESGOTADAS" if concluida_por_regra else "TUTORIAL ENCERRADO")
		resultado_detalhes = "%d jogadas | %d/6 objetivos | %s" % [turnos_jogados,
			int(jogadores[0]["objetivos_concluidos"]), rotulo_estrela_compacto(int(jogadores[0]["pontos"]))]
		mensagem = "Você completou seis objetivos. Experimente uma nova partida!" if meta_aula else "Veja suas conquistas e as estrelas dos pólens. Você pode praticar novamente."
	else:
		# A comparação acontece APÓS distribuir_polens_na_pontuacao_final():
		# objetivos ativam o término da partida, mas nunca desempatarão o placar.
		var melhor_pontuacao: int = -999999
		var vencedores: Array[int] = []
		var detalhes_partes: Array[String] = []
		for i in range(jogadores.size()):
			var participante: Dictionary = jogadores[i]
			var pontos_i: int = int(participante.get("pontos", 0))
			var objetivos_i: int = int(participante.get("objetivos_concluidos", 0))
			detalhes_partes.append("%s: %s / %d obj" % [str(participante.get("nome", "Jogador %d" % (i + 1))), rotulo_estrela_compacto(pontos_i), objetivos_i])
			if pontos_i > melhor_pontuacao:
				melhor_pontuacao = pontos_i
				vencedores = [i]
			elif pontos_i == melhor_pontuacao:
				vencedores.append(i)
		if vencedores.size() != 1:
			resultado_titulo = "EMPATE!"
		else:
			var vencedor: int = vencedores[0]
			resultado_titulo = "%s VENCERAM!" % nome_cor_fada_plural(vencedor).to_upper()
		resultado_detalhes = ""
		for i in range(detalhes_partes.size()):
			if i > 0:
				resultado_detalhes += "  |  "
			resultado_detalhes += detalhes_partes[i]
		if not concluida_por_regra:
			resultado_detalhes += " | Encerramento antecipado"
		mensagem = resultado_titulo
	estado_tela = "resultado"
	feel_final_por_regra = concluida_por_regra
	juice_fim = juice_relogio
	audio_trincas_final_tocou = eh_alternativa()
	atualizar_botoes_de_movimento()
	sincronizar_botoes_menu()
	queue_redraw()
	if tocar_final_agora:
		tocar_som("fim")

func mostrar_placar_parcial() -> bool:
	# Mesmo placar na prática e nas partidas de 2–4 jogadores.
	return estado_tela == "partida" and area_historico.has_area() and not jogadores.is_empty()

func perf_estado_layout() -> Array:
	# Somente valores que afetam geometria, visibilidade e navegação.
	var historico_atual: int = 0
	if jogador_atual >= 0 and jogador_atual < jogadores.size():
		historico_atual = jogadores[jogador_atual].get("historico_objetivos", []).size()
	return [get_viewport_rect().size, ui_insets, deve_usar_interface_compacta(get_viewport_rect().size), controles_revisao_no_pc(), historico_atual,
		identificador_partida, estado_tela, modo_partida, versao_nova, versao_gamer_progressiva,
		jogador_atual, jogadores.size(), quantidade_slots_objetivos(), turnos_jogados, partida_encerrada,
		aula_duelo, aula_aviso_licao_tipo, tutorial_etapa, tutorial_final_pendente, tutorial_pratica_livre,
		tutorial_passo_consulta, tutorial_rotacao_pronta, passo_tutorial_atual(), indice_estado_tutorial,
		acao_nova, etapa_fada, flor_na_mao, origem_carta_selecionada, origem_selecionada, movimento_pendente,
		animacao_setup_ativa, celebracao_objetivo_ativa, duplicacao_ativa,
		escolha_objetivo_ativa, escolhas_iniciais_pendentes, maquina_ocupada, aguardando_reposicao_automatica,
		animacao_compra_ativa, juice_plantar.is_empty(), juice_repor.is_empty(), conquistas_abertas,
		indice_cenario_em_revisao, revisao_final_ativa, cenarios_anteriores.size(), pagina_catalogo,
		cartas_catalogo_visual.size(), pagina_resultado, total_paginas_resultado(), pode_abrir_revisao_visual(),
		pode_abrir_conquistas(), pratica_com_dicas_breves()]

func atualizar_layout(forcar: bool = true) -> void:
	var chave_layout: Array = perf_estado_layout()
	if not forcar and chave_layout == perf_layout_chave:
		return
	var tela: Vector2 = get_viewport_rect().size
	interface_compacta = true
	layout_paisagem = false
	var margem: float = 8.0
	var lateral: float = margem + maxf(ui_insets.x, ui_insets.z)
	var largura: float = tela.x - 2.0 * lateral
	var topo: float = margem + ui_insets.y
	var rodape: float = margem + ui_insets.w
	var intervalo: float = 6.0
	var lado_saida: float = 48.0
	var altura_placar: float = lado_saida
	# Texto direto sobre a mesa; o tutorial mantém espaço para leitura e navegação.
	var altura_instrucao: float = 94.0 if pratica_com_dicas_breves() or aula_duelo else 36.0
	var largura_mao_coluna: float = clampf(largura * 0.29, 120.0, 142.0)
	var largura_objetivos: float = largura - largura_mao_coluna - intervalo
	var linhas: int = 2 # Reserva a mesma grade nas duas etapas e no tutorial.
	var espaco_cartas: float = espaco_grade_objetivos(largura_objetivos)
	var lado_objetivo: float = lado_grade_objetivos(largura_objetivos)
	var altura_objetivos: float = 28.0 + float(linhas) * lado_objetivo + float(linhas - 1) * espaco_cartas + 16.0
	# v230: aumentar a altura da coluna somente até o limite que preserva o jardim.
	# As três cartas usam a largura disponível; o espaço de ações é condicional.
	var lado_desejado: float = largura_mao_coluna - 12.0
	var altura_desejada_coluna: float = 3.0 * lado_desejado + 100.0
	var altura_disponivel: float = tela.y - topo - rodape - altura_placar - altura_instrucao - 2.0 * intervalo
	var jardim_minimo: float = 205.0 if altura_disponivel >= 550.0 else 165.0
	altura_objetivos = maxf(altura_objetivos, minf(altura_desejada_coluna, altura_disponivel - jardim_minimo))
	altura_objetivos = maxf(altura_objetivos, 292.0)
	var altura_faixa_inferior: float = altura_objetivos
	var altura_mesa: float = maxf(1.0, tela.y - topo - rodape - altura_placar - altura_instrucao - altura_faixa_inferior - 2.0 * intervalo)

	# Cabeçalho único: placar à esquerda, saída à direita, ambos na mesma altura.
	botao_encerrar = Rect2(lateral + largura - lado_saida, topo, lado_saida, lado_saida)
	area_historico = Rect2(lateral, topo, largura - lado_saida - intervalo, altura_placar)
	area_tabuleiro = Rect2(lateral, area_historico.end.y + intervalo, largura, altura_mesa)
	# Sem intervalo ou contorno entre a mesa e o texto: uma superfície marrom contínua.
	area_dica_aprender = Rect2(lateral, area_tabuleiro.end.y, largura, altura_instrucao)

	var topo_inferior: float = area_dica_aprender.end.y + intervalo
	area_objetivos = Rect2(lateral, topo_inferior, largura_objetivos, altura_objetivos)
	var area_mao_painel: Rect2 = Rect2(area_objetivos.end.x + intervalo, topo_inferior, largura_mao_coluna, altura_objetivos)
	# Uma coluna única: pólens, baralho, coletiva, ações e mão.
	area_compra = area_mao_painel
	# v230: três cartas iguais, próximas das bordas, com respiros equilibrados.
	var margem_topo_coluna: float = 5.0
	var altura_polens_coluna: float = 20.0
	var intervalo_polens: float = 9.0
	var altura_legenda: float = 15.0
	var intervalo_cartas: float = 9.0
	var margem_base_coluna: float = 6.0
	# Espelhar a condição de visibilidade dos controles de ação. Não reservar
	# uma faixa vazia durante plantio, compra ou voo; manter Cancelar acessível.
	var acoes_disponiveis: bool = not aula_guiada_ativa() and not escolhas_iniciais_pendentes and not tutorial_final_pendente and estado_tela == "partida" and not partida_encerrada and not turno_da_maquina() and not animacao_setup_ativa and not celebracao_objetivo_ativa and etapa_fada == "" and indice_cenario_em_revisao < 0 and tutorial_passo_consulta < 1
	var acoes_ativas: bool = acoes_disponiveis and (acao_nova in ["mover", "poderes", "diagonal_fada", "diagonal_destino", "pintar_alvo", "pintar_cor"] or (acao_nova == "plantar" and flor_na_mao == ""))
	var altura_acoes: float = 32.0 if acoes_ativas else 0.0
	var espaco_acoes: float = altura_acoes + 4.0 if acoes_ativas else 0.0
	var espaco_fixo: float = margem_topo_coluna + altura_polens_coluna + intervalo_polens + 3.0 * altura_legenda + 2.0 * intervalo_cartas + margem_base_coluna + espaco_acoes
	var lado_coluna: float = maxf(1.0, minf(area_compra.size.x - 12.0, (area_compra.size.y - espaco_fixo) / 3.0))
	var respiro: float = maxf(0.0, (area_compra.size.y - espaco_fixo - 3.0 * lado_coluna) / 3.0)
	area_contadores_polens = Rect2(area_compra.position + Vector2(5.0, margem_topo_coluna), Vector2(area_compra.size.x - 10.0, altura_polens_coluna))
	var x_cartas: float = area_compra.get_center().x - lado_coluna * 0.5
	area_baralho = Rect2(Vector2(x_cartas, area_contadores_polens.end.y + intervalo_polens + respiro), Vector2.ONE * lado_coluna)
	area_aberta = Rect2(Vector2(x_cartas, area_baralho.end.y + altura_legenda + intervalo_cartas + respiro), Vector2.ONE * lado_coluna)
	area_acoes_gamer = Rect2(Vector2(area_compra.position.x + 3.0, area_aberta.end.y + altura_legenda + 2.0), Vector2(area_compra.size.x - 6.0, altura_acoes))
	area_mao = Rect2(Vector2(x_cartas, area_aberta.end.y + altura_legenda + intervalo_cartas + respiro + espaco_acoes), Vector2.ONE * lado_coluna)

	var tamanho_janela: Vector2 = Vector2(minf(610.0, ui_area_segura().size.x - 24.0), minf(525.0, ui_area_segura().size.y - 40.0))
	area_janela_conquistas = Rect2((tela - tamanho_janela) * 0.5, tamanho_janela)
	botao_fechar_conquistas = Rect2(area_janela_conquistas.end.x - 51.0, area_janela_conquistas.position.y + 5.0, 46.0, 46.0)
	botao_anterior_conquistas = Rect2(area_janela_conquistas.position.x + 9.0, area_janela_conquistas.end.y - 54.0, 46.0, 46.0)
	botao_proximo_conquistas = Rect2(area_janela_conquistas.end.x - 55.0, area_janela_conquistas.end.y - 54.0, 46.0, 46.0)

	botao_novo = Rect2()

	atualizar_botoes_historico()
	posicionar_botoes_poder()
	sincronizar_botoes_menu()
	perf_layout_chave = perf_estado_layout()

func centro_visual_do_jardim() -> Vector2:
	return area_tabuleiro.get_center()

func tamanho_carta_base_jardim() -> float:
	return clampf(minf((area_tabuleiro.size.y - 12.0) / 3.5, (area_tabuleiro.size.x - 20.0) / 4.0), 22.0, TAMANHO_CARTA)

func texto_vez_atual() -> String:
	return "Vez das %s" % nome_cor_fada_plural(jogador_atual).to_lower()

func posicao_celula(c: Vector2i) -> Vector2:
	return centro_visual_do_jardim() + deslocamento + Vector2(c) * tamanho_carta_base_jardim() * zoom

func celula_na_posicao(pos: Vector2) -> Vector2i:
	var relativo: Vector2 = (pos - centro_visual_do_jardim() - deslocamento) / (tamanho_carta_base_jardim() * zoom)
	return Vector2i(roundi(relativo.x), roundi(relativo.y))

func mudar_zoom(fator: float, ancora: Vector2) -> void:
	mobile_camera_manual()
	var anterior: float = zoom
	zoom = clampf(zoom * fator, 0.12, 1.9)
	var relativo: Vector2 = ancora - centro_visual_do_jardim()
	deslocamento = relativo - (relativo - deslocamento) * (zoom / anterior)
	queue_redraw()

# A navegacao da camera e independente do bloqueio de jogadas/animacoes.
# Mesmo na vez da maquina ou na celebracao dos objetivos, o jogador deve
# poder arrastar o jardim e usar a roda ou os gestos de pinça.
func tratar_camera_durante_bloqueio(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		if toque_tabuleiro:
			if event.position.distance_to(inicio_toque) > 11.0:
				toque_arrastou = true
			if toque_arrastou:
				mobile_camera_manual()
				deslocamento += event.position - ultimo_toque
			ultimo_toque = event.position
		if area_tabuleiro.has_point(mouse_pos):
			celula_mouse = celula_na_posicao(mouse_pos)
		else:
			celula_mouse = Vector2i(99999, 99999)
		queue_redraw()
		return toque_tabuleiro
	if not (event is InputEventMouseButton):
		return false
	var clique: InputEventMouseButton = event as InputEventMouseButton
	mouse_pos = clique.position
	if clique.pressed and area_tabuleiro.has_point(clique.position):
		if clique.button_index == MOUSE_BUTTON_WHEEL_UP:
			mudar_zoom(1.1, clique.position)
			return true
		if clique.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			mudar_zoom(1.0 / 1.1, clique.position)
			return true
	if clique.button_index != MOUSE_BUTTON_LEFT:
		return false
	if not clique.pressed:
		if toque_tabuleiro:
			toque_tabuleiro = false
			toque_arrastou = false
			queue_redraw()
			return true
		return false
	if area_tabuleiro.has_point(clique.position):
		toque_tabuleiro = true
		toque_arrastou = false
		inicio_toque = clique.position
		ultimo_toque = clique.position
		return true
	return false

# v177: a pressão é apenas intenção; a soltura confirma a compra/plantio.
func mobile_limpar_intencao() -> void:
	cancelar_voo_press = Vector2i(-1, -1)
	v209_retorno_borda.clear()
	mobile_objetivo_giro_indice = -1
	v209_giro_angulo = 0.0
	v209_giro_id = ""
	v209_encaixe = CELULA_INVALIDA
	mobile_borda_arrastada = CELULA_INVALIDA
	feel_previa_casas.clear()
	feel_previa_arrasto_chave.clear()
	mobile_arrastando_coletiva = false
	mobile_arrastando_mao = false
	mobile_objetivo_press = -1
	mobile_fonte_pressionada = -1
	mobile_ajustando_plantio = false
	mobile_fada_pressionada = -1
	mobile_casa_pressionada = CELULA_INVALIDA
	toque_tabuleiro = false
	toque_arrastou = false
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		ambiente_foco = true
		v209_amostra = 0.0
		v209_lento = 0
		v209_rapido = 0
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		ambiente_foco = false
		aula_nav_cancelar_gesto()
		v199_parar_ambiente()
		mobile_fechar_objetivo_ampliado()
		saida_pressionada = false
		mobile_limpar_intencao()
		mobile_dedos.clear()
		pontos_multitoque.clear()
		mobile_gesto_cancelado = false
		gesto_multitoque_ativo = false

func mobile_contexto_jogavel() -> bool:
	return estado_tela == "partida" and not partida_encerrada and not turno_da_maquina() \
		and not maquina_ocupada and not animacao_setup_ativa and not celebracao_objetivo_ativa \
		and not duplicacao_ativa and not animacao_compra_ativa and juice_plantar.is_empty() \
		and juice_repor.is_empty() \
		and not conquistas_abertas and not escolha_objetivo_ativa \
		and not escolhas_iniciais_pendentes and not tutorial_final_pendente \
		and tutorial_passo_consulta < 1 and indice_cenario_em_revisao < 0 \
		and not aula_aviso_licao_ativo() and not aula_aviso_fada_ativo() and aula_nav_indice < 0

# O botão só existe enquanto a escolha de voar é opcional; não interrompe um voo.
func pode_cancelar_voo_na_mao() -> bool:
	return flor_na_mao == "" and etapa_fada in ["oferta", "escolha"] \
		and mobile_contexto_jogavel() and not pausa_saida_ativa \
		and mobile_objetivo_ampliado.is_empty() and not aula_nav_animando \
		and not (aula_demonstracao_ativa() and fadas_elegiveis.has(int(aula_plano().get("fada", -1))))

func mobile_pode_arrastar_coletiva() -> bool:
	return mobile_contexto_jogavel() and pode_realcar_fonte_compra(true) \
		and not modo_movimento and not movimento_pendente and not aguardando_reposicao_automatica \
		and origem_selecionada == CELULA_INVALIDA and acao_nova in ["", "plantar"] \
		and (not aula_guiada_ativa() or (aula_demonstracao_ativa() and aula_origem() == CELULA_INVALIDA)) \
		and acao_permitida_no_tutorial_novo("plantar")

func mobile_pode_prever_plantio(c: Vector2i) -> bool:
	if mobile_arrastando_coletiva:
		return mobile_pode_arrastar_coletiva() and pode_colocar(c) and (not aula_guiada_ativa() or c == aula_destino())
	return mobile_contexto_jogavel() and etapa_fada == "" and flor_na_mao != "" \
		and not modo_movimento and not movimento_pendente and not aguardando_reposicao_automatica and origem_selecionada == CELULA_INVALIDA \
		and acao_nova in ["", "plantar"] and pode_colocar(c) \
		and (not aula_guiada_ativa() or c == aula_alvo_tabuleiro())

func mobile_area_fonte(da_aberta: bool) -> Rect2:
	# Cada fonte ocupa uma faixa vertical exclusiva, com sua própria legenda.
	var r: Rect2 = area_aberta if da_aberta else area_baralho
	return Rect2(Vector2(area_compra.position.x + 3.0, r.position.y - 2.0), Vector2(area_compra.size.x - 6.0, r.size.y + 17.0))

func mobile_armar_compra(da_aberta: bool) -> void:
	if mobile_contexto_jogavel() and pode_realcar_fonte_compra(da_aberta):
		mobile_fonte_pressionada = 1 if da_aberta else 0
		mobile_inicio_compra = mouse_pos
		mobile_token_compra = identificador_partida
		mobile_turno_compra = turnos_jogados
		queue_redraw()

func mobile_soltar_coletiva_arrastada(pos: Vector2) -> void:
	# A compra é confirmada uma única vez, na soltura, como no toque normal.
	var valida: bool = mobile_token_compra == identificador_partida and mobile_turno_compra == turnos_jogados \
		and not mobile_gesto_cancelado and not gesto_multitoque_ativo and mobile_pode_arrastar_coletiva()
	var casa: Vector2i = feel_casa_magnetica(pos) if valida else CELULA_INVALIDA
	var origem_visual: Vector2 = feel_pos
	var angulo: float = feel_angulo
	var lado_visual: float = feel_lado_arrasto()
	mobile_limpar_intencao()
	if not valida:
		return
	escolher_carta(true, true)
	if flor_na_mao == "" or origem_carta_selecionada != "aberta":
		return
	juice_vibrar(12)
	if casa != CELULA_INVALIDA and mobile_pode_prever_plantio(casa):
		feel_origem_plantio = {"pos": origem_visual, "angulo": angulo, "lado": lado_visual}
		executar_acao_no_tabuleiro(casa, pos)
		feel_origem_plantio.clear()
	else:
		# Não desfazer a compra quando a soltura não é um plantio válido.
		feel_retorno = {"pos": origem_visual, "angulo": angulo, "cor": flor_na_mao, "lado": lado_visual, "inicio": juice_relogio, "duracao": 0.24 * juice_fator_tempo()}
	queue_redraw()

func mobile_soltar_compra(pos: Vector2) -> void:
	if mobile_arrastando_coletiva:
		mouse_pos = pos
		mobile_soltar_coletiva_arrastada(pos)
		return
	var fonte_compra: int = mobile_fonte_pressionada
	mobile_fonte_pressionada = -1
	mouse_pos = pos
	if fonte_compra >= 0 and mobile_token_compra == identificador_partida and mobile_turno_compra == turnos_jogados \
			and not mobile_gesto_cancelado and not gesto_multitoque_ativo and mobile_contexto_jogavel():
		var aberta: bool = fonte_compra == 1
		if mobile_area_fonte(aberta).has_point(pos) and pode_realcar_fonte_compra(aberta):
			escolher_carta(aberta)
			if flor_na_mao != "":
				juice_vibrar(12)
	queue_redraw()

# A flor amarela no menu inicial é exclusivamente decorativa.
func _input(event: InputEvent) -> void:
	# A pinça cancela qualquer compra ou plantio armado, mesmo se o primeiro
	# dedo começou sobre uma carta de compra, fora do jardim.
	if event is InputEventScreenTouch:
		if event.pressed:
			mobile_dedos[event.index] = true
			if mobile_dedos.size() > 1:
				aula_nav_cancelar_gesto()
				saida_pressionada = false
				mobile_gesto_cancelado = true
				mobile_limpar_intencao()
		else:
			mobile_dedos.erase(event.index)
			if event.canceled:
				aula_nav_cancelar_gesto()
				saida_pressionada = false
				mobile_limpar_intencao()
			if mobile_dedos.is_empty():
				mobile_gesto_cancelado = false
				pontos_multitoque.clear()
				gesto_multitoque_ativo = false
	if not mobile_objetivo_ampliado.is_empty():
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			mobile_fechar_objetivo_ampliado()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				mobile_objetivo_fechar_press = true
			elif mobile_objetivo_fechar_press:
				mobile_fechar_objetivo_ampliado()
		get_viewport().set_input_as_handled()
		return
	if mobile_objetivo_giro_indice >= 0 and event is InputEventMouseMotion:
		mouse_pos = event.position
		if v209_giro_valido():
			v209_atualizar_angulo(event.position)
		else:
			mobile_limpar_intencao()
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and toque_tabuleiro and not toque_arrastou and mobile_borda_arrastada == CELULA_INVALIDA and not mobile_ajustando_plantio:
		if event.position.distance_to(inicio_toque) > 11.0 and v199_pode_arrastar_borda(mobile_casa_pressionada):
			mobile_borda_arrastada = mobile_casa_pressionada
			feel_pos = posicao_celula(mobile_borda_arrastada)
			feel_alvo = feel_pos
			feel_angulo = 0.0
			feel_inclinacao_alvo = 0.0
			camera_ajustando = false
	if mobile_borda_arrastada != CELULA_INVALIDA and event is InputEventMouseMotion:
		mouse_pos = event.position
		feel_inclinacao_alvo = clampf(-event.relative.x * 0.009, -0.12, 0.12)
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and mobile_fonte_pressionada == 1 and not mobile_arrastando_coletiva:
		if event.position.distance_to(mobile_inicio_compra) > 11.0 and mobile_pode_arrastar_coletiva():
			mobile_arrastando_coletiva = true
			mobile_ajustando_plantio = true
			feel_retorno.clear()
			feel_pos = area_aberta.get_center()
			feel_alvo = feel_pos
			feel_angulo = 0.0
			feel_inclinacao_alvo = 0.0
	if (mobile_arrastando_mao or mobile_arrastando_coletiva) and event is InputEventMouseMotion:
		feel_inclinacao_alvo = clampf(-event.relative.x * 0.012, -0.18, 0.18)
		mouse_pos = event.position
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if mobile_gesto_cancelado or gesto_multitoque_ativo:
			cancelar_voo_press = Vector2i(-1, -1)
			get_viewport().set_input_as_handled()
			return
		# A mesma região desenhada recebe o toque; confirmar apenas na soltura.
		if not event.pressed and cancelar_voo_press.x >= 0:
			var mesma_jogada: bool = cancelar_voo_press == Vector2i(identificador_partida, turnos_jogados)
			cancelar_voo_press = Vector2i(-1, -1)
			if mesma_jogada and pode_cancelar_voo_na_mao() and area_mao.has_point(event.position):
				recusar_movimento_fada()
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if event.pressed and pode_cancelar_voo_na_mao() and area_mao.has_point(event.position):
			mobile_limpar_intencao()
			cancelar_voo_press = Vector2i(identificador_partida, turnos_jogados)
			mouse_pos = event.position
			juice_ultima_pressao = event.position
			juice_pressao_tempo = juice_relogio
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if not event.pressed and mobile_objetivo_giro_indice >= 0:
			finalizar_giro_objetivo(event.position)
			get_viewport().set_input_as_handled()
			return
		if not event.pressed and mobile_borda_arrastada != CELULA_INVALIDA:
			v199_soltar_borda(event.position)
			get_viewport().set_input_as_handled()
			return
		if not event.pressed and mobile_arrastando_mao:
			var mesma_jogada: bool = mobile_token_tabuleiro == identificador_partida and mobile_turno_tabuleiro == turnos_jogados
			var casa_soltar: Vector2i = feel_casa_magnetica(event.position)
			var plantar: bool = mesma_jogada and area_tabuleiro.has_point(event.position) and mobile_pode_prever_plantio(casa_soltar)
			if plantar:
				feel_origem_plantio = {"pos": feel_pos, "angulo": feel_angulo}
			elif mesma_jogada and mobile_contexto_jogavel() and flor_na_mao != "":
				feel_retorno = {"pos": feel_pos, "angulo": feel_angulo, "cor": flor_na_mao, "inicio": juice_relogio, "duracao": 0.24 * juice_fator_tempo()}
			mobile_limpar_intencao()
			if plantar:
				executar_acao_no_tabuleiro(casa_soltar, event.position)
				feel_origem_plantio.clear()
			get_viewport().set_input_as_handled()
			return
		if not event.pressed and mobile_objetivo_press >= 0:
			var indice_consulta: int = mobile_objetivo_press
			mobile_objetivo_press = -1
			if mobile_contexto_jogavel() and retangulo_objetivo_ativo(indice_consulta).has_point(event.position):
				var cartas_consulta: Array[Dictionary] = jogadores[jogador_atual]["objetivos"]
				if indice_consulta < cartas_consulta.size() and not cartas_consulta[indice_consulta].is_empty():
					mobile_abrir_objetivo_ampliado(cartas_consulta[indice_consulta])
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if not event.pressed and mobile_fonte_pressionada >= 0:
			mobile_soltar_compra(event.position)
			get_viewport().set_input_as_handled()
			return
		if event.pressed:
			saida_pressionada = false
			mobile_limpar_intencao()
		elif toque_tabuleiro and (not area_tabuleiro.has_point(event.position) or not mobile_contexto_jogavel()):
			mobile_limpar_intencao()
			# Se era navegação durante uma animação, não há ação de jogo a liberar.
			queue_redraw()

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and (v199_arrasto_ativo() or mobile_objetivo_giro_indice >= 0):
		mobile_limpar_intencao()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		perf_alternar_debug()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		juice_ultima_pressao = event.position
		juice_pressao_tempo = juice_relogio
	# O botão de saída só confirma a intenção quando o dedo é solto sobre ele.
	if estado_tela == "partida" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and botao_encerrar.has_point(event.position) and not conquistas_abertas and not escolha_objetivo_ativa and not escolhas_iniciais_pendentes and not tutorial_final_pendente:
			saida_pressionada = true
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if not event.pressed and saida_pressionada:
			saida_pressionada = false
			if botao_encerrar.has_point(event.position) and not conquistas_abertas and not escolha_objetivo_ativa and not escolhas_iniciais_pendentes and not tutorial_final_pendente:
				solicitar_saida_partida()
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
	# A faixa recebe seu próprio gesto; a revisão nunca altera a mesa.
	if aula_nav_input(event):
		get_viewport().set_input_as_handled()
		return
	# Lições aguardam o avanço explícito, e páginas antigas são só leitura.
	if aula_aviso_licao_ativo() or aula_aviso_fada_ativo() or aula_nav_indice >= 0:
		get_viewport().set_input_as_handled()
		return
	if conquistas_abertas:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			fechar_conquistas()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if botao_fechar_conquistas.has_point(event.position) or not area_janela_conquistas.has_point(event.position):
				fechar_conquistas()
			elif botao_anterior_conquistas.has_point(event.position):
				alterar_pagina_historico(-1)
			elif botao_proximo_conquistas.has_point(event.position):
				alterar_pagina_historico(1)
		get_viewport().set_input_as_handled()
		return
	# A caixa de escolha modal recebe os cliques; nao acionar a mesa por tras.
	if escolha_objetivo_ativa:
		return
	# Pinça e arrasto com dois dedos: não acionam uma jogada nem um botão.
	if tratar_gestos_de_toque(event):
		return
	if mostrar_placar_parcial() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and area_historico.has_point(event.position):
		get_viewport().set_input_as_handled()
		return
	if not aula_nav_animando and aula_pode_pedir_ajuda() and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and aula_retangulo_ajuda().has_point(event.position):
		aula_pedir_ajuda()
		get_viewport().set_input_as_handled()
		return
	# Processar a camera ANTES dos bloqueios de jogada. _unhandled_input
	# pode nao receber eventos durante celebracoes, movimentos e controles.
	if estado_tela == "partida" and (turno_da_maquina() or animacao_setup_ativa \
			or celebracao_objetivo_ativa or etapa_fada == "movendo" \
			or duplicacao_ativa or aguardando_reposicao_automatica or animacao_compra_ativa or not juice_plantar.is_empty() or not juice_repor.is_empty()):
		if tratar_camera_durante_bloqueio(event):
			get_viewport().set_input_as_handled()
			return
	if estado_tela == "partida" and (animacao_compra_ativa or not juice_plantar.is_empty() or not juice_repor.is_empty()) and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		return
	# Quando a janela de cores esta aberta, somente as duas flores da
	# janela (ou os botoes de interface) podem receber o clique.
	if pintura_aguardando_cor() and event is InputEventMouseButton and event.pressed and \
			event.button_index == MOUSE_BUTTON_LEFT:
		atualizar_geometria_seletor_pintura()
		for cor in escolhas_flores_pintura:
			var r: Rect2 = escolhas_flores_pintura[cor]
			if r.has_point(event.position):
				escolher_cor_do_poder(str(cor))
				get_viewport().set_input_as_handled()
				return
		# O botao Cancelar (Control) continua clicavel fora da janela.
		var cancel: Button = botoes_acao_nova.get("cancelar") as Button
		if cancel != null and cancel.visible and Rect2(cancel.position, cancel.size).has_point(event.position):
			return
		if janela_pintura_retangulo.has_point(event.position) or area_tabuleiro.has_point(event.position):
			get_viewport().set_input_as_handled()
			return
	# Hover recebe eventos mesmo sobre Controls, evitando que o contorno azul
	# fique preso na última fada quando o cursor cruza um botão ou um painel.
	if event is InputEventMouseMotion and estado_tela == "partida":
		mouse_pos = event.position
		queue_redraw()
	# O titulo da janela didatica funciona como uma alca arrastavel.
	# Impede que o mesmo gesto mova o jardim ou selecione uma flor.
	# Clique direito em qualquer parte da janela equivale ao botao CANCELAR.
	# Para navegar na mesa, use arrasto com botao esquerdo (ou toque).
	if event is InputEventMouseButton:
		if estado_tela == "partida" and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if mobile_borda_arrastada != CELULA_INVALIDA:
				mobile_limpar_intencao()
				get_viewport().set_input_as_handled()
				return
			if animacao_setup_ativa or duplicacao_ativa:
				get_viewport().set_input_as_handled()
				return
			if indice_cenario_em_revisao >= 0:
				sair_da_revisao_visual()
			elif (aprender_ativo() or tutorial_novo_ativo()) and tutorial_passo_consulta >= 1:
				mostrar_instrucao_atual_tutorial()
			elif not turno_da_maquina():
				if (versao_nova or eh_gamer()) and acao_nova != "" and etapa_fada == "":
					cancelar_acao_nova()
				elif versao_nova and etapa_fada in ["magia", "pagar_diagonal", "cor_nova"]:
					cancelar_poder_novo()
				else:
					cancelar_movimento()
			get_viewport().set_input_as_handled()

func navegar_camera_durante_turno_maquina(event: InputEvent) -> void:
	# A maquina controla as pecas, mas o jogador continua controlando a
	# CAMERA: arrastar a mesa, usar a roda do mouse e os botoes de zoom.
	# Os mesmos cliques nunca compram cartas nem movimentam flores ou fadas.
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		if toque_tabuleiro:
			if event.position.distance_to(inicio_toque) > 11.0:
				toque_arrastou = true
			if toque_arrastou:
				mobile_camera_manual()
				deslocamento += event.position - ultimo_toque
			ultimo_toque = event.position
		if area_tabuleiro.has_point(mouse_pos):
			celula_mouse = celula_na_posicao(mouse_pos)
		else:
			celula_mouse = Vector2i(99999, 99999)
		queue_redraw()
		return

	var clique: InputEventMouseButton = event as InputEventMouseButton
	if clique == null:
		return
	mouse_pos = clique.position
	if clique.pressed and area_tabuleiro.has_point(clique.position):
		if clique.button_index == MOUSE_BUTTON_WHEEL_UP:
			mudar_zoom(1.1, clique.position)
			return
		if clique.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			mudar_zoom(1.0 / 1.1, clique.position)
			return
	if clique.button_index != MOUSE_BUTTON_LEFT:
		return
	if not clique.pressed:
		# Nunca executar a jogada no mouse-up da navegacao.
		toque_tabuleiro = false
		toque_arrastou = false
		queue_redraw()
		return

	if botao_novo.has_point(clique.position):
		voltar_inicio()
	elif area_tabuleiro.has_point(clique.position):
		toque_tabuleiro = true
		toque_arrastou = false
		inicio_toque = clique.position
		ultimo_toque = clique.position
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if aula_aviso_licao_ativo() or aula_aviso_fada_ativo() or aula_nav_indice >= 0:
		return
	if escolha_objetivo_ativa or escolhas_iniciais_pendentes:
		return
	atualizar_layout(false)
	if interface_compacta and gesto_multitoque_ativo and event is InputEventMouseButton:
		return
	if estado_tela != "partida":
		return
	if tutorial_final_pendente:
		# A tela final tem apenas duas escolhas. Nao tocar na mesa ao fundo.
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if botao_novo.has_point(event.position):
				abrir_menu_ao_pedir_novo_jogo()
		return
	if animacao_setup_ativa:
		# Durante a abertura, apenas os comandos de encerramento respondem.
		# Isto impede cartas e fadas de serem manipuladas antes de chegar.
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if botao_novo.has_point(event.position):
				abrir_menu_ao_pedir_novo_jogo()
		return
	if animacao_compra_ativa or not juice_plantar.is_empty() or not juice_repor.is_empty():
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and botao_novo.has_point(event.position):
			abrir_menu_ao_pedir_novo_jogo()
		if event is InputEventMouseButton and not event.pressed:
			toque_tabuleiro = false
			toque_arrastou = false
		return
	# Mesmo quando a maquina esta analisando, andando ou polinizando,
	# a camera e livre. Apenas as acoes sobre as pecas ficam bloqueadas.
	if turno_da_maquina():
		navegar_camera_durante_turno_maquina(event)
		return
	if (aprender_ativo() or tutorial_novo_ativo()) and tutorial_passo_consulta >= 1:
		# Modo de consulta: comandos globais continuam acessiveis, mas
		# nao se pode plantar/comprar enquanto estiver lendo etapas antigas.
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if botao_novo.has_point(event.position):
					abrir_menu_ao_pedir_novo_jogo()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP and area_tabuleiro.has_point(event.position):
				mudar_zoom(1.1, event.position)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and area_tabuleiro.has_point(event.position):
				mudar_zoom(1.0 / 1.1, event.position)
		return
	if indice_cenario_em_revisao >= 0:
		# O historico e SOMENTE visual. Os comandos globais permanecem ativos,
		# e qualquer clique esquerdo na mesa equivale a pressionar "Atual".
		# O clique que sai da revisao nao executa uma jogada simultaneamente.
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if botao_novo.has_point(event.position):
					sair_da_revisao_visual()
					abrir_menu_ao_pedir_novo_jogo()
					return
				if area_tabuleiro.has_point(event.position):
					sair_da_revisao_visual()
					return
			if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP and area_tabuleiro.has_point(event.position):
				mudar_zoom(1.1, event.position)
			elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and area_tabuleiro.has_point(event.position):
				mudar_zoom(1.0 / 1.1, event.position)
		return
	# Etapa 9: a unica acao didatica e girar o objetivo assinalado.
	# Nao avanca um turno, nao compra cartas e nao movimenta flores.
	if duplicacao_ativa:
		# Manter a camera acessivel sem aceitar novas jogadas durante o bonus.
		navegar_camera_durante_turno_maquina(event)
		return
	if etapa_fada == "movendo" or celebracao_objetivo_ativa:
		return
	# Compra e cancelamento podem ocorrer durante 1 segundo; o tabuleiro
	# permanece bloqueado ate terminar o deslocamento.
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		# Iniciar numa casa válida com carta na mão ajusta a prévia.
		# Iniciar em outro lugar continua permitindo arrastar a câmera.
		if toque_tabuleiro:
			if not mobile_ajustando_plantio:
				if event.position.distance_to(inicio_toque) > 11.0:
					toque_arrastou = true
				if toque_arrastou:
					mobile_camera_manual()
					deslocamento += event.position - ultimo_toque
			ultimo_toque = event.position

		if area_tabuleiro.has_point(mouse_pos):
			celula_mouse = celula_na_posicao(mouse_pos)
		else:
			celula_mouse = Vector2i(99999, 99999)
		queue_redraw()
		return

	if event is InputEventMouseButton:
		mouse_pos = event.position

		if area_tabuleiro.has_point(event.position) and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				mudar_zoom(1.1, event.position)
				return
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				mudar_zoom(1.0 / 1.1, event.position)
				return

		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if not event.pressed:
			# Soltar sobre uma casa inválida cancela só a intenção, não a compra.
			var mesmo_turno: bool = mobile_token_tabuleiro == identificador_partida and mobile_turno_tabuleiro == turnos_jogados
			if toque_tabuleiro and not toque_arrastou and mesmo_turno and mobile_contexto_jogavel() and area_tabuleiro.has_point(event.position):
				var casa_final: Vector2i = celula_na_posicao(event.position)
				var confirmada: bool = not mobile_ajustando_plantio or mobile_pode_prever_plantio(casa_final)
				if etapa_fada in ["oferta", "escolha"]:
					# Um pequeno deslizamento não troca a fada por uma recusa acidental.
					confirmada = casa_final == mobile_casa_pressionada and indice_fada_clicada(event.position) == mobile_fada_pressionada
				if confirmada and not aguardando_reposicao_automatica:
					executar_acao_no_tabuleiro(casa_final, event.position)
			mobile_limpar_intencao()
			return

		if botao_novo.has_point(event.position):
			abrir_menu_ao_pedir_novo_jogo()
		elif mobile_contexto_jogavel() and armar_giro_objetivo(event.position):
			return
		elif mobile_contexto_jogavel() and area_mao.has_point(event.position) and flor_na_mao != "" and etapa_fada == "" and not modo_movimento and not movimento_pendente and not aguardando_reposicao_automatica and origem_selecionada == CELULA_INVALIDA and acao_nova in ["", "plantar"] and (not aula_guiada_ativa() or aula_demonstracao_ativa()):
			mobile_arrastando_mao = true
			feel_retorno.clear()
			feel_pos = area_mao.get_center()
			feel_alvo = feel_pos
			feel_angulo = 0.0
			feel_inclinacao_alvo = 0.0
			mobile_ajustando_plantio = true
			mobile_token_tabuleiro = identificador_partida
			mobile_turno_tabuleiro = turnos_jogados
			queue_redraw()
			return
		elif mobile_contexto_jogavel() and area_objetivos.has_point(event.position):
			var cartas_consulta: Array[Dictionary] = jogadores[jogador_atual]["objetivos"]
			for i in range(cartas_consulta.size()):
				if not cartas_consulta[i].is_empty() and retangulo_objetivo_ativo(i).has_point(event.position):
					mobile_objetivo_press = i
					break
			return
		elif mobile_area_fonte(true).has_point(event.position):
			mouse_pos = event.position
			mobile_armar_compra(true)
		elif mobile_area_fonte(false).has_point(event.position):
			mobile_armar_compra(false)
		elif area_tabuleiro.has_point(event.position) and not aguardando_reposicao_automatica and not turno_da_maquina():
			toque_tabuleiro = true
			toque_arrastou = false
			inicio_toque = event.position
			ultimo_toque = event.position
			mobile_token_tabuleiro = identificador_partida
			mobile_turno_tabuleiro = turnos_jogados
			mobile_casa_pressionada = celula_na_posicao(event.position)
			mobile_fada_pressionada = indice_fada_clicada(event.position) if etapa_fada in ["oferta", "escolha"] else -1
			mobile_ajustando_plantio = mobile_pode_prever_plantio(mobile_casa_pressionada)
			queue_redraw()

# v172: hierarquia tipográfica e superfícies reutilizáveis.
func ui_fonte_para(cor: Color, tamanho: int) -> Font:
	if (cor == COR_OURO or cor == COR_PRATA or cor == COR_PRATA_BRILHO) and tamanho >= 16 and fonte_destaque != null:
		return fonte_destaque
	return fonte

# Preserva a fonte e o alinhamento do texto; apenas o símbolo de pontos muda de cor.
func escrever_com_estrela_prateada(canvas: CanvasItem, fonte_texto: Font, texto: String, p: Vector2, tamanho: int, cor: Color, largura: float = -1.0) -> void:
	if not texto.contains(ICONE_ESTRELA_VITORIA) or cor == COR_PRATA:
		canvas.draw_string(fonte_texto, p, texto, HORIZONTAL_ALIGNMENT_LEFT, largura, tamanho, cor)
		return
	var inicio: int = 0
	var indice: int = texto.find(ICONE_ESTRELA_VITORIA)
	while indice >= 0:
		var trecho: String = texto.substr(inicio, indice - inicio)
		var x: float = fonte_texto.get_string_size(texto.substr(0, inicio), HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
		if not trecho.is_empty():
			canvas.draw_string(fonte_texto, p + Vector2(x, 0.0), trecho, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)
		var x_estrela: float = fonte_texto.get_string_size(texto.substr(0, indice), HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
		canvas.draw_string(fonte_texto, p + Vector2(x_estrela, 0.0), ICONE_ESTRELA_VITORIA, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, Color(COR_PRATA, cor.a))
		inicio = indice + ICONE_ESTRELA_VITORIA.length()
		indice = texto.find(ICONE_ESTRELA_VITORIA, inicio)
	if inicio < texto.length():
		var x_final: float = fonte_texto.get_string_size(texto.substr(0, inicio), HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
		canvas.draw_string(fonte_texto, p + Vector2(x_final, 0.0), texto.substr(inicio), HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)

func escrever(texto: String, p: Vector2, tamanho: int = 16, cor: Color = COR_TEXTO) -> void:
	escrever_com_estrela_prateada(self, ui_fonte_para(cor, tamanho), texto, p, tamanho, cor)

func rotulo_estrela_compacto(valor: int) -> String:
	return "%s %d" % [ICONE_ESTRELA_VITORIA, valor]

func rotulo_estrelas_texto(valor: int) -> String:
	return "%d estrela" % valor if valor == 1 else "%d estrelas" % valor

func ui_superficie(r: Rect2, preenchimento: Color, borda: Color, raio: int = 8, sombra: bool = false) -> void:
	if not r.has_area():
		return
	var chave: String = "%s:%s:%d:%s:%s" % [preenchimento.to_html(), borda.to_html(), raio, str(sombra), str(r.size.y >= 34.0)]
	if not _ui_paineis.has(chave):
		var estilo: StyleBoxFlat = StyleBoxFlat.new()
		estilo.bg_color = preenchimento
		estilo.border_color = borda
		estilo.set_border_width_all(1)
		estilo.set_corner_radius_all(raio)
		estilo.corner_detail = 7
		estilo.anti_aliasing = true
		if sombra:
			estilo.shadow_color = Color(0.045, 0.025, 0.015, 0.48)
			estilo.shadow_size = 4
			estilo.shadow_offset = Vector2(0, 2)
		_ui_paineis[chave] = estilo
	draw_style_box(_ui_paineis[chave], r)


func retangulo(r: Rect2, preenchimento: Color, borda: Color) -> void:
	ui_superficie(r, preenchimento, borda, 6)

func desenhar_botao_arredondado(r: Rect2) -> void:
	var pressionado: bool = r.has_point(juice_ultima_pressao) and juice_relogio - juice_pressao_tempo < 0.12
	var hover: bool = r.has_point(mouse_pos)
	var r_visual: Rect2 = Rect2(r.position + Vector2(0.0, 1.5 if pressionado else 0.0), r.size - Vector2(0.0, 1.5 if pressionado else 0.0))
	var preenchimento: Color = UI_ACAO_PRESSIONADA if pressionado else (UI_ACAO_HOVER if hover else UI_ACAO)
	var borda: Color = Color("f0d8a8") if hover else Color("be9e69")
	ui_superficie(r_visual, preenchimento, borda, 12, true)

# Para os botoes desenhados no CanvasItem, centralizar pelo centro geometricamente
# correto em ambos os eixos, em vez de offsets fixos que variam por dispositivo.
func escrever_texto_botao_centralizado(texto: String, area: Rect2, tamanho: int) -> void:
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return
	if texto == "X":
		var c: Vector2 = area.get_center()
		var d: float = minf(6.0, minf(area.size.x, area.size.y) * 0.22)
		draw_line(c - Vector2(d, d), c + Vector2(d, d), COR_TEXTO, 1.8, true)
		draw_line(c + Vector2(-d, d), c + Vector2(d, -d), COR_TEXTO, 1.8, true)
		return
	var fonte_botao: int = tamanho
	var largura_maxima: float = maxf(8.0, area.size.x - 9.0)
	while fonte_botao > 8 and fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, fonte_botao).x > largura_maxima:
		fonte_botao -= 1
	var linha_base: float = area.get_center().y + (fonte.get_ascent(fonte_botao) - fonte.get_descent(fonte_botao)) * 0.5
	escrever_centralizado(texto, area.get_center().x, linha_base, fonte_botao, COR_TEXTO)

func pintura_aguardando_cor() -> bool:
	return versao_nova and estado_tela == "partida" and not partida_encerrada and \
		(acao_nova == "pintar_cor" or etapa_fada == "cor_nova") and \
		alvo_transformacao != CELULA_INVALIDA and tabuleiro.has(alvo_transformacao)

func atualizar_geometria_seletor_pintura() -> void:
	escolhas_flores_pintura.clear()
	janela_pintura_retangulo = Rect2()
	if not pintura_aguardando_cor():
		return
	var tela: Vector2 = get_viewport_rect().size
	var largura: float = minf(282.0, tela.x - 24.0)
	var altura: float = 151.0
	var centro_mesa: Vector2 = area_tabuleiro.get_center()
	var posicao: Vector2 = Vector2(
		clampf(centro_mesa.x - largura * 0.5, 8.0, maxf(8.0, tela.x - largura - 8.0)),
		clampf(area_tabuleiro.position.y + 12.0, 9.0, maxf(9.0, tela.y - altura - 9.0)))
	janela_pintura_retangulo = Rect2(posicao, Vector2(largura, altura))
	var alternativas: Array[String] = []
	for cor in CORES:
		if cor != str(tabuleiro[alvo_transformacao]):
			alternativas.append(cor)
	for indice in range(alternativas.size()):
		var lado: float = minf(70.0, (largura - 40.0) * 0.42)
		var centro_x: float = posicao.x + largura * (0.31 if indice == 0 else 0.69)
		var centro_y: float = posicao.y + 88.0
		escolhas_flores_pintura[alternativas[indice]] = Rect2(
			Vector2(centro_x - lado * 0.5, centro_y - lado * 0.5), Vector2.ONE * lado)

func desenhar_seletor_pintura() -> void:
	atualizar_geometria_seletor_pintura()
	if janela_pintura_retangulo.size.x <= 0.0:
		return
	var janela: Rect2 = janela_pintura_retangulo
	draw_rect(janela.grow(4.0), Color(0.04, 0.06, 0.07, 0.36))
	draw_rect(janela, Color(0.17, 0.13, 0.11, 0.98))
	draw_rect(janela, Color(0.33, 0.70, 1.0, 0.93), false, 2.2)
	draw_rect(Rect2(janela.position, Vector2(janela.size.x, 34.0)), Color(0.19, 0.29, 0.36, 0.95))
	escrever_ajustado("QUAL A NOVA COR?", janela.position.x + 13.0,
		janela.position.y + 24.0, janela.size.x - 22.0, 15, Color("a6d8ff"))
	for cor in escolhas_flores_pintura:
		var r: Rect2 = escolhas_flores_pintura[cor]
		var bloqueada: bool = tutorial_novo_ativo() and passo_tutorial_novo() == 10 and str(cor) == "vermelha"
		var hover: bool = r.has_point(mouse_pos) and not bloqueada
		draw_rect(r, Color(0.24, 0.24, 0.24, 0.92) if bloqueada else Color(0.30, 0.43, 0.33, 0.98))
		draw_rect(r.grow(3.0), Color(0.32, 0.77, 1.0, 0.96) if hover else Color(0.59, 0.53, 0.40, 0.78), false, 3.5 if hover else 1.5)
		desenhar_flor(r.get_center() + Vector2(0, -5), r.size.x * 0.36, cor)
		if bloqueada:
			draw_rect(r.grow(1.0), Color(0.11, 0.11, 0.11, 0.52))
		var legenda: String = nome_cor(str(cor)).capitalize()
		var largura_texto: float = fonte.get_string_size(legenda, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		escrever(legenda, Vector2(r.get_center().x - largura_texto * 0.5,
			r.end.y + 13.0), 12, COR_TEXTO)

func desenhar_flor(centro: Vector2, raio: float, nome: String, abertura: float = 1.0, vento: float = 0.0, alfa: float = 1.0, simbolo_objetivo: bool = false) -> void:
	if not PERF_FLORES.has(nome):
		return
	# Mesma ilustração em repouso, prévia e florescimento; sem trocar o desenho.
	var escala: float = clampf(abertura, 0.08, 1.22)
	var lado: float = raio * 2.4 * escala
	var pos: Vector2 = centro + Vector2(clampf(vento, -1.0, 1.0) * raio * 0.12, 0.0)
	var textura: Texture2D = PERF_FLORES[nome]
	var modulacao: Color = cor_modulada_objetivo(nome) if simbolo_objetivo else Color.WHITE
	modulacao.a = clampf(alfa, 0.0, 1.0)
	draw_texture_rect(textura, Rect2(pos - Vector2.ONE * lado * 0.5, Vector2.ONE * lado), false, modulacao)

func desenhar_grama_discreta_em_carta(area: Rect2, alfa: float = 1.0) -> void:
	var passo_x: float = maxf(9.0, area.size.x / 5.2)
	var passo_y: float = maxf(9.0, area.size.y / 5.2)
	var cor_grama_1: Color = Color(0.20, 0.42, 0.13, 0.17 * alfa)
	var cor_grama_2: Color = Color(0.16, 0.36, 0.11, 0.22 * alfa)
	var y: float = area.position.y + passo_y * 0.65
	var linha: int = 0
	while y < area.end.y - passo_y * 0.18:
		var x: float = area.position.x + (0.32 if linha % 2 == 0 else 0.68) * passo_x
		while x < area.end.x - passo_x * 0.18:
			var base: Vector2 = Vector2(x, y + passo_y * 0.18)
			draw_line(base, base + Vector2(-passo_x * 0.10, -passo_y * 0.34), cor_grama_1, 1.0)
			draw_line(base, base + Vector2(passo_x * 0.06, -passo_y * 0.41), cor_grama_2, 1.0)
			x += passo_x
		y += passo_y
		linha += 1

func desenhar_carta(centro: Vector2, lado: float, tipo: String, alfa: float = 1.0, recortar_mesa: bool = false, flor_abertura: float = 1.0, flor_vento: float = 0.0) -> void:
	# Uma carta na borda do jardim continua visivel, mesmo parcialmente.
	# So o gramado e recortado na area util; as cartas do painel de compra
	# continuam inteiras, porque sao desenhadas com recortar_mesa = false.
	var r: Rect2 = Rect2(centro - Vector2.ONE * lado * 0.5, Vector2.ONE * lado)
	var area_verde: Rect2 = r.intersection(area_tabuleiro) if recortar_mesa else r
	if not area_verde.has_area():
		return
	# Cartas inteiras e opacas: uma textura substitui dezenas de traços.
	# O recorte parcial e a prévia transparente conservam o desenho original.
	var grama: int = 0 if lado < 68.0 else (1 if lado < 136.0 else 2)
	var textura_grama: Texture2D = PERF_GRAMA[grama]
	var modulacao: Color = Color(1.0, 1.0, 1.0, alfa)
	if area_verde == r:
		draw_texture_rect(textura_grama, area_verde, false, modulacao)
	else:
		var proporcao: Vector2 = textura_grama.get_size() / r.size
		var recorte: Rect2 = Rect2((area_verde.position - r.position) * proporcao, area_verde.size * proporcao)
		draw_texture_rect_region(textura_grama, area_verde, recorte, modulacao)
	if CORES.has(tipo):
		desenhar_flor(centro - Vector2(0.0, lado * 0.035), lado * 0.34, tipo, flor_abertura, flor_vento, alfa)

func fadas_na_mesma_casa(casa: Vector2i) -> Array[int]:
	var lista: Array[int] = []
	for indice in range(fadas.size()):
		if fadas[indice]["casa"] == casa:
			lista.append(indice)
	return lista

func posicionar_fadas_em_duas_fileiras_na_casa_central(indice_fada: int) -> bool:
	# A regra vale nas partidas contra 2 ou 3 maquinas quando as fadas ainda estao
	# na carta central. Em 3 jogadores totais, o humano (fadas brancas) fica sozinho
	# na fileira superior e as outras 4 fadas ficam na inferior.
	return (modo_partida == "maquina" and quantidade_jogadores() >= 3
		and fadas[indice_fada]["casa"] == Vector2i.ZERO)

func escala_fada_na_casa(indice_fada: int) -> float:
	var lado: float = tamanho_carta_base_jardim() * zoom
	var largura_png_por_escala: float = 2.60 * 420.0 / 531.0
	var espaco_referencia: float = lado * 0.86 / 4.0
	var escala_anterior: float = minf(lado * 0.22, espaco_referencia / largura_png_por_escala)
	if posicionar_fadas_em_duas_fileiras_na_casa_central(indice_fada):
		# Em 3 jogadores totais: topo com 2 fadas brancas, base com 4 fadas rivais.
		# Em 4 jogadores totais: 4 em cima e 4 embaixo.
		return escala_anterior * 1.25 * (0.80 if quantidade_jogadores() == 3 else 0.88)
	var total: int = fadas_na_mesma_casa(fadas[indice_fada]["casa"]).size()
	var ajuste: float = 1.0
	if total > 4:
		ajuste = lerpf(1.0, 0.76, clampf(float(total - 4) / 4.0, 0.0, 1.0))
	return escala_anterior * 1.25 * ajuste

func centro_visual_da_fada(indice_fada: int) -> Vector2:
	var casa: Vector2i = fadas[indice_fada]["casa"]
	var centro_carta: Vector2 = posicao_celula(casa)
	var lista: Array[int] = fadas_na_mesma_casa(casa)
	var lado: float = tamanho_carta_base_jardim() * zoom
	if posicionar_fadas_em_duas_fileiras_na_casa_central(indice_fada):
		var dono_fada: int = int(fadas[indice_fada]["dono"])
		var linha_superior: bool = (dono_fada == 0) if quantidade_jogadores() == 3 else (dono_fada <= 1)
		var mesma_fileira: Array[int] = []
		for outro_indice in lista:
			var dono_outro: int = int(fadas[outro_indice]["dono"])
			var grupo_superior: bool = (dono_outro == 0) if quantidade_jogadores() == 3 else (dono_outro <= 1)
			if grupo_superior == linha_superior:
				mesma_fileira.append(outro_indice)
		var posicao_na_fileira: int = mesma_fileira.find(indice_fada)
		var total_fileira: int = mesma_fileira.size()
		var divisor: float = 2.7 if quantidade_jogadores() == 3 and linha_superior else 4.0
		var distancia: float = lado * 0.94 / divisor
		var x_fileira: float = centro_carta.x + (float(posicao_na_fileira) - float(total_fileira - 1) * 0.5) * distancia
		var y_fileira: float = centro_carta.y + lado * (-0.245 if linha_superior else 0.245)
		return Vector2(x_fileira, y_fileira)
	# Posicionamento original para as outras casas e modalidades.
	var indice_local: int = lista.find(indice_fada)
	var total: int = lista.size()
	var espaco_por_fada: float = lado * 0.94 / maxf(4.0, float(total))
	var x: float = centro_carta.x + (float(indice_local) - float(total - 1) * 0.5) * espaco_por_fada
	var altura_png: float = escala_fada_na_casa(indice_fada) * 2.60
	var y: float = centro_carta.y + lado * 0.455 - altura_png * 0.5
	return Vector2(x, y)

func indice_fada_sob_mouse(posicao: Vector2) -> int:
	# A região sensível ao hover acompanha a forma do PNG transparente,
	# evitando acender fadas apenas por aproximar o cursor de um círculo.
	if estado_tela != "partida" or not area_tabuleiro.has_point(posicao):
		return -1
	if etapa_fada in ["oferta", "escolha"]:
		return indice_fada_clicada(posicao)
	var indice_proximo: int = -1
	var distancia_proxima: float = INF
	for i in range(fadas.size()):
		var centro: Vector2 = centro_visual_da_fada(i)
		var escala: float = escala_fada_na_casa(i)
		var indice_png: int = indice_textura_por_jogador(int(fadas[i]["dono"]))
		var imagem: Image = imagens_fadas_para_hit_test.get(indice_png) as Image
		var tem_toque: bool = false
		if imagem != null:
			var altura: float = escala * 2.60
			var largura: float = altura * float(imagem.get_width()) / maxf(1.0, float(imagem.get_height()))
			var rect: Rect2 = Rect2(centro - Vector2(largura, altura) * 0.5, Vector2(largura, altura))
			if rect.has_point(posicao):
				var relativo: Vector2 = (posicao - rect.position) / rect.size
				var px: int = clampi(int(relativo.x * imagem.get_width()), 0, imagem.get_width() - 1)
				var py: int = clampi(int(relativo.y * imagem.get_height()), 0, imagem.get_height() - 1)
				tem_toque = imagem.get_pixel(px, py).a >= 0.18
		else:
			tem_toque = posicao.distance_to(centro) <= maxf(5.0, escala * 1.20)
		if tem_toque:
			var distancia: float = posicao.distance_squared_to(centro)
			if distancia < distancia_proxima:
				indice_proximo = i
				distancia_proxima = distancia
	return indice_proximo

func desenhar_contorno_silhueta_fada(mascara: Texture2D, rect: Rect2, escala: float) -> void:
	# O mesmo brilho azul é usado em hover e em todas as escolhas de fada.
	# Camadas translúcidas deslocadas por alguns pixels reproduzem o contorno
	# das asas e do corpo. A imagem original será desenhada sobre elas.
	var pulso: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.006)
	var raio: float = maxf(2.0, escala * 0.24)
	var brilho: Color = Color(0.15, 0.56, 1.0, 0.17 + pulso * 0.07)
	var borda: Color = Color(0.18, 0.69, 1.0, 0.62 + pulso * 0.26)
	for angulo_i in range(8):
		var direcao: Vector2 = Vector2.RIGHT.rotated(float(angulo_i) * TAU / 8.0)
		draw_texture_rect(mascara, Rect2(rect.position + direcao * raio * 1.9, rect.size), false, brilho)
		draw_texture_rect(mascara, Rect2(rect.position + direcao * raio, rect.size), false, borda)

func indice_fada_do_jogador_clicada(posicao: Vector2) -> int:
	# Atalho para poderes. Aceita apenas o clique na miniatura da fada do jogador.
	var melhor: int = -1
	var distancia_menor: float = INF
	for i in range(fadas.size()):
		if int(fadas[i]["dono"]) != jogador_atual:
			continue
		var alcance: float = maxf(6.0, escala_fada_na_casa(i) * 1.35)
		var distancia: float = posicao.distance_to(centro_visual_da_fada(i))
		if distancia <= alcance and distancia < distancia_menor:
			melhor = i
			distancia_menor = distancia
	return melhor

func indice_fada_clicada(posicao: Vector2) -> int:
	# Alvo de toque: a carta inteira. Quando duas fadas elegíveis dividem
	# uma casa, escolhemos a miniatura mais próxima do ponto tocado.
	if not area_tabuleiro.has_point(posicao):
		return -1
	var casa_tocada: Vector2i = celula_na_posicao(posicao)
	var escolhida: int = -1
	var menor_distancia: float = INF
	var candidatas: Array[int] = fadas_elegiveis.duplicate()
	for indice in candidatas:
		if indice < 0 or indice >= fadas.size() or fadas[indice]["casa"] != casa_tocada:
			continue
		var distancia: float = posicao.distance_squared_to(centro_visual_da_fada(indice))
		if distancia < menor_distancia:
			menor_distancia = distancia
			escolhida = indice
	return escolhida

# Velocidade constante entre as flores, com rampas curtas somente nos extremos.
func voo_progresso_espacial(t: float, passos: int) -> float:
	t = clampf(t, 0.0, 1.0)
	var rampa: float = minf(0.18, 0.22 / float(maxi(1, passos)))
	var normalizar: float = 1.0 - rampa
	if t < rampa:
		return t * t / (2.0 * rampa * normalizar)
	if t > 1.0 - rampa:
		return 1.0 - (1.0 - t) * (1.0 - t) / (2.0 * rampa * normalizar)
	return (t - rampa * 0.5) / normalizar

func desenhar_fada_com_asas(indice_textura: int, r: Rect2, flutter: float) -> void:
	var camadas: Array = texturas_fadas_voo[indice_textura]
	var corpo: Texture2D = camadas[0]
	var esquerda: Texture2D = camadas[1]
	var direita: Texture2D = camadas[2]
	# A raiz das asas permanece atrás do corpo. Só as asas se fecham;
	# a cabeça e o corpo não se deformam, nem mudam de cor.
	var largura: float = r.size.x * flutter
	var re: Rect2 = Rect2(Vector2(r.get_center().x - largura * 0.5, r.position.y), Vector2(largura, r.size.y))
	draw_texture_rect(esquerda, re, false)
	draw_texture_rect(direita, re, false)
	draw_texture_rect(corpo, r, false)

func desenhar_fada_miniatura(indice_fada: int, destacar: bool = false, fator_entrada: float = 1.0) -> void:
	# Ilustracoes PNG sem fundo, com escala fixa igual a quatro fadas no centro.
	var fada: Dictionary = fadas[indice_fada]
	var indice_jogador: int = int(fada["dono"])
	var numero: int = int(fada["numero"])
	var centro: Vector2 = juice_posicao_sobre_carta(fada["casa"], centro_visual_da_fada(indice_fada))
	var escala: float = escala_fada_na_casa(indice_fada) * fator_entrada
	var flutter: float = 1.0
	var inclinacao: float = 0.0
	var visual_ativo: bool = indice_cenario_em_revisao < 0 and not partida_encerrada and not animacao_setup_ativa
	var intensidade: float = [0.55, 1.0, 1.12][juice_nivel]
	var em_voo: bool = visual_ativo and int(juice_voo.get("indice", -1)) == indice_fada
	if visual_ativo and not em_voo:
		# Prontidão de todas as fadas elegíveis, sem mudar a área de clique.
		# Ao recusar (ou escolher outra fada), a amplitude decai até o repouso.
		var pronta: float = float(juice_fada_prontidao.get(indice_fada, 0.0))
		var onda_pronta: float = 0.5 + 0.5 * cos(juice_relogio * TAU * 2.6 + float(indice_fada) * 1.7)
		flutter = 1.0 - 0.22 * pronta * onda_pronta * intensidade
		if pronta > 0.0 and destino_da_fada != CELULA_INVALIDA:
			var rumo: Vector2 = Vector2(destino_da_fada - fada["casa"]).normalized()
			inclinacao = rumo.x * 0.10 * pronta
			centro += rumo * escala * 0.08 * pronta
		else:
			var repouso: float = juice_relogio * 1.7 + float(indice_fada) * 2.13
			inclinacao = 0.018 * sin(repouso)
			flutter = 1.0 - 0.045 * pow(maxf(0.0, sin(repouso * 0.72)), 6.0)
		if not juice_mover.is_empty() and fada["casa"] == juice_mover.get("destino"):
			# A fada conserva os pés sobre a carta e compensa a aceleração/frenagem.
			var t_carta: float = juice_progresso(juice_mover)
			var direcao_carta: Vector2 = Vector2(juice_mover["destino"] - juice_mover["origem"]).normalized()
			var trajeto: float = clampf(t_carta / 0.78, 0.0, 1.0)
			var acomodar: float = clampf((t_carta - 0.78) / 0.22, 0.0, 1.0)
			# Contrapeso visível na aceleração e na frenagem; pequena correção final.
			var compensar: float = -sin(trajeto * TAU) * sin(trajeto * PI)
			compensar += 0.40 * sin(acomodar * TAU) * (1.0 - acomodar)
			inclinacao = compensar * (direcao_carta.x * 0.39 + direcao_carta.y * 0.18) * intensidade + juice_inclinacao_carta(fada["casa"]) * 0.65
			var esforco: float = sin(t_carta * PI)
			var batida_equilibrio: float = 0.5 + 0.5 * cos(t_carta * TAU * 3.0 + float(indice_fada) * 0.6)
			flutter = minf(flutter, 1.0 - 0.32 * esforco * batida_equilibrio * intensidade)
	if em_voo:
		var t_voo: float = juice_progresso(juice_voo)
		var fase: String = str(juice_voo["fase"])
		var andando: bool = fase == "viajar"
		var t_pos: float = voo_progresso_espacial(t_voo, int(juice_voo["total"])) if andando else 0.0
		var rota: float = t_pos if andando else (1.0 if fase == "pousar" else 0.0)
		var lado: float = tamanho_carta_base_jardim() * zoom
		var oi: Vector2 = juice_voo["offset_inicio"]
		var of: Vector2 = juice_voo["offset_fim"]
		var solo: Vector2 = posicao_celula(juice_voo["origem"]).lerp(posicao_celula(juice_voo["destino"]), t_pos) + oi.lerp(of, rota) * lado
		escala = lerpf(float(juice_voo["escala_inicio"]), float(juice_voo["escala_fim"]), rota) * lado
		var altura_voo: float = 1.0
		var amplitude_asas: float = 0.36
		var direcao_voo: Vector2 = juice_voo.get("direcao", Vector2.ZERO)
		var impulso: float = 1.0
		var antecipacao: float = 0.0
		if fase == "decolar":
			# Primeiro inclina, então ganha altura; não há salto inicial.
			antecipacao = interpolar_suave(t_voo / 0.32)
			altura_voo = interpolar_suave((t_voo - 0.30) / 0.70)
			impulso = antecipacao * lerpf(1.0, 0.32, interpolar_suave((t_voo - 0.35) / 0.65))
			amplitude_asas = lerpf(0.17 * float(juice_voo.get("prontidao_inicial", 0.0)), 0.36, interpolar_suave(t_voo))
		elif fase == "pousar":
			altura_voo = 1.0 - interpolar_suave(t_voo / 0.80)
			impulso = 0.32 * (1.0 - interpolar_suave(t_voo))
			# Asas continuam a bater suavemente até se acomodarem no repouso.
			amplitude_asas = 0.36 * (1.0 - interpolar_suave(t_voo))
		if andando:
			# Inclinação proporcional à aceleração e ao sentido do trajeto.
			var rampa: float = minf(0.18, 0.22 / float(maxi(1, int(juice_voo["total"]))))
			var acelerar: float = interpolar_suave(t_voo / rampa)
			var frear: float = 1.0 - interpolar_suave((t_voo - (1.0 - rampa)) / rampa)
			impulso = 0.32 + 0.68 * acelerar * frear
		var fase_asas: float = float(juice_voo.get("fase_asas", 0.0))
		var batida: float = 0.5 + 0.5 * cos(fase_asas)
		flutter = 1.0 - amplitude_asas * batida * intensidade
		inclinacao = direcao_voo.x * 0.21 * impulso * intensidade
		# Nos trajetos verticais, a inclinação é sugerida por avanço do corpo.
		var avanco: Vector2 = direcao_voo * escala * 0.12 * impulso * intensidade
		var tempo_asas: float = juice_relogio - float(juice_voo["inicio_global"])
		centro = solo + avanco + Vector2(0.0, -escala * altura_voo * (0.90 + 0.055 * sin(tempo_asas * TAU * 3.75)))
		if fase == "pousar":
			# Pequeno ajuste de postura ao tocar a flor, com retorno exato à posição estática.
			var acomodar: float = clampf((t_voo - 0.80) / 0.20, 0.0, 1.0)
			inclinacao -= direcao_voo.x * 0.065 * sin(acomodar * PI) * intensidade
			centro.y += escala * 0.055 * sin(acomodar * PI)
		# Sombra separada no chão: a miniatura fica suspensa em todas as flores.
		draw_circle(solo + Vector2(0.0, escala * 0.91), escala * (0.46 - altura_voo * 0.08), Color(0.10, 0.08, 0.06, 0.13 + 0.06 * altura_voo))
		if andando:
			var quantidade_rastro: int = 4 if juice_nivel == 0 or v209_leve else 10
			for i in range(quantidade_rastro):
				var rastro_t: float = t_pos - float(i + 1) * 0.038 / float(maxi(1, int(juice_voo["total"])))
				if rastro_t < 0.0:
					continue
				var rastro: Vector2 = posicao_celula(juice_voo["origem"]).lerp(posicao_celula(juice_voo["destino"]), rastro_t) + oi.lerp(of, rastro_t) * lado
				rastro += Vector2(sin(float(i) * 2.4 + juice_relogio * 5.0) * escala * 0.15, -escala * 0.82)
				if not area_tabuleiro.grow(-4.0).has_point(rastro):
					continue
				var brilho: float = (0.38 + minf(0.25, float(registro_voo_fada.get("coletados", 0)) * 0.035)) * (1.0 - float(i) / float(quantidade_rastro))
				var raio_rastro: float = maxf(0.8, escala * 0.10) * (1.0 - float(i) / float(quantidade_rastro + 2))
				draw_circle(rastro, raio_rastro * 2.1, Color(1.0, 0.82, 0.49, brilho * 0.22))
				draw_circle(rastro, raio_rastro, Color(1.0, 0.93, 0.68, brilho))
	var base: Color = cor_visual_da_fada(indice_jogador)
	var contorno: Color = Color("fff4dc") if indice_jogador == 0 else Color("38342f")
	var opacidade_asa: Color = Color("c9cdd3") if indice_jogador == 0 else Color("e6e8eb")
	# Jogador principal (indice 0): fada branca de asas cinzas.
	# Todas as outras fadas possuem asas brancas, no mesmo tom.
	# Nao usar modulacao cromatica no PNG: ela coloriria as asas.
	var indice_textura: int = indice_textura_por_jogador(indice_jogador)
	var textura: Texture2D = texturas_fadas.get(indice_textura) as Texture2D
	if textura != null:
		var altura: float = escala * 2.60
		var largura: float = altura * float(textura.get_width()) / maxf(1.0, float(textura.get_height()))
		var retangulo_png: Rect2 = Rect2(-Vector2(largura, altura) * 0.5, Vector2(largura, altura))
		var pivo: Vector2 = Vector2.ZERO if em_voo else Vector2(0.0, altura * 0.43)
		draw_set_transform(centro + pivo - pivo.rotated(inclinacao), inclinacao)
		if destacar:
			var mascara: Texture2D = mascaras_silhueta_fadas.get(indice_textura) as Texture2D
			if mascara != null:
				desenhar_contorno_silhueta_fada(mascara, retangulo_png, escala)
		if (em_voo or flutter < 0.999) and texturas_fadas_voo.has(indice_textura):
			desenhar_fada_com_asas(indice_textura, retangulo_png, flutter)
		else:
			draw_texture_rect(textura, retangulo_png, false, Color.WHITE)
		draw_set_transform(Vector2.ZERO)
		return

	# Reserva vetorial se o PNG não carregar: destaque segue asas, corpo e cabeça.
	if destacar:
		var cor_br = Color(0.26, 0.70, 1.0, 0.90)
		for lado in [-1.0, 1.0]:
			var asa: PackedVector2Array = PackedVector2Array([
				centro + Vector2(lado * escala * 0.12, -escala * 0.05),
				centro + Vector2(lado * escala * 1.32, -escala * 1.47),
				centro + Vector2(lado * escala * 1.05, escala * 0.16),
				centro + Vector2(lado * escala * 1.25, escala * 1.30)])
			draw_colored_polygon(asa, cor_br)
		draw_circle(centro + Vector2(0.0, escala * 0.20), escala * 0.86, cor_br)
		draw_circle(centro + Vector2(0.0, -escala * 0.40), escala * 0.55, cor_br)
	# Asas alongadas vistas de cima.
	for lado_asa in [-1.0, 1.0]:
		var ponta_x: float = centro.x + lado_asa * escala * 1.18 * flutter
		var asa_alta: PackedVector2Array = PackedVector2Array([
			centro + Vector2(lado_asa * escala * 0.15, -escala * 0.05),
			Vector2(ponta_x, centro.y - escala * 1.30),
			centro + Vector2(lado_asa * escala * 0.80 * flutter, escala * 0.03)
		])
		var asa_baixa: PackedVector2Array = PackedVector2Array([
			centro + Vector2(lado_asa * escala * 0.15, escala * 0.10),
			Vector2(ponta_x, centro.y + escala * 1.15),
			centro + Vector2(lado_asa * escala * 0.73 * flutter, escala * 0.08)
		])
		draw_colored_polygon(asa_alta, opacidade_asa)
		draw_colored_polygon(asa_baixa, opacidade_asa.darkened(0.045))

	# Corpo e cabeca em cor contrastante.
	draw_circle(centro + Vector2(0.0, escala * 0.20), escala * 0.72, contorno)
	draw_circle(centro + Vector2(0.0, escala * 0.20), escala * 0.53, base)
	draw_circle(centro + Vector2(0.0, -escala * 0.40), escala * 0.43, contorno)
	draw_circle(centro + Vector2(0.0, -escala * 0.40), escala * 0.30, base.lightened(0.12))
	# Simbolos pequenos identificam as duas fadas da mesma cor.
	draw_circle(centro + Vector2(0.0, escala * 0.20), maxf(1.0, escala * 0.10),
		Color("e4b86b") if numero == 1 else Color("a3d4d2"))
func desenhar_todas_as_fadas() -> void:
	var passo: float = tamanho_carta_base_jardim() * zoom
	var indice_hover: int = indice_fada_sob_mouse(mouse_pos) if not animacao_setup_ativa and not partida_encerrada and indice_cenario_em_revisao < 0 else -1
	var visiveis: int = clampi(animacao_setup_etapa - 4, 0, fadas.size()) if animacao_setup_ativa else fadas.size()
	var indice_voando: int = int(juice_voo.get("indice", -1)) if indice_cenario_em_revisao < 0 else -1
	for i in range(visiveis):
		if i == indice_voando:
			continue
		var fada: Dictionary = fadas[i]
		var centro: Vector2 = posicao_celula(fada["casa"]) + juice_desvio_carta(fada["casa"])
		var carta: Rect2 = Rect2(centro - Vector2.ONE * passo * 0.5, Vector2.ONE * passo)
		if not area_tabuleiro.grow(-1.0).intersects(carta):
			continue
		# O recurso de destaque antes usado apenas na escolha de qual fada
		# agora e ativado automaticamente assim que uma opcao e oferecida.
		var etapa_voo_aula: bool = tutorial_novo_ativo() and not PINTURA_GAMER_ATIVA and passo_tutorial_novo() in [9, 10]
		var elegivel_poder: bool = int(fada["dono"]) == jogador_atual and (not etapa_voo_aula or i == tutorial_voo_fada_indice)
		var destacada: bool = (i == indice_hover) or (etapa_voo_aula and i == tutorial_voo_fada_indice) or ((etapa_fada == "oferta" or etapa_fada == "escolha") and fadas_elegiveis.has(i)) or (tem_voo_livre() and acao_nova == "diagonal_fada" and elegivel_poder)
		var fator_entrada: float = 1.0
		if animacao_setup_ativa and i == visiveis - 1 and animacao_setup_etapa == i + 5:
			var progresso: float = progresso_entrada_setup()
			fator_entrada = 0.62 + 0.38 * progresso
			var brilho: Vector2 = centro_visual_da_fada(i)
			draw_circle(brilho, escala_fada_na_casa(i) * (2.2 + progresso),
				Color(0.78, 0.91, 1.0, (1.0 - progresso) * 0.20))
		if aula_demonstracao_ativa() and not turno_da_maquina() and indice_cenario_em_revisao < 0 and etapa_fada in ["oferta", "escolha"] and fadas_elegiveis.has(i) and i == int(aula_plano().get("fada", -1)):
			var centro_guia: Vector2 = centro_visual_da_fada(i)
			var pulso_guia: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.009)
			var raio_guia: float = escala_fada_na_casa(i) * (1.65 + 0.20 * pulso_guia)
			draw_arc(centro_guia, raio_guia, 0.0, TAU, 40, Color(0.45, 0.91, 1.0, 0.70 + 0.30 * pulso_guia), 2.5, true)
			draw_arc(centro_guia, raio_guia + 3.0, 0.0, TAU, 40, Color(0.20, 0.65, 1.0, 0.18 + 0.25 * pulso_guia), 4.0, true)
		desenhar_fada_miniatura(i, destacada, fator_entrada)
		# A previsão na faixa da aula usa o número correspondente à fada real.
		if aula_duelo_ativa() and not aula_demonstracao_ativa() and etapa_fada in ["oferta", "escolha"] and fadas_elegiveis.has(i):
			var centro_numero: Vector2 = centro_visual_da_fada(i) + Vector2(0.0, -escala_fada_na_casa(i) * 1.35)
			if area_tabuleiro.grow(-9.0).has_point(centro_numero):
				draw_circle(centro_numero, 8.0, Color("234761"))
				escrever_centralizado(str(fada["numero"]), centro_numero.x, centro_numero.y + 4.0, 11, Color.WHITE)
	if indice_voando >= 0 and indice_voando < visiveis:
		desenhar_fada_miniatura(indice_voando)

func desenhar_tabuleiro() -> void:
	# A borda inferior não separa o jardim das mensagens.
	draw_rect(area_tabuleiro, UI_MESA)
	var passo: float = tamanho_carta_base_jardim() * zoom
	var origem: Vector2 = centro_visual_do_jardim() + deslocamento

	# Grade discreta da mesa, atras do jardim.
	var x: float = area_tabuleiro.position.x + fposmod(origem.x - passo * 0.5 - area_tabuleiro.position.x, passo)
	while x < area_tabuleiro.end.x:
		draw_line(Vector2(x, area_tabuleiro.position.y), Vector2(x, area_tabuleiro.end.y), Color(1, 0.9, 0.76, 0.045), 1.0)
		x += passo
	var y: float = area_tabuleiro.position.y + fposmod(origem.y - passo * 0.5 - area_tabuleiro.position.y, passo)
	while y < area_tabuleiro.end.y:
		draw_line(Vector2(area_tabuleiro.position.x, y), Vector2(area_tabuleiro.end.x, y), Color(1, 0.9, 0.76, 0.045), 1.0)
		y += passo

	# Jogada normal: desenha possibilidades vazias quando uma carta foi escolhida.
	if not celebracao_objetivo_ativa and etapa_fada == "" and flor_na_mao != "" and not partida_encerrada and not modo_movimento and not movimento_pendente and (not versao_nova or acao_nova == "plantar"):
		for c in v209_casas_candidatas():
			if aula_guiada_ativa() and c != aula_alvo_tabuleiro():
				continue
			var centro: Vector2 = posicao_celula(c)
			var r: Rect2 = Rect2(centro - Vector2.ONE * passo * 0.43, Vector2.ONE * passo * 0.86)
			if mobile_pode_prever_plantio(c) and area_tabuleiro.grow(-1.0).intersects(r):
				var visivel: Rect2 = r.intersection(area_tabuleiro.grow(-1.0))
				draw_rect(visivel, Color(0.85, 0.93, 0.70, 0.13))
				draw_rect(visivel, Color(0.84, 0.91, 0.62, 0.52), false, 1.6)

	# Todas as flores sao desenhadas imediatamente, sem bordas marrons,
	# molduras ou transformacoes de entrada (inclusive no setup inicial).
	var ordem_flores: Array = tabuleiro.keys()
	var carta_elevada: Vector2i = mobile_borda_arrastada if mobile_borda_arrastada != CELULA_INVALIDA else v209_retorno_borda.get("casa", CELULA_INVALIDA)
	if carta_elevada != CELULA_INVALIDA and tabuleiro.has(carta_elevada):
		ordem_flores.erase(carta_elevada)
		ordem_flores.append(carta_elevada)
	for c in ordem_flores:
		if not juice_plantar.is_empty() and c == juice_plantar.get("casa") and indice_cenario_em_revisao < 0:
			continue
		var deslocamento_carta: Vector2 = juice_desvio_carta(c)
		var centro: Vector2 = posicao_celula(c) + deslocamento_carta
		var escala_carta: float = juice_escala_carta(c)
		var lado_carta: float = passo * escala_carta
		var r: Rect2 = Rect2(centro - Vector2.ONE * lado_carta * 0.5, Vector2.ONE * lado_carta)
		if area_tabuleiro.grow(-1.0).intersects(r):
			if deslocamento_carta != Vector2.ZERO or escala_carta > 1.0:
				draw_rect(Rect2(r.position + Vector2(3, 5), r.size).intersection(area_tabuleiro), Color(0, 0, 0, 0.24))
			var abertura_flor: float = juice_abertura_flor(c)
			var angulo_carta: float = juice_inclinacao_carta(c)
			# Rotação em torno do centro, sem alterar a célula lógica.
			if absf(angulo_carta) > 0.0001:
				draw_set_transform(centro - centro.rotated(angulo_carta), angulo_carta)
			var brisa: float = 0.0
			if not v209_leve and is_equal_approx(abertura_flor, 1.0) and deslocamento_carta == Vector2.ZERO and not animacao_setup_ativa:
				var fase_brisa: float = juice_relogio * 1.35 + float(c.x) * 0.79 + float(c.y) * 1.13
				abertura_flor *= 1.0 + 0.008 * sin(fase_brisa)
				brisa = 0.055 * sin(fase_brisa + 0.8)
			if feel_vento_ativo:
				var intensidade_vento: float = feel_vento_forca * clampf(1.0 - centro.distance_to(feel_vento_centro) / maxf(1.0, passo * 1.30), 0.0, 1.0)
				abertura_flor *= 1.0 + 0.045 * intensidade_vento * sin(juice_relogio * 13.0 + float(c.x + c.y))
				brisa += intensidade_vento * 0.35 * sin(juice_relogio * 9.0)
			desenhar_carta(centro, lado_carta, str(tabuleiro[c]), 1.0, true, abertura_flor, brisa)
			if absf(angulo_carta) > 0.0001:
				draw_set_transform(Vector2.ZERO)

	feel_desenhar_grama()
	v199_desenhar_reacao_grama()
	# Os polens no jardim aparecem como pequenas pecas redondas.
	desenhar_polens_do_jardim()

	# Sinalizacao azul da DECISAO manual de movimentar as fadas.
	# A nova flor recebe um contorno suave e linhas discretas indicam
	# quais miniaturas podem alcanca-la, sem exigir clicar antes no botao.
	if etapa_fada != "" and destino_da_fada != CELULA_INVALIDA:
		var pulso: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.006)
		var centro_destino: Vector2 = posicao_celula(destino_da_fada)
		var r_destino_fada: Rect2 = Rect2(centro_destino - Vector2.ONE * passo * 0.46, Vector2.ONE * passo * 0.92)
		if area_tabuleiro.grow(-1.0).intersects(r_destino_fada):
			draw_rect(r_destino_fada, Color(0.32, 0.73, 1.0, 0.55 + pulso * 0.30), false, maxf(1.8, passo * 0.023))
			var casas_destacadas: Dictionary = {}
			for indice in fadas_elegiveis:
				if etapa_fada in ["oferta", "escolha"]:
					var casa_fada: Vector2i = fadas[indice]["casa"]
					if not casas_destacadas.has(casa_fada):
						casas_destacadas[casa_fada] = true
						var quadro_fada: Rect2 = Rect2(posicao_celula(casa_fada) - Vector2.ONE * passo * 0.47, Vector2.ONE * passo * 0.94)
						if area_tabuleiro.grow(-1.0).encloses(quadro_fada):
							draw_rect(quadro_fada, Color(0.30, 0.73, 1.0, 0.75), false, maxf(2.0, passo * 0.025))
				if etapa_fada == "movendo" and indice != fada_em_movimento:
					continue
				var origem_fada: Vector2 = centro_visual_da_fada(indice)
				# Trajeto azul espesso e visivel durante a escolha e o movimento.
				# Uma camada translucida mais larga cria um brilho discreto.
				draw_line(origem_fada, centro_destino, Color(0.26, 0.62, 1.0, 0.15 + pulso * 0.10), maxf(6.0, passo * 0.11))
				draw_line(origem_fada, centro_destino, Color(0.28, 0.72, 1.0, 0.55 + pulso * 0.20), maxf(4.0, passo * 0.072))

	# Flores transformaveis: contorno verde em qualquer uma das 8 casas
	# imediatamente vizinhas as fadas do jogador, inclusive diagonais.
	if versao_nova and acao_nova in ["pintar_alvo", "pintar_cor"]:
		for casa_magica in flores_transformaveis(jogador_atual):
			var centro_magico: Vector2 = posicao_celula(casa_magica)
			var moldura_magica: Rect2 = Rect2(centro_magico - Vector2.ONE * passo * 0.465, Vector2.ONE * passo * 0.93)
			if area_tabuleiro.grow(-1.0).intersects(moldura_magica):
				var selecionada: bool = casa_magica == alvo_transformacao
				draw_rect(moldura_magica, Color("f4dc68") if selecionada else Color("5abaff"), false, maxf(2.0, passo * 0.030))
	# O poder Voar exibe pousos retos e diagonais somente DEPOIS de escolher a fada.
	# Miniaturas aparecem por cima do jardim e dos sinais de movimento.
	desenhar_todas_as_fadas()

	# Contorno AZUL fino sinaliza permanentemente flores da borda moviveis.
	if not animacao_setup_ativa and not celebracao_objetivo_ativa and etapa_fada == "" and not partida_encerrada and not movimento_pendente and (not versao_nova or acao_nova in ["mover", "", "plantar"] ):
		for c in tabuleiro:
			if not pode_deslocar_origem(c) or (aula_guiada_ativa() and c != aula_origem()):
				continue
			var centro: Vector2 = posicao_celula(c)
			var r: Rect2 = Rect2(centro - Vector2.ONE * passo * 0.5, Vector2.ONE * passo)
			if area_tabuleiro.grow(-1.0).intersects(r):
				draw_rect(r.grow(-passo * 0.025), Color(0.38, 0.72, 0.92, 0.45), false, maxf(1.0, passo * 0.014))

	# Hover: borda azul reforcada e retangulos azuis nas CASAS vazias possiveis.
	if not animacao_setup_ativa and not celebracao_objetivo_ativa and etapa_fada == "" and not partida_encerrada and not movimento_pendente and origem_selecionada == CELULA_INVALIDA and area_tabuleiro.has_point(mouse_pos):
		var hover: Vector2i = celula_na_posicao(mouse_pos)
		var hover_centro: Vector2 = posicao_celula(hover)
		var hover_rect: Rect2 = Rect2(hover_centro - Vector2.ONE * passo * 0.5, Vector2.ONE * passo)
		if hover_rect.has_point(mouse_pos) and area_tabuleiro.grow(-1.0).intersects(hover_rect) and pode_deslocar_origem(hover) and (not aula_guiada_ativa() or hover == aula_origem()):
			draw_rect(hover_rect.grow(-passo * 0.026), Color(0.28, 0.65, 0.93, 0.90), false, maxf(1.5, passo * 0.024))
			for direcao in VIZINHOS:
				var vizinha: Vector2i = hover + direcao
				if destino_valido_para_movimento(hover, vizinha) and (not aula_guiada_ativa() or vizinha == aula_destino()):
					var centro_livre: Vector2 = posicao_celula(vizinha)
					var r_livre: Rect2 = Rect2(centro_livre - Vector2.ONE * passo * 0.46, Vector2.ONE * passo * 0.92)
					if area_tabuleiro.grow(-1.0).intersects(r_livre):
						draw_rect(r_livre, Color(0.28, 0.65, 0.93, 0.14))
						draw_rect(r_livre, Color(0.38, 0.75, 0.96, 0.85), false, maxf(1.5, passo * 0.022))

	# Ao clicar numa flor de borda, indicar casas livres para afastamento.
	if origem_selecionada != CELULA_INVALIDA and not movimento_pendente:
		var centro_escolhido: Vector2 = posicao_celula(origem_selecionada)
		var r_escolhido: Rect2 = Rect2(centro_escolhido - Vector2.ONE * passo * 0.495, Vector2.ONE * passo * 0.99)
		if area_tabuleiro.grow(-1.0).intersects(r_escolhido):
			draw_rect(r_escolhido, Color("bed9df"), false, maxf(2.0, passo * 0.025))
		for direcao in VIZINHOS:
			var destino: Vector2i = origem_selecionada + direcao
			if not destino_valido_para_movimento(origem_selecionada, destino) or (aula_guiada_ativa() and destino != aula_destino()):
				continue
			var centro_destino: Vector2 = posicao_celula(destino)
			var r_destino: Rect2 = Rect2(centro_destino - Vector2.ONE * passo * 0.46, Vector2.ONE * passo * 0.92)
			if area_tabuleiro.grow(-1.0).intersects(r_destino):
				draw_rect(r_destino, Color(0.56, 0.80, 0.86, 0.18))
				draw_rect(r_destino, Color("91c9ce"), false, maxf(2.0, passo * 0.022))

	# Apos mover, a origem fica visivelmente vazia por pelo menos 1 segundo.
	if movimento_pendente:
		var centro_vazio: Vector2 = posicao_celula(origem_movimento)
		var r_vazio: Rect2 = Rect2(centro_vazio - Vector2.ONE * passo * 0.495, Vector2.ONE * passo * 0.99)
		if area_tabuleiro.grow(-1.0).intersects(r_vazio):
			draw_rect(r_vazio, Color("e6db99"), false, maxf(2.0, passo * 0.025))
		var centro_movido: Vector2 = posicao_celula(destino_movimento)
		var r_movido: Rect2 = Rect2(centro_movido - Vector2.ONE * passo * 0.495, Vector2.ONE * passo * 0.99)
		if area_tabuleiro.grow(-1.0).intersects(r_movido):
			draw_rect(r_movido, Color("91c9ce"), false, maxf(2.0, passo * 0.022))

	# Prévia translúcida: não confundir uma possibilidade com uma flor já plantada.
	if mobile_contexto_jogavel() and etapa_fada == "" and (flor_na_mao != "" or mobile_arrastando_coletiva) and not modo_movimento and not movimento_pendente and not toque_arrastou and area_tabuleiro.has_point(mouse_pos) and (not mobile_tem_toque() or mobile_ajustando_plantio):
		var c_mouse: Vector2i = feel_casa_magnetica(mouse_pos) if (mobile_arrastando_mao or mobile_arrastando_coletiva) else celula_na_posicao(mouse_pos)
		if c_mouse == CELULA_INVALIDA:
			c_mouse = celula_na_posicao(mouse_pos)
		var centro_previa: Vector2 = posicao_celula(c_mouse)
		var r_previa: Rect2 = Rect2(centro_previa - Vector2.ONE * passo * 0.5, Vector2.ONE * passo)
		if area_tabuleiro.grow(-1.0).intersects(r_previa) and not tabuleiro.has(c_mouse):
			if mobile_pode_prever_plantio(c_mouse):
				if area_tabuleiro.encloses(r_previa) and not mobile_arrastando_mao and not mobile_arrastando_coletiva:
					desenhar_carta(centro_previa, passo, flor_na_mao, 0.63 if mobile_ajustando_plantio else 0.42, true)
				draw_rect(r_previa.intersection(area_tabuleiro), Color(0.87, 0.95, 0.68, 0.90), false, 2.5)
			elif mobile_ajustando_plantio:
				draw_rect(r_previa.intersection(area_tabuleiro), Color(0.94, 0.22, 0.20, 0.14))
				draw_rect(r_previa.intersection(area_tabuleiro), Color("e87b70"), false, 2.0)

	if mobile_ajustando_plantio and mobile_contexto_jogavel() and area_tabuleiro.has_point(mouse_pos) and tabuleiro.has(celula_na_posicao(mouse_pos)) and not mobile_arrastando_mao:
		var r_invalida: Rect2 = Rect2(posicao_celula(celula_na_posicao(mouse_pos)) - Vector2.ONE * passo * 0.48, Vector2.ONE * passo * 0.96)
		draw_rect(r_invalida.intersection(area_tabuleiro), Color(0.94, 0.22, 0.20, 0.16))
		draw_rect(r_invalida.intersection(area_tabuleiro), Color("e87b70"), false, 2.0)
	v199_desenhar_previa_arrasto()
	v209_desenhar_encaixe()
	mobile_desenhar_previsao_voo()
	mobile_desenhar_constelacao()

	# Celebracao: as FLORES reais da combinacao ganham contorno amarelo.
	# Todos os novos polens surgem juntos; por 1 s sao desenhados em dobro.
	if celebracao_objetivo_ativa and not celebracao_objetivo_casas.is_empty():
		var pulso_amarelo: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.009)
		for casa_objetivo in celebracao_objetivo_casas:
			if juice_relogio - float(juice_efeitos.get("celebrar", -10.0)) < float(celebracao_objetivo_casas.find(casa_objetivo)) * 0.085 * juice_fator_tempo():
				continue
			var centro_flor_objetivo: Vector2 = posicao_celula(casa_objetivo)
			var moldura_flor: Rect2 = Rect2(centro_flor_objetivo - Vector2.ONE * passo * 0.48,
				Vector2.ONE * passo * 0.96)
			if area_tabuleiro.grow(-1.0).intersects(moldura_flor):
				draw_rect(moldura_flor.grow(1.5), Color(1.0, 0.78, 0.15, 0.20 + pulso_amarelo * 0.13), false, maxf(4.0, passo * 0.077))
				draw_rect(moldura_flor, Color(1.0, 0.91, 0.29, 0.75 + pulso_amarelo * 0.22), false, maxf(2.0, passo * 0.028))


# ============================================================================
# OBJETIVOS: GIRAR SOMENTE O DESENHO, NUNCA A REGRA NEM A PONTUACAO
# ============================================================================
func quantidade_slots_objetivos() -> int:
	if aula_duelo and jogador_atual >= 0 and jogador_atual < jogadores.size() and jogadores[jogador_atual]["objetivos"].size() == 1:
		return 3 if not aula_previa_objetivos(jogador_atual).is_empty() else 1
	if versao_nova and jogador_atual >= 0 and jogador_atual < jogadores.size() and bool(jogadores[jogador_atual].get("fadas_desbloqueadas", false)):
		return 4
	return 3

func retangulo_objetivo_ativo(indice: int) -> Rect2:
	return retangulo_objetivo_com_slots(indice, quantidade_slots_objetivos())

func espaco_grade_objetivos(largura: float) -> float:
	return clampf(largura * 0.022, 5.0, 8.0)

func lado_grade_objetivos(largura: float) -> float:
	# Preservar a leitura das cartas na nova proporção compacta; em telas curtas, reduzir suavemente.
	var altura_util: float = get_viewport_rect().size.y - ui_insets.y - ui_insets.w
	var limite: float = clampf(100.0 + (altura_util - 740.0) * 0.40, 86.0, 150.0)
	return minf(limite, (largura - 16.0 - espaco_grade_objetivos(largura)) * 0.5)

func retangulo_objetivo_com_slots(indice: int, quantidade: int) -> Rect2:
	var espaco: float = espaco_grade_objetivos(area_objetivos.size.x)
	var lado: float = lado_grade_objetivos(area_objetivos.size.x)
	var largura_grade: float = 2.0 * lado + espaco
	var esquerda: float = area_objetivos.get_center().x - largura_grade * 0.5
	# Tutorial: um objetivo central no topo; as duas prévias ficam abaixo.
	if aula_duelo and jogador_atual == 0 and jogadores[0]["objetivos"].size() == 1 and quantidade in [1, 3]:
		if indice == 0:
			return Rect2(area_objetivos.get_center().x - lado * 0.5, area_objetivos.position.y + 28.0, lado, lado)
		return Rect2(esquerda + float(indice - 1) * (lado + espaco), area_objetivos.position.y + 28.0 + lado + espaco, lado, lado)
	var x: float = esquerda + float(indice % 2) * (lado + espaco)
	return Rect2(x, area_objetivos.position.y + 28.0 + float(floori(float(indice) / 2.0)) * (lado + espaco), lado, lado)

# Região invisível de interação no canto superior direito do cabeçalho.
func v210_area_giro_objetivo(r: Rect2) -> Rect2:
	var altura: float = clampf(r.size.y * 0.235, 23.0, 43.0)
	var largura: float = minf(r.size.x * 0.46, clampf(r.size.x * 0.38, 32.0, 48.0))
	return Rect2(Vector2(r.end.x - largura - 2.0, r.position.y + 2.0), Vector2(largura, altura - 3.0))

func objetivo_aceita_giro(indice: int) -> bool:
	if estado_tela != "partida" or indice_cenario_em_revisao >= 0 or jogadores.is_empty():
		return false
	var objetivos: Array[Dictionary] = jogadores[jogador_atual]["objetivos"]
	if indice < 0 or indice >= objetivos.size() or objetivos[indice].is_empty() or str(objetivos[indice].get("classe", "flor")) == "fada":
		return false
	var so_objetivo_da_aula: bool = PINTURA_GAMER_ATIVA and tutorial_novo_ativo() and passo_tutorial_novo() == 9
	if so_objetivo_da_aula and str(objetivos[indice].get("id", "")) != "6:vermelha:lilas":
		mensagem = "Gire somente o objetivo indicado em azul."
		queue_redraw()
		return false
	var indice_rotacao_aula: int = aula_indice_rotacao()
	if indice_rotacao_aula >= 0:
		if aula_rotacao_pendente() and indice != indice_rotacao_aula:
			return false
		if indice == indice_rotacao_aula and not aula_rotacao_pendente():
			return false
	return true

func aplicar_giro_objetivo(indice: int, passos: int = 1, angulo_gesto: float = 0.0) -> bool:
	if not objetivo_aceita_giro(indice):
		return false
	var objetivos: Array[Dictionary] = jogadores[jogador_atual]["objetivos"]
	var chave_giro: String = str(objetivos[indice].get("id", ""))
	# Continua a partir do ângulo real do dedo, sem salto ou giro forçado para a direita.
	juice_rotacoes[chave_giro] = {"inicio": juice_relogio, "desvio": angulo_gesto - float(passos) * PI * 0.5}
	if passos != 0:
		tocar_som("papel_girar")
		juice_vibrar(10)
	objetivos[indice]["rotacao_visual"] = posmod(int(objetivos[indice].get("rotacao_visual", 0)) + passos, 4)
	var indice_rotacao_aula: int = aula_indice_rotacao()
	if indice == indice_rotacao_aula and not aula_rotacao_pendente():
		atualizar_interface_acoes_nova()
	var so_objetivo_da_aula: bool = PINTURA_GAMER_ATIVA and tutorial_novo_ativo() and passo_tutorial_novo() == 9
	if so_objetivo_da_aula and int(objetivos[indice]["rotacao_visual"]) == 2:
		tutorial_rotacao_pronta = true
		mensagem = "Objetivo orientado!"
		preparar_poder_do_tutorial_novo()
		atualizar_interface_acoes_nova()
		sincronizar_botoes_menu()
	queue_redraw()
	return true

func armar_giro_objetivo(posicao: Vector2) -> bool:
	if estado_tela != "partida" or indice_cenario_em_revisao >= 0 or jogadores.is_empty():
		return false
	var objetivos: Array[Dictionary] = jogadores[jogador_atual]["objetivos"]
	for i in range(objetivos.size()):
		if objetivos[i].is_empty() or str(objetivos[i].get("classe", "flor")) == "fada":
			continue
		var carta_r: Rect2 = retangulo_objetivo_ativo(i)
		if not carta_r.has_point(posicao):
			continue
		if v210_area_giro_objetivo(carta_r).has_point(posicao):
			if not objetivo_aceita_giro(i):
				return false
			mobile_objetivo_giro_indice = i
			mobile_objetivo_giro_inicio = posicao
			mobile_objetivo_giro_centro = carta_r.get_center()
			mobile_objetivo_giro_angulo_inicial = (posicao - mobile_objetivo_giro_centro).angle()
			v209_giro_ultimo = mobile_objetivo_giro_angulo_inicial
			v209_giro_angulo = 0.0
			v209_giro_token = identificador_partida
			v209_giro_turno = turnos_jogados
			v209_giro_id = str(objetivos[i].get("id", ""))
			juice_rotacoes.erase(v209_giro_id)
			queue_redraw()
			return true
	return false

func v209_giro_valido() -> bool:
	if mobile_objetivo_giro_indice < 0 or not mobile_contexto_jogavel() or v209_giro_token != identificador_partida or v209_giro_turno != turnos_jogados or mobile_gesto_cancelado or gesto_multitoque_ativo:
		return false
	if not objetivo_aceita_giro(mobile_objetivo_giro_indice):
		return false
	return str(jogadores[jogador_atual]["objetivos"][mobile_objetivo_giro_indice].get("id", "")) == v209_giro_id

func v209_atualizar_angulo(posicao: Vector2) -> void:
	var vetor: Vector2 = posicao - mobile_objetivo_giro_centro
	if vetor.length() < 12.0:
		return # evita saltos angulares ao cruzar o centro da carta
	var angulo: float = vetor.angle()
	v209_giro_angulo = clampf(v209_giro_angulo + wrapf(angulo - v209_giro_ultimo, -PI, PI), -TAU, TAU)
	v209_giro_ultimo = angulo

func finalizar_giro_objetivo(posicao: Vector2) -> bool:
	if not v209_giro_valido():
		mobile_limpar_intencao()
		return true
	v209_atualizar_angulo(posicao)
	var indice: int = mobile_objetivo_giro_indice
	var angulo: float = v209_giro_angulo
	var distancia: float = posicao.distance_to(mobile_objetivo_giro_inicio)
	mobile_objetivo_giro_indice = -1
	v209_giro_angulo = 0.0
	if absf(angulo) < 0.18 and distancia < 10.0:
		var area: Rect2 = v210_area_giro_objetivo(retangulo_objetivo_ativo(indice))
		if area.has_point(posicao):
			return aplicar_giro_objetivo(indice, 1, 0.0)
		queue_redraw()
		return true
	var passos: int = roundi(angulo / (PI * 0.5))
	return aplicar_giro_objetivo(indice, passos, angulo)

func v209_angulo_desenho(objetivo: Dictionary, indice: int, permitir_giro: bool) -> float:
	if not permitir_giro or indice_cenario_em_revisao >= 0:
		return 0.0
	var chave: String = str(objetivo.get("id", ""))
	if mobile_objetivo_giro_indice == indice and chave == v209_giro_id:
		return v209_giro_angulo
	if juice_rotacoes.has(chave):
		var animacao: Dictionary = juice_rotacoes[chave]
		var t: float = clampf((juice_relogio - float(animacao["inicio"])) / (0.20 * juice_fator_tempo()), 0.0, 1.0)
		return float(animacao["desvio"]) * (1.0 - interpolar_suave(t))
	return 0.0

func desenhar_objetivo_fada(objetivo: Dictionary, r: Rect2, _compacto: bool = false) -> void:
	if objetivo.is_empty():
		return
	var margem: float = clampf(r.size.x * 0.065, 4.0, 11.0)
	draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0.05, 0.04, 0.04, 0.3))
	ui_superficie(r, Color("253e49"), Color("7eaec4"), 8, true)
	
	var titulo_fonte: int = int(clampf(r.size.x * 0.115, 10.0, 25.0))
	var texto_fonte: int = int(clampf(r.size.x * 0.115, 10.0, 25.0))
	var pontos: int = int(objetivo.get("pontos_finais", objetivo["pontos"]))
	var cabecalho_fada: String = "FADA · %s" % rotulo_estrela_compacto(pontos)
	escrever_ajustado(cabecalho_fada, r.position.x + margem, r.position.y + margem + titulo_fonte,
		r.size.x - margem * 2.0, titulo_fonte, Color("d6efff"))
	draw_line(Vector2(r.position.x + margem, r.position.y + margem + titulo_fonte + 6.0),
		Vector2(r.end.x - margem, r.position.y + margem + titulo_fonte + 6.0), Color("a8dcf7", 0.5), 1.0)
	# A Expandida nunca imprime o nome do objetivo nas cartas.
	# Preserva o titulo apenas nos dados internos, para metricas.
	# Descrições de posicionamento e confronto são mais longas: até 5 linhas.
	var descricao: String = str(objetivo.get("descricao", ""))
	var largura_util: float = maxf(14.0, r.size.x - margem * 2.0)
	var topo_texto: float = r.position.y + margem + titulo_fonte + 10.0
	var altura_texto: float = maxf(8.0, r.end.y - margem - topo_texto)
	var linhas: Array[String] = quebrar_texto_instrucoes(descricao, largura_util, texto_fonte)
	while texto_fonte > (17 if r.size.x >= 250.0 else 8) and float(linhas.size()) * float(texto_fonte + 2) > altura_texto:
		texto_fonte -= 1
		linhas = quebrar_texto_instrucoes(descricao, largura_util, texto_fonte)
	var avancar: float = float(texto_fonte + 2)
	var linhas_exibidas: int = mini(linhas.size(), maxi(1, floori(altura_texto / avancar)))
	for i in range(linhas_exibidas):
		var linha: String = linhas[i]
		if i == linhas_exibidas - 1 and linhas.size() > linhas_exibidas:
			linha += "…"
		escrever_ajustado(linha, r.position.x + margem, topo_texto + float(texto_fonte) + float(i) * avancar,
			largura_util, texto_fonte, Color("ecf5f4"))

func cor_modulada_objetivo(nome: String) -> Color:
	match nome:
		"vermelha":
			return Color(1.10, 0.95, 0.95, 1.0)
		"amarela":
			return Color(1.08, 1.04, 0.90, 1.0)
		"lilas":
			return Color(1.06, 0.96, 1.10, 1.0)
		_:
			return Color.WHITE

func objetivo_posicoes_vazias_para_moldura(posicoes: Array[Vector2i]) -> Array[Vector2i]:
	var ocupadas: Dictionary = {}
	var minimo_x: int = 999
	var maximo_x: int = -999
	var minimo_y: int = 999
	var maximo_y: int = -999
	for posicao in posicoes:
		ocupadas[posicao] = true
		minimo_x = mini(minimo_x, posicao.x)
		maximo_x = maxi(maximo_x, posicao.x)
		minimo_y = mini(minimo_y, posicao.y)
		maximo_y = maxi(maximo_y, posicao.y)
	var visitado: Dictionary = {}
	var componentes: int = 0
	for posicao in posicoes:
		if visitado.has(posicao):
			continue
		componentes += 1
		var fila: Array[Vector2i] = [posicao]
		visitado[posicao] = true
		while not fila.is_empty():
			var atual: Vector2i = fila.pop_back()
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if dx == 0 and dy == 0:
						continue
					var vizinho: Vector2i = atual + Vector2i(dx, dy)
					if ocupadas.has(vizinho) and not visitado.has(vizinho):
						visitado[vizinho] = true
						fila.append(vizinho)
	if componentes <= 1:
		return []
	var vazias: Array[Vector2i] = []
	for y in range(minimo_y, maximo_y + 1):
		for x in range(minimo_x, maximo_x + 1):
			var casa: Vector2i = Vector2i(x, y)
			if not ocupadas.has(casa):
				vazias.append(casa)
	return vazias

func desenhar_objetivo(objetivo: Dictionary, r: Rect2, _indice: int, compacto: bool = false, permitir_giro: bool = false, polens_no_centro: bool = false) -> void:
	# O desenho gira por toque no canto superior direito ou gesto; texto e moldura ficam fixos.
	# A verificacao das combinacoes no jardim usa sempre o MODELO ORIGINAL.
	if objetivo.is_empty():
		return
	if str(objetivo.get("classe", "flor")) == "fada":
		desenhar_objetivo_fada(objetivo, r, compacto)
		return
	ui_superficie(r, Color("514537"), Color("a58b61"), 6, true)
	var escala: float = r.size.x / 204.0
	var margem: float = clampf(r.size.x * 0.07, 4.0, 13.0)
	var altura_cabecalho: float = clampf(r.size.y * 0.235, 15.0 if compacto else 23.0, 43.0)
	var tamanho_fonte: int = int(clampf(r.size.x * 0.145, 12.0, 28.0))
	var pontos_exibidos: int = int(objetivo.get("pontos_finais", objetivo["pontos"]))
	if estado_tela == "distribuicao_final":
		var t_dobro: float = clampf((juice_relogio - float(juice_efeitos.get("dobro:%s" % str(objetivo.get("id", "")), -10.0))) / 0.45, 0.0, 1.0)
		pontos_exibidos = roundi(lerpf(float(objetivo["pontos"]), float(pontos_exibidos), t_dobro))
	var texto_pontos: String = rotulo_estrela_compacto(pontos_exibidos)
	var largura_disponivel: float = maxf(12.0, r.size.x - 2.0 * margem)
	if permitir_giro:
		largura_disponivel = maxf(12.0, v210_area_giro_objetivo(r).position.x - r.position.x - margem - 3.0)
	var largura_texto: float = ui_fonte_para(COR_PRATA, tamanho_fonte).get_string_size(texto_pontos, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_fonte).x
	while tamanho_fonte > 7 and largura_texto > largura_disponivel:
		tamanho_fonte -= 1
		largura_texto = ui_fonte_para(COR_PRATA, tamanho_fonte).get_string_size(texto_pontos, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_fonte).x
	if largura_texto > largura_disponivel:
		texto_pontos = "%s%d" % [ICONE_ESTRELA_VITORIA, pontos_exibidos]
	escrever(texto_pontos, Vector2(r.position.x + margem, r.position.y + altura_cabecalho * 0.75), tamanho_fonte, COR_PRATA)
	draw_line(Vector2(r.position.x + margem, r.position.y + altura_cabecalho),
		Vector2(r.end.x - margem, r.position.y + altura_cabecalho), Color("c3a474", 0.35), 1.0)

	var area_desenho: Rect2 = Rect2(
		r.position + Vector2(margem, altura_cabecalho + 3.0),
		Vector2(r.size.x - 2.0 * margem, r.size.y - altura_cabecalho - margem - 5.0)
	)
	var tipo: int = int(objetivo["tipo"])
	var modelo: Dictionary = MODELOS_OBJETIVO[tipo]
	var padrao: Array = modelo["padrao"]
	var giro: int = int(objetivo.get("rotacao_visual", 0)) % 4
	var chave_geometria: Vector2i = Vector2i(tipo, giro)
	if not v209_geometrias.has(chave_geometria):
		var casas: Array[Vector2i] = posicoes_do_modelo(modelo)
		for i in range(casas.size()):
			casas[i] = transformar_posicao(casas[i], giro, false)
		v209_geometrias[chave_geometria] = {"casas": casas, "molduras": objetivo_posicoes_vazias_para_moldura(casas)}
	var posicoes: Array[Vector2i] = v209_geometrias[chave_geometria]["casas"]
	if posicoes.is_empty():
		return
	var angulo_giro: float = v209_angulo_desenho(objetivo, _indice, permitir_giro)
	var escala_giro: float = 1.0 / maxf(1.0, absf(cos(angulo_giro)) + absf(sin(angulo_giro)))

	var minimo_x: int = 999
	var maximo_x: int = -999
	var minimo_y: int = 999
	var maximo_y: int = -999
	for posicao in posicoes:
		minimo_x = mini(minimo_x, posicao.x)
		maximo_x = maxi(maximo_x, posicao.x)
		minimo_y = mini(minimo_y, posicao.y)
		maximo_y = maxi(maximo_y, posicao.y)
	var intervalo: float = clampf(5.0 * escala, 1.5, 5.0)
	# Grade 3x3 fixa: tamanhos identicos para todos os tipos de objetivo.
	var lado_quadrado: float = minf(52.0, minf(
		(area_desenho.size.x - 2.0 * intervalo) / 3.0,
		(area_desenho.size.y - 2.0 * intervalo) / 3.0
	))
	lado_quadrado = maxf(1.0, lado_quadrado)
	var passo: float = lado_quadrado + intervalo
	var centro_modelo: Vector2 = Vector2(
		float(minimo_x + maximo_x) * 0.5,
		float(minimo_y + maximo_y) * 0.5
	)
	var lado_visual: float = lado_quadrado * escala_giro * maxf(absf(cos(angulo_giro)), absf(sin(angulo_giro)))
	var polens_desenhados: Dictionary = objetivo.get("polens_aplicados", {}).duplicate()
	var vazias_moldura: Array[Vector2i] = v209_geometrias[chave_geometria]["molduras"]
	for posicao_vazia in vazias_moldura:
		var centro_vazio: Vector2 = area_desenho.get_center() + (Vector2(posicao_vazia) - centro_modelo).rotated(angulo_giro) * passo * escala_giro
		var quadrado_vazio: Rect2 = Rect2(centro_vazio - Vector2.ONE * lado_visual * 0.5, Vector2.ONE * lado_visual)
		draw_rect(quadrado_vazio, Color("5c4633"))
		draw_rect(quadrado_vazio.grow(-maxf(0.7, 2.1 * escala)), Color("6c553f"), false, 1.0)
		draw_rect(quadrado_vazio.grow(-maxf(1.5, 4.2 * escala)), Color("8d7052", 0.22), false, 1.0)
	for i in range(posicoes.size()):
		var vetor_modelo: Vector2 = (Vector2(posicoes[i]) - centro_modelo).rotated(angulo_giro) * escala_giro
		var centro: Vector2 = area_desenho.get_center() + vetor_modelo * passo
		var quadrado: Rect2 = Rect2(centro - Vector2.ONE * lado_visual * 0.5, Vector2.ONE * lado_visual)
		draw_rect(quadrado, Color("4e8043"))
		draw_rect(quadrado.grow(-maxf(0.7, 2.3 * escala)), Color("64964b"))
		if not compacto:
			draw_rect(quadrado, Color("a7b980"), false, 1.0)
		var cor: String = cor_da_marca(objetivo, str(padrao[i]))
		# Ampliar apenas as flores das cartas concluidas (miniaturas do historico).
		# Os objetivos ativos preservam o tamanho anterior.
		var escala_flor: float = 0.74 if compacto else 0.56
		desenhar_flor(centro - Vector2(0.0, 0.8), lado_visual * escala_flor, cor, 1.0, 0.0, 1.0, true)
		# Cada polen aplicado fica visivel na flor da carta concluida.
		# Se houver duas flores da mesma cor, usa uma por unidade paga.
		if int(polens_desenhados.get(cor, 0)) > 0:
			polens_desenhados[cor] = int(polens_desenhados[cor]) - 1
			var centro_marca: Vector2 = centro if polens_no_centro else centro + Vector2(lado_visual * 0.23, -lado_visual * 0.27)
			var raio_marca: float = maxf(2.0, lado_visual * (0.13 if polens_no_centro else 0.14))
			if compacto and duplicacao_ativa and duplicacao_indice_jogador == jogador_atual and duplicacao_indice_historico == _indice and duplicacao_polen_ultimo_indice == i:
				var pulso: float = duplicacao_polen_ultimo_tempo / 0.45
				draw_circle(centro_marca, raio_marca * (1.6 + pulso), Color("ffe79d", 0.13 + 0.28 * pulso))
			desenhar_polen_brilhante(centro_marca, raio_marca, cor)
	if bool(objetivo.get("duplicado", false)):
		var tamanho_x: int = maxi(8, tamanho_fonte - 1)
		escrever("×2", Vector2(r.end.x - margem - float(tamanho_x * 2), r.end.y - margem * 0.5),
			tamanho_x, Color("8cdbff"))

func desenhar_verso_baralho(r: Rect2, alfa: float = 1.0) -> void:
	# Usa exatamente o fundo de carta fornecido pelo autor, em tamanho proporcional.
	if textura_verso_baralho != null:
		draw_texture_rect(textura_verso_baralho, r, false, Color(1.0, 1.0, 1.0, alfa))
		return
	# Mantem uma alternativa segura caso a textura nao carregue na Godot.
	desenhar_verso_baralho_reserva(r, alfa)

func desenhar_verso_baralho_reserva(r: Rect2, alfa: float = 1.0) -> void:
	# Ornamentos em marrom, verde e dourado, proporcionais a cada tela.
	var centro: Vector2 = r.get_center()
	var s: float = r.size.x
	draw_rect(Rect2(r.position + Vector2(2.0, 3.0), r.size), Color(0.05, 0.03, 0.02, 0.22 * alfa))
	draw_rect(r, Color(Color("d9c29a"), alfa))
	draw_rect(r.grow(-s * 0.045), Color(Color("6b4a35"), alfa))
	draw_rect(r.grow(-s * 0.10), Color(Color("325f43"), alfa))
	draw_rect(r.grow(-s * 0.15), Color(Color("e0cfad"), alfa), false, maxf(1.0, s * 0.018))
	draw_rect(r.grow(-s * 0.22), Color(Color("6e5641"), alfa), false, maxf(1.0, s * 0.010))

	# Medalhao com rosacea ornamental de oito petalas.
	var raio_ext: float = s * 0.215
	var raio_int: float = s * 0.145
	draw_circle(centro, raio_ext, Color(Color("e5d6bb"), alfa))
	draw_circle(centro, raio_ext * 0.86, Color(Color("6b4a35"), alfa))
	draw_circle(centro, raio_int, Color(Color("d9c29a"), alfa))
	draw_circle(centro, raio_int * 0.70, Color(Color("3f6b50"), alfa))
	for i in range(8):
		var ang: float = TAU * float(i) / 8.0
		var p: Vector2 = centro + Vector2(cos(ang), sin(ang)) * raio_int * 0.40
		draw_circle(p, raio_int * 0.18, Color(Color("eadbc0"), alfa))
	draw_circle(centro, raio_int * 0.17, Color(Color("99764c"), alfa))
	draw_circle(centro, raio_int * 0.095, Color(Color("f4e9c7"), alfa))

	# Quatro pequenos ramos decorativos simetricos.
	for i in range(4):
		var ang: float = TAU * float(i) / 4.0
		var direcao: Vector2 = Vector2(cos(ang), sin(ang))
		var ponta: Vector2 = centro + direcao * s * 0.31
		draw_line(centro + direcao * s * 0.23, ponta, Color(Color("dcc8a3"), 0.85 * alfa), maxf(1.0, s * 0.013))
		draw_circle(ponta, s * 0.017, Color(Color("eadbc0"), alfa))
	for x_sinal in [-1.0, 1.0]:
		for y_sinal in [-1.0, 1.0]:
			var canto: Vector2 = centro + Vector2(x_sinal, y_sinal) * s * 0.36
			draw_circle(canto, s * 0.023, Color(Color("d5bb86"), alfa))
			draw_circle(canto, s * 0.010, Color(Color("3f6b50"), alfa))

func desenhar_pilha_baralho(r: Rect2, alfa: float = 1.0) -> void:
	# Simula varias cartas sob a ilustracao do topo, sem editar o PNG.
	# As camadas surgem ao lado direito e embaixo, com borda de papel clara.
	# Com o estoque chegando ao fim, a altura da pilha diminui.
	var camadas: int = mini(5, maxi(1, baralho.size()))
	var passo_camada: float = minf(2.2, r.size.x * 0.032)
	var margem: float = passo_camada * float(camadas - 1)
	var lado: float = maxf(10.0, r.size.x - margem - 1.0)
	var frente: Rect2 = Rect2(r.position + Vector2(0.5, 0.5), Vector2.ONE * lado)
	for camada in range(camadas - 1, 0, -1):
		var desvio: Vector2 = Vector2(passo_camada, passo_camada * 0.85) * float(camada)
		var traseira: Rect2 = Rect2(frente.position + desvio, frente.size)
		# Evita acumular opacidade de várias cartas sobrepostas quando indisponível.
		if alfa < 1.0:
			draw_rect(traseira, Color(Color("efe3cc"), alfa * 0.65), false, 1.0)
			continue
		draw_rect(Rect2(traseira.position + Vector2(1.3, 2.4), traseira.size), Color(0.04, 0.02, 0.01, 0.23 * alfa))
		draw_rect(traseira, Color(Color("ded5bd"), alfa))
		draw_rect(traseira.grow(-1.3), Color(Color("2d653c"), alfa))
		draw_rect(traseira, Color(Color("efe3cc"), alfa), false, maxf(0.9, r.size.x * 0.014))
	# O desenho original da flor verde e da interrogacao permanece intacto.
	draw_rect(Rect2(frente.position + Vector2(1.5, 2.0), frente.size), Color(0, 0, 0, 0.24 * alfa))
	desenhar_verso_baralho(frente, alfa)
	draw_rect(frente, Color(Color("eadfc7"), 0.8 * alfa), false, maxf(0.9, r.size.x * 0.012))

func pode_realcar_fonte_compra(da_aberta: bool) -> bool:
	if origem_carta_selecionada != "":
		return false
	if aula_guiada_ativa() and not aula_pode_comprar(da_aberta):
		return false
	if estado_tela != "partida" or partida_encerrada or animacao_setup_ativa or turno_da_maquina() or maquina_ocupada or duplicacao_ativa or celebracao_objetivo_ativa or etapa_fada != "" or flor_na_mao != "" or indice_cenario_em_revisao >= 0 or tutorial_passo_consulta >= 1 or tutorial_final_pendente or escolha_objetivo_ativa or escolhas_iniciais_pendentes or conquistas_abertas:
		return false
	if (da_aberta and flor_aberta == "") or (not da_aberta and baralho.is_empty()):
		return false
	if acao_nova != "" and acao_nova not in ["plantar", "mover"]:
		return false
	if acao_nova == "" and not acao_permitida_no_tutorial_novo(acao_automatica_compra()):
		return false
	return true

func desenhar_compra() -> void:
	ui_superficie(area_compra, UI_PAINEL, UI_BORDA, 10, false)
	# A origem só é limpa ao terminar a jogada. Não depende da carta ainda estar na mão.
	var alfa_baralho: float = 0.28 if origem_carta_selecionada != "" else 1.0
	var alfa_coletiva: float = 0.28 if origem_carta_selecionada == "baralho" else 1.0

	if flor_aberta != "" and (juice_repor.is_empty() or indice_cenario_em_revisao >= 0):
		desenhar_carta(area_aberta.get_center(), area_aberta.size.x * (1.01 if area_aberta.has_point(mouse_pos) and pode_realcar_fonte_compra(true) else 0.98), flor_aberta, alfa_coletiva * (0.20 if mobile_arrastando_coletiva else 1.0))
	else:
		retangulo(area_aberta, Color("3c322c"), Color("6a5643"))
		var texto_vazio: String = "Vazia"
		var fonte_vazio: int = 11 if area_aberta.size.x < 63.0 else 13
		var largura_vazio: float = fonte.get_string_size(texto_vazio, HORIZONTAL_ALIGNMENT_LEFT, -1, fonte_vazio).x
		escrever(texto_vazio, Vector2(area_aberta.get_center().x - largura_vazio * 0.5,
			area_aberta.get_center().y + 5.0), fonte_vazio, COR_TEXTO_FRACO)

	desenhar_pilha_baralho(area_baralho.grow(area_baralho.size.x * 0.015) if area_baralho.has_point(mouse_pos) and pode_realcar_fonte_compra(false) else area_baralho, alfa_baralho)
	if aula_guiada_ativa():
		for da_aberta in [true, false]:
			if pode_realcar_fonte_compra(da_aberta):
				var fonte_guiada: Rect2 = area_aberta if da_aberta else area_baralho
				draw_rect(fonte_guiada.grow(3.0), Color(0.30, 0.73, 1.0, 0.90), false, 2.5)

	var cancelar_voo: bool = pode_cancelar_voo_na_mao()
	var ocultar_mao: bool = indice_cenario_em_revisao < 0 and (animacao_compra_ativa or not juice_plantar.is_empty())
	if flor_na_mao != "" and not ocultar_mao and feel_retorno.is_empty():
		var centro_mao: Vector2 = area_mao.get_center()
		desenhar_carta(centro_mao, area_mao.size.x * 0.98, flor_na_mao, 0.30 if mobile_arrastando_mao else 1.0)

	elif cancelar_voo and not ocultar_mao:
		var r_botao: Rect2 = area_mao.grow(-2.0)
		var pressionado: bool = cancelar_voo_press.x >= 0 and area_mao.has_point(mouse_pos)
		var hover: bool = area_mao.has_point(mouse_pos)
		var fundo_botao: Color = Color("49302a") if pressionado else (Color("88594b") if hover else Color("75483e"))
		ui_superficie(r_botao, fundo_botao, Color("bc9377"), 10, true)
		if r_botao.size.x < 90.0:
			var meio: float = r_botao.size.y * 0.5
			escrever_texto_botao_centralizado("Cancelar", Rect2(r_botao.position + Vector2(0.0, meio - 22.0), Vector2(r_botao.size.x, 22.0)), 13)
			escrever_texto_botao_centralizado("Voo", Rect2(r_botao.position + Vector2(0.0, meio), Vector2(r_botao.size.x, 22.0)), 13)
		else:
			escrever_texto_botao_centralizado("Cancelar Voo", r_botao, 16)
	elif flor_na_mao == "" and not ocultar_mao:
		ui_superficie(area_mao, Color("252620"), Color("655e4e"), 9, false)
		escrever_centralizado("Vazia", area_mao.get_center().x, area_mao.get_center().y + 5.0, 14, COR_TEXTO_FRACO)

	var legendas: Array[String] = ["Baralho · %d" % baralho.size(), "Flor Coletiva", "Sua Flor"]
	var retangulos: Array[Rect2] = [area_baralho, area_aberta, area_mao]
	var largura_maxima: float = area_compra.size.x - 12.0
	for i in range(retangulos.size()):
		var tamanho: int = 13
		while tamanho > 11 and fonte.get_string_size(legendas[i], HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x > largura_maxima:
			tamanho -= 1
		var largura_texto: float = fonte.get_string_size(legendas[i], HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
		var posicao: Vector2 = Vector2(retangulos[i].get_center().x - largura_texto * 0.5, retangulos[i].end.y + 12.0)
		var alfa_legenda: float = maxf(0.72, alfa_baralho if i == 0 else (alfa_coletiva if i == 1 else 1.0))
		escrever(legendas[i], posicao, tamanho, Color(COR_TEXTO, alfa_legenda))

	juice_desenhar_reposicao()

	if mobile_fonte_pressionada >= 0 and mobile_contexto_jogavel():
		var pressionada: bool = mobile_fonte_pressionada == 1
		var r_pressao: Rect2 = area_aberta if pressionada else area_baralho
		if mobile_area_fonte(pressionada).has_point(mouse_pos):
			draw_rect(r_pressao, Color(0.06, 0.10, 0.07, 0.20))
			draw_rect(r_pressao.grow(2.0), Color("f4dc98"), false, 2.5)
	var pulso_compra: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.005)
	for da_aberta in [false, true]:
		if not pode_realcar_fonte_compra(da_aberta):
			continue
		var r_compra: Rect2 = area_aberta if da_aberta else area_baralho
		for i in range(3, 0, -1):
			draw_rect(r_compra.grow(float(i) * 1.5), Color(0.22, 0.63, 1.0, (0.10 + pulso_compra * 0.10) / float(i)), false, 2.0)
		draw_rect(r_compra.grow(2.0), Color(0.29, 0.75, 1.0, 0.58 + pulso_compra * 0.38), false, 2.6)
		draw_rect(r_compra, Color(0.80, 0.94, 1.0, 0.45 + pulso_compra * 0.38), false, 1.2)

func interpolar_suave(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func desenhar_carta_em_retangulo(r: Rect2, tipo: String, alfa: float = 1.0) -> void:
	if r.size.x <= 1.0 or r.size.y <= 1.0:
		return
	var area_verde: Rect2 = r
	draw_rect(area_verde, Color("579b42"))
	desenhar_grama_discreta_em_carta(area_verde)
	if CORES.has(tipo):
		var lado: float = minf(r.size.x, r.size.y)
		desenhar_flor(r.get_center() - Vector2(0.0, lado * 0.035), lado * 0.34, tipo)
	if alfa < 1.0:
		draw_rect(area_verde, Color(0.25, 0.42, 0.24, 1.0 - alfa))

func iniciar_animacao_compra(fonte_animada: String, cor: String) -> void:
	if cor == "":
		animacao_compra_ativa = false
		animacao_compra_fonte = ""
		animacao_compra_cor = ""
		animacao_compra_tempo = 0.0
		return
	animacao_compra_ativa = true
	animacao_compra_fonte = fonte_animada
	animacao_compra_cor = cor
	animacao_compra_tempo = 0.0
	tocar_som("papel_coletiva" if fonte_animada == "aberta" else "papel_saque")
	queue_redraw()

func desenhar_animacao_compra() -> void:
	if indice_cenario_em_revisao >= 0 or not animacao_compra_ativa or animacao_compra_cor == "":
		return
	var origem: Rect2 = area_aberta if animacao_compra_fonte == "aberta" else area_baralho
	var destino: Rect2 = area_mao
	if animacao_compra_fonte == "aberta":
		var t: float = interpolar_suave(animacao_compra_tempo / DURACAO_ANIMACAO_CARTA_COLETIVA)
		var centro: Vector2 = origem.get_center().lerp(destino.get_center(), t)
		var lado: float = lerpf(origem.size.x * 0.98, destino.size.x * 0.98, t)
		desenhar_carta(centro, lado, animacao_compra_cor)
		return

	if animacao_compra_tempo < DURACAO_ANIMACAO_REVELAR_BARALHO:
		var t_revelar: float = clampf(animacao_compra_tempo / DURACAO_ANIMACAO_REVELAR_BARALHO, 0.0, 1.0)
		var largura_fator: float
		var r_flip: Rect2
		if t_revelar < 0.5:
			largura_fator = lerpf(1.0, 0.08, interpolar_suave(t_revelar / 0.5))
			r_flip = Rect2(Vector2(origem.get_center().x - origem.size.x * largura_fator * 0.5, origem.position.y), Vector2(origem.size.x * largura_fator, origem.size.y))
			desenhar_verso_baralho(r_flip)
		else:
			largura_fator = lerpf(0.08, 1.0, interpolar_suave((t_revelar - 0.5) / 0.5))
			r_flip = Rect2(Vector2(origem.get_center().x - origem.size.x * largura_fator * 0.5, origem.position.y), Vector2(origem.size.x * largura_fator, origem.size.y))
			desenhar_carta_em_retangulo(r_flip, animacao_compra_cor)
		return

	var t_mover: float = interpolar_suave((animacao_compra_tempo - DURACAO_ANIMACAO_REVELAR_BARALHO) / DURACAO_ANIMACAO_MOVER_CARTA_ESCOLHIDA)
	var centro_mover: Vector2 = origem.get_center().lerp(destino.get_center(), t_mover)
	var lado_mover: float = lerpf(origem.size.x * 0.98, destino.size.x * 0.98, t_mover)
	desenhar_carta(centro_mover, lado_mover, animacao_compra_cor)

func escrever_ajustado(texto: String, x: float, y: float, largura_maxima: float, tamanho: int, cor: Color = COR_TEXTO) -> void:
	var chave: String = "%s|%s|%d|%s" % [texto, str(floorf(largura_maxima)), tamanho, cor.to_html()]
	var fonte_tamanho: int = int(v209_fontes.get(chave, -1))
	if fonte_tamanho < 0:
		fonte_tamanho = tamanho
		while fonte_tamanho > 9 and ui_fonte_para(cor, fonte_tamanho).get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, fonte_tamanho).x > floorf(largura_maxima):
			fonte_tamanho -= 1
		if v209_fontes.size() >= 512:
			v209_fontes.clear()
		v209_fontes[chave] = fonte_tamanho
	escrever(texto, Vector2(x, y), fonte_tamanho, cor)

func desenhar_area_objetivos() -> void:
	ui_superficie(area_objetivos, UI_PAINEL, UI_BORDA, 10, true)
	v200_texto_central_ajustado("Objetivos", area_objetivos.get_center().x, area_objetivos.position.y + 19.0, area_objetivos.size.x - 16.0, 15, COR_TEXTO)
	var dados: Dictionary = jogadores[jogador_atual]
	var transicao: bool = juice_transicao_visivel()
	var t_etapa: float = juice_progresso(juice_transicao_objetivos) if transicao else 1.0

	var objetivos: Array[Dictionary] = dados["objetivos"]
	if transicao and t_etapa < 0.26:
		juice_desenhar_saida_objetivos(t_etapa / 0.26)
	for i in range(objetivos.size()):
		if objetivos[i].is_empty():
			continue # 2 segundos sem carta depois de concluir.
		if transicao and t_etapa < 0.26 + float(i) * 0.085:
			continue
		var r: Rect2 = retangulo_objetivo_ativo(i)
		var id_visual: String = str(objetivos[i].get("id", ""))
		var arquivando: bool = indice_cenario_em_revisao < 0 and not juice_arquivo.is_empty() and int(juice_arquivo.get("dono", -1)) == jogador_atual and id_visual == str(juice_arquivo.get("carta", {}).get("id", ""))
		if arquivando or (indice_cenario_em_revisao < 0 and celebracao_objetivo_ativa and linhas_pontuadas.has(id_visual)):
			continue
		var entrada: float = float(juice_entradas.get("%d:%s" % [jogador_atual, id_visual], -10.0))
		var t_entrada: float = clampf((juice_relogio - entrada) / (0.34 * juice_fator_tempo()), 0.0, 1.0)
		if transicao:
			t_entrada = clampf((t_etapa - 0.26 - float(i) * 0.085) / 0.42, 0.0, 1.0)
		var r_visual: Rect2 = r
		if t_entrada < 1.0 and indice_cenario_em_revisao < 0:
			r_visual = Rect2(r.position + Vector2(0, (1.0 - interpolar_suave(t_entrada)) * 12.0), r.size)
		if t_entrada < 0.35 and indice_cenario_em_revisao < 0:
			var largura_verso: float = r_visual.size.x * maxf(0.04, 1.0 - t_entrada / 0.35)
			var verso: Rect2 = Rect2(Vector2(r_visual.get_center().x - largura_verso * 0.5, r_visual.position.y), Vector2(largura_verso, r_visual.size.y))
			retangulo(verso, Color("563720"), COR_OURO)
		else:
			var largura_frente: float = clampf((t_entrada - 0.35) / 0.35, 0.04, 1.0)
			if t_entrada < 0.70 and indice_cenario_em_revisao < 0:
				draw_set_transform(Vector2(r_visual.get_center().x * (1.0 - largura_frente), 0), 0.0, Vector2(largura_frente, 1.0))
			desenhar_objetivo(objetivos[i], r_visual, i, false, str(objetivos[i].get("classe", "flor")) != "fada")
			draw_set_transform(Vector2.ZERO)
		if t_entrada < 1.0 and str(objetivos[i].get("classe", "flor")) == "fada":
			draw_rect(r_visual.grow(2.0), Color(0.68, 0.81, 1.0, 1.0 - t_entrada), false, 2.5)
		if transicao and t_entrada > 0.70:
			juice_desenhar_realce_nova_etapa(r, t_entrada, str(objetivos[i].get("classe", "flor")) == "fada")
		if aula_duelo_ativa() and aula_passo_humano() == 0 and jogador_atual == 0 and not celebracao_objetivo_ativa and indice_cenario_em_revisao < 0 and str(objetivos[i].get("id", "")) == str(aula_plano().get("objetivo", "")):
			var pulso_inicio: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.006)
			draw_rect(r.grow(1.0), Color(0.42, 0.75, 1.0, 0.35 + 0.35 * pulso_inicio), false, 1.5)
		if aula_aviso_fada_ativo() and str(objetivos[i].get("classe", "flor")) == "fada":
			aula_realcar_novo_objetivo_fada(r)
		if aula_guiada_ativa() and jogador_atual == 0 and not celebracao_objetivo_ativa and indice_cenario_em_revisao < 0 and str(objetivos[i].get("id", "")) == str(aula_plano().get("objetivo", "")):
			var objetivo_de_rotacao: bool = i == aula_indice_rotacao()
			if not objetivo_de_rotacao or aula_rotacao_pendente():
				draw_rect(r.grow(2.0), Color("70bfff"), false, 2.5)
		if celebracao_objetivo_ativa and celebracao_objetivo_jogador == jogador_atual and celebracao_objetivo_indice == i:
			var pulso: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.009)
			draw_rect(r.grow(3.0), Color(1.0, 0.73, 0.11, 0.18 + pulso * 0.09), false, 6.0)
			draw_rect(r.grow(2.0), Color(1.0, 0.90, 0.32, 0.77 + 0.20 * pulso), false, 2.6)
		if feel_previsao_ids.has(id_visual) and not celebracao_objetivo_ativa:
			var brilho_possivel: float = 0.55 + 0.20 * sin(juice_relogio * 5.0)
			draw_rect(r.grow(1.0), Color(1.0, 0.81, 0.36, brilho_possivel), false, 2.0)

	# Prévias da mão normal: desenhar abaixo da meta, sem área de interação.
	var previas: Array = aula_previa_objetivos(jogador_atual)
	for i in range(previas.size()):
		var r_previa: Rect2 = retangulo_objetivo_com_slots(i + 1, 3)
		desenhar_objetivo(previas[i], r_previa, -1, false, false)
		# Composição de 32% de opacidade sobre o fundo sólido do painel.
		draw_rect(r_previa.grow(3.0), Color("302722", 0.68))

	# Uma peça por cor, com contador. Os pólens em trânsito aparecem apenas ao pousar.
	var inventario: Dictionary = dados["polens"]
	for cor in CORES:
		var quantidade: int = int(inventario.get(cor, 0))
		if not (modo_partida == "maquina" and jogador_atual >= 1):
			for lote in animacoes_coleta_aula:
				if int(lote.get("dono", -1)) == jogador_atual and str(lote.get("cor", "")) == cor:
					quantidade -= maxi(0, int(lote.get("quantidade", 0)) - int(lote.get("chegados", 0)))
		var centro: Vector2 = centro_grupo_polen(cor)
		var raio: float = 6.0
		for lote in juice_reserva_pousos:
			if int(lote.get("dono", -1)) == jogador_atual and str(lote.get("cor", "")) == cor:
				var t: float = clampf((juice_relogio - float(lote["inicio"])) / (0.34 * juice_fator_tempo()), 0.0, 1.0)
				raio *= 1.0 + 0.22 * sin(t * PI)
				break
		# Zero permanece visível para facilitar a comparação entre cores.
		desenhar_polen_brilhante(centro, raio, cor)
		var texto: String = str(maxi(0, quantidade))
		var largura_texto: float = area_contadores_polens.size.x / float(CORES.size()) - 18.0
		escrever_ajustado(texto, centro.x + 9.0, centro.y + 4.0, largura_texto, 13, COR_TEXTO)

func pontuacao_parcial_alternativa(dados: Dictionary) -> int:
	# Placar provisório: objetivos já concluídos + pólens guardados +
	# bônus de trincas já formadas. Pólens ainda nas flores não pontuam.
	var total: int = int(dados.get("pontos_base", 0))
	var estoque: Dictionary = dados.get("polens", {})
	for cor in CORES:
		var quantidade: int = int(estoque.get(cor, 0))
		total += quantidade + 2 * floori(float(quantidade) / 3.0)
	return total

func retangulo_linha_placar(indice: int) -> Rect2:
	var interior: Rect2 = Rect2(area_historico.position + Vector2(4.0, 4.0), area_historico.size - Vector2(8.0, 8.0))
	var quantidade: int = maxi(1, jogadores.size())
	var intervalo: float = 4.0
	var largura: float = (interior.size.x - intervalo * float(quantidade - 1)) / float(quantidade)
	return Rect2(interior.position.x + float(indice) * (largura + intervalo), interior.position.y, largura, interior.size.y)

func desenhar_placar_compacto() -> void:
	ui_superficie(area_historico, UI_PAINEL, UI_BORDA, 10, false)
	for i in range(jogadores.size()):
		var r: Rect2 = retangulo_linha_placar(i)
		var ativo: bool = i == jogador_atual
		var fundo: Color = Color("454137") if ativo else Color("2a2521")
		var borda: Color = Color("a99a76") if ativo else Color("65584a")
		ui_superficie(r, fundo, borda, 7, false)
		var valor: String = str(pontuacao_parcial_alternativa(jogadores[i]))
		var cor_fada: Color = cor_visual_da_fada(i)
		var raio_externo: float = clampf(r.size.x * 0.095, 4.0, 7.0)
		var espaco: float = clampf(r.size.x * 0.065, 2.0, 5.0)
		var raio_estrela: float = clampf(r.size.x * 0.10, 4.0, 8.0)
		var largura_numero: float = maxf(1.0, r.size.x - 2.0 * raio_externo - 2.0 * espaco - 2.0 * raio_estrela - 8.0)
		var tamanho_valor: int = 22
		while tamanho_valor > 10 and ui_fonte_para(COR_PRATA, tamanho_valor).get_string_size(valor, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_valor).x > largura_numero:
			tamanho_valor -= 1
		var largura_texto: float = ui_fonte_para(COR_PRATA, tamanho_valor).get_string_size(valor, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_valor).x
		var inicio: float = r.get_center().x - (2.0 * raio_externo + 2.0 * espaco + largura_texto + 2.0 * raio_estrela) * 0.5
		var centro_ponto: Vector2 = Vector2(inicio + raio_externo, r.get_center().y)
		draw_circle(centro_ponto, raio_externo, Color("b4a595"))
		draw_circle(centro_ponto, raio_externo - 1.2, cor_fada)
		escrever_ajustado(valor, inicio + 2.0 * raio_externo + espaco, r.get_center().y + float(tamanho_valor) * 0.34, largura_numero, tamanho_valor, COR_PRATA)
		# Estrela prateada depois do número, desenhada como vetor para não depender da fonte.
		var centro_estrela: Vector2 = Vector2(inicio + 2.0 * raio_externo + 2.0 * espaco + largura_texto + raio_estrela, r.get_center().y)
		var pontos_estrela: PackedVector2Array = PackedVector2Array()
		for ponta in range(10):
			var angulo: float = -PI * 0.5 + float(ponta) * PI / 5.0
			var raio: float = raio_estrela if ponta % 2 == 0 else raio_estrela * 0.46
			pontos_estrela.append(centro_estrela + Vector2(cos(angulo), sin(angulo)) * raio)
		draw_colored_polygon(pontos_estrela, COR_PRATA)
		juice_desenhar_ganho(i, r)

func desenhar_historico_objetivos() -> void:
	if not conquistas_abertas or jogadores.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.03, 0.02, 0.01, 0.81))
	ui_superficie(area_janela_conquistas, Color("342b26"), Color("bd995e"), 12, true)
	var historico: Array = jogadores[jogador_atual]["historico_objetivos"]
	escrever_ajustado("Objetivos concluídos (%d)" % historico.size(),
		area_janela_conquistas.position.x + 10.0, area_janela_conquistas.position.y + 25.0,
		area_janela_conquistas.size.x - 68.0, 17, COR_OURO)
	desenhar_botao_arredondado(botao_fechar_conquistas)
	escrever_texto_botao_centralizado("X", botao_fechar_conquistas, 16)
	if historico.is_empty():
		escrever_ajustado("Nenhum objetivo concluído ainda.", area_janela_conquistas.position.x + 12.0,
			area_janela_conquistas.position.y + 66.0, area_janela_conquistas.size.x - 24.0, 14, COR_TEXTO_FRACO)
		return
	var capacidade: int = capacidade_pagina_historico()
	var total_paginas: int = maxi(1, ceili(float(historico.size()) / float(capacidade)))
	var pagina: int = clampi(pagina_historico[jogador_atual], 0, total_paginas - 1)
	var inicio: int = pagina * capacidade
	for i in range(inicio, mini(historico.size(), inicio + capacidade)):
		desenhar_objetivo(historico[i], retangulo_objetivo_historico(i), i, true)
	if total_paginas > 1:
		desenhar_botao_arredondado(botao_anterior_conquistas)
		escrever_texto_botao_centralizado("‹", botao_anterior_conquistas, 20)
		desenhar_botao_arredondado(botao_proximo_conquistas)
		escrever_texto_botao_centralizado("›", botao_proximo_conquistas, 20)
		escrever_centralizado("%d / %d" % [pagina + 1, total_paginas], area_janela_conquistas.get_center().x,
			area_janela_conquistas.end.y - 24.0, 16, COR_TEXTO)

func escrever_centralizado(texto: String, centro_x: float, linha_base_y: float, tamanho: int, cor: Color) -> void:
	var largura: float = ui_fonte_para(cor, tamanho).get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
	escrever(texto, Vector2(centro_x - largura * 0.5, linha_base_y), tamanho, cor)

func quebrar_texto_instrucoes(texto: String, largura: float, tamanho: int) -> Array[String]:
	var chave: String = "%d|%s|%s" % [tamanho, str(largura), texto]
	if perf_textos.has(chave):
		return perf_textos[chave]
	var linhas: Array[String] = []
	var atual: String = ""
	for palavra in texto.split(" ", false):
		var candidata: String = str(palavra) if atual == "" else atual + " " + str(palavra)
		if atual != "" and fonte.get_string_size(candidata, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x > largura:
			linhas.append(atual)
			atual = str(palavra)
		else:
			atual = candidata
	if atual != "":
		linhas.append(atual)
	if perf_textos.size() >= 256:
		perf_textos.clear()
	perf_textos[chave] = linhas
	return linhas

func instrucoes_da_jogada() -> String:
	if turno_da_maquina():
		return texto_vez_atual()
	if mobile_arrastando_coletiva:
		return "Solte numa casa livre para plantar."
	if animacao_setup_ativa:
		return "Preparando o jardim…"
	if celebracao_objetivo_ativa:
		if not juice_arquivo.is_empty():
			return "Objetivo concluído! +%s" % rotulo_estrela_compacto(int(juice_arquivo["carta"].get("pontos_finais", 0)))
		return "Objetivo concluído!"
	if etapa_fada == "movendo":
		var ganho: Dictionary = juice_ganhos_placar.get(jogador_atual, {})
		if not ganho.is_empty():
			return "Coleta: +%s%s" % [rotulo_estrela_compacto(int(ganho["valor"])), " · bônus de trinca!" if int(ganho["bonus"]) > 0 else ""]
		return "A fada está voando."
	if escolha_objetivo_ativa:
		return "Escolha um objetivo concluído."
	if etapa_fada in ["oferta", "escolha"]:
		return "Escolha uma fada azul ou toque em Cancelar Voo."
	if animacao_compra_ativa:
		return "A flor está indo para sua mão."
	if movimento_pendente:
		return "Pegue uma flor" if flor_na_mao == "" else "Repondo a flor movida…"
	if origem_selecionada != CELULA_INVALIDA:
		return "Escolha uma casa azul para mover a flor."
	if flor_na_mao != "":
		return "Jogue na mesa, ou mova uma flor"
	return "Arraste a coletiva ou pegue uma flor"

func pratica_com_dicas_breves() -> bool:
	if aula_duelo_ativa():
		return true
	return estado_tela == "partida" and tutorial_pratica_livre and modo_partida in ["aprender", "aprender_novo"] and (eh_gamer() or eh_alternativa())

func dica_pratica_aprender() -> String:
	if aula_duelo_ativa():
		return aula_dica()
	if duplicacao_ativa:
		return "Os pólens das cores do objetivo duplicam suas estrelas."
	if animacao_setup_ativa:
		return "Observe o jardim e os desenhos dos seus objetivos."
	if escolha_objetivo_ativa:
		return "Escolha um dos objetivos atendidos. Só um rende estrelas por jogada."
	if celebracao_objetivo_ativa:
		return "Objetivo concluído! Veja suas estrelas no placar."
	if etapa_fada in ["oferta", "escolha"]:
		return "Toque na fada azul ou em Cancelar Voo."
	if etapa_fada == "movendo":
		return "A fada recolhe pólens no caminho e deixa um nas flores vazias."
	if movimento_pendente:
		return "Escolha uma carta para repor a flor movida." if flor_na_mao == "" else "A carta escolhida preenche o espaço vazio."
	if origem_selecionada != CELULA_INVALIDA:
		return "Mova a flor para uma casa azul vizinha; depois reponha o espaço."
	if flor_na_mao != "":
		return "Plante no azul ou mova uma flor da borda."
	var concluidos: int = int(jogadores[jogador_atual].get("objetivos_concluidos", 0)) if not jogadores.is_empty() else 0
	if concluidos >= 3 and eh_alternativa():
		if turnos_jogados % 2 == 0:
			return "Cumpra os objetivos de Fada com seus voos para ganhar estrelas."
		return "Cada pólen vale 1 estrela; três da mesma cor valem 5 no total."
	match turnos_jogados % 5:
		0:
			return "Escolha a carta coletiva ou o baralho. Forme os desenhos dos objetivos."
		1:
			return "Experimente mover uma flor da borda e repor sua posição."
		2:
			return "Cada pólen vale 1 estrela; três da mesma cor valem 5 no total." if eh_alternativa() else "No final, 1 pólen da cor de cada flor duplica o objetivo concluído."
		3:
			return "Após 3 objetivos: 2 Difíceis e 2 de Fada." if eh_alternativa() else "Após 3 Médios, receba 3 Difíceis. Pares restantes da mesma cor valem 1 estrela."
		_:
			return "Toque no canto superior direito do objetivo para girar. O treino termina com 6 conquistas."

func aula_nav_mensagem(prever: bool = true) -> Dictionary:
	if turno_da_maquina():
		return {"titulo": texto_vez_atual(), "texto": "", "aviso": false}
	var tutorial: bool = pratica_com_dicas_breves()
	var titulo: String = aula_titulo_etapa() if tutorial else texto_vez_atual()
	var texto: String = dica_pratica_aprender() if tutorial else instrucoes_da_jogada()
	if not tutorial and juice_transicao_visivel():
		texto = "Nova etapa: dois objetivos difíceis e dois de fada."
	var aviso: bool = aula_aviso_licao_ativo() or aula_aviso_fada_ativo()
	if aula_aviso_fada_ativo():
		titulo = "Etapa avançada"
		texto = "Agora: 2 objetivos difíceis e 2 de fada. Cumpra os desafios de voo para ganhar estrelas."
	elif aula_aviso_licao_ativo():
		match aula_aviso_licao_tipo:
			"polens_objetivo":
				titulo = "Objetivo concluído!"
				texto = "Você ganhou as estrelas da carta. Cada flor do desenho recebe 1 pólen extra (máximo 4)."
			"inicio":
				titulo = "Como vencer"
				texto = "★ A estrela prateada representa um ponto de vitória. Vence quem somar mais estrelas."
			_:
				titulo = "Estrelas dos pólens"
				texto = "Cada pólen guardado vale 1 estrela. Três da mesma cor valem 5 estrelas no total."
	elif prever and etapa_fada in ["oferta", "escolha"] and not turno_da_maquina():
		var indice: int = mobile_indice_previsao_voo()
		if indice >= 0:
			var previsao: Dictionary = mobile_prever_rota(indice, destino_da_fada)
			texto = "Fada %d: %d pólens · +%s · produz %d. Solte para voar." % [int(fadas[indice]["numero"]), previsao["coleta"], rotulo_estrela_compacto(int(previsao["estrelas"])), previsao["produz"]]
	return {"titulo": titulo, "texto": texto, "aviso": aviso}

func desenhar_dica_pratica_aprender() -> void:
	var faixa: Rect2 = area_dica_aprender
	if not faixa.has_area():
		return
	var tutorial: bool = pratica_com_dicas_breves()
	var pagina: Dictionary = aula_nav_mensagem()
	var aviso: bool = bool(pagina["aviso"])
	# Repinta somente o prolongamento da mesa (sem painel, borda ou sombra).
	# Protege a leitura mesmo quando uma flor ultrapassa o limite visual ao fazer zoom.
	draw_rect(faixa, UI_MESA)
	# Durante qualquer turno automático, mostrar somente a cor ativa.
	if turno_da_maquina():
		aula_texto_modal(texto_vez_atual(), faixa.grow(-4.0), 17)
		return
	if tutorial:
		aula_nav_desenhar_setas()
		if not aviso and aula_nav_indice < 0 and not aula_nav_animando and not aula_nav_pressao and aula_pode_pedir_ajuda():
			var botao: Rect2 = aula_retangulo_ajuda()
			desenhar_botao_arredondado(botao)
			escrever_texto_botao_centralizado("Ocultar" if aula_ajuda_visivel() else "Dica", botao, 13)
		return # texto renderizado no Control recortado, sem sobrepor as setas.
	# O jogador ativo já está destacado no placar; basta a instrução contextual.
	var corpo: Rect2 = faixa.grow(-4.0)
	aula_texto_modal(str(pagina["texto"]), corpo, 17)

# v204 — mensagens em um carrossel recortado, sem alterar regras ou desfazer jogadas.
func aula_nav_criar() -> void:
	aula_nav_clip = Control.new()
	aula_nav_clip.name = "MensagensTutorial"
	aula_nav_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aula_nav_clip.clip_contents = true
	aula_nav_clip.hide()
	add_child(aula_nav_clip)
	aula_nav_canvas = Node2D.new()
	aula_nav_canvas.draw.connect(aula_nav_desenhar_paginas)
	aula_nav_clip.add_child(aula_nav_canvas)

func aula_nav_limpar() -> void:
	aula_nav_historico.clear()
	aula_nav_atual.clear()
	aula_nav_visual.clear()
	aula_nav_saida.clear()
	aula_nav_indice = -1
	aula_nav_token = -1
	aula_nav_animando = false
	aula_nav_cancelar_gesto()
	if is_instance_valid(aula_nav_clip):
		aula_nav_clip.hide()

func aula_nav_cancelar_gesto() -> void:
	aula_nav_pressao = false
	aula_nav_pressao_bloqueada = false
	aula_nav_botao = 0
	if not aula_nav_animando:
		aula_nav_desvio = 0.0
	if is_instance_valid(aula_nav_canvas):
		aula_nav_canvas.queue_redraw()

func aula_nav_ativo() -> bool:
	return not turno_da_maquina() and pratica_com_dicas_breves() and estado_tela == "partida" and not partida_encerrada and not conquistas_abertas and not escolha_objetivo_ativa and not escolhas_iniciais_pendentes and not tutorial_final_pendente and mobile_objetivo_ampliado.is_empty()

func aula_nav_area_texto() -> Rect2:
	return Rect2(area_dica_aprender.position + Vector2(5.0, 3.0), area_dica_aprender.size - Vector2(60.0, 6.0))

func aula_nav_retangulo_seta(direcao: int) -> Rect2:
	var altura: float = (area_dica_aprender.size.y - 8.0) * 0.5
	return Rect2(area_dica_aprender.end.x - 50.0, area_dica_aprender.position.y + 3.0 + (altura + 2.0 if direcao > 0 else 0.0), 46.0, altura)

func aula_nav_registrar() -> void:
	if not aula_nav_ativo():
		return
	var pagina: Dictionary = aula_nav_mensagem(false)
	aula_nav_atual = pagina
	aula_nav_visual = aula_nav_mensagem() if not bool(pagina["aviso"]) and etapa_fada in ["oferta", "escolha"] else pagina.duplicate()
	# Não encher o histórico com cada nota de coleta ou frame de animação.
	var estavel: bool = bool(pagina["aviso"]) or not (animacao_setup_ativa or animacao_compra_ativa or celebracao_objetivo_ativa or etapa_fada == "movendo" or movimento_pendente and flor_na_mao != "" or not juice_plantar.is_empty())
	if estavel and str(pagina["texto"]) != "" and (aula_nav_historico.is_empty() or aula_nav_historico.back() != pagina):
		aula_nav_historico.append(pagina.duplicate())
		if aula_nav_historico.size() > 120:
			aula_nav_historico.pop_front()
			if aula_nav_indice >= 0:
				aula_nav_indice = maxi(0, aula_nav_indice - 1)

func aula_nav_iniciar_aviso() -> void:
	if aula_nav_token != identificador_partida:
		aula_nav_limpar()
		aula_nav_token = identificador_partida
	mobile_limpar_intencao()
	aula_nav_registrar()
	# A lição recém-desbloqueada tem prioridade sobre uma revisão antiga.
	aula_nav_indice = -1
	aula_nav_cancelar_gesto()
	queue_redraw()

func aula_nav_pagina() -> Dictionary:
	if aula_nav_indice >= 0 and aula_nav_indice < aula_nav_historico.size():
		return aula_nav_historico[aula_nav_indice]
	return aula_nav_visual

func aula_nav_anterior() -> int:
	if aula_nav_indice >= 0:
		return aula_nav_indice - 1
	var ultimo: int = aula_nav_historico.size() - 1
	if ultimo >= 0 and aula_nav_historico[ultimo] == aula_nav_atual:
		ultimo -= 1
	return ultimo

func aula_nav_pode(direcao: int) -> bool:
	if direcao < 0:
		return aula_nav_anterior() >= 0
	return aula_nav_indice >= 0 or aula_aviso_licao_ativo() or aula_aviso_fada_ativo()

func aula_nav_vizinha(direcao: int) -> Dictionary:
	if not aula_nav_pode(direcao):
		return {}
	if direcao < 0:
		return aula_nav_historico[aula_nav_anterior()]
	if aula_nav_indice >= 0:
		var proximo: int = aula_nav_indice + 1
		if proximo < aula_nav_historico.size():
			return aula_nav_historico[proximo]
		return aula_nav_visual
	return {"titulo": "Avançar", "texto": "Solte para concluir a leitura.", "aviso": false}

func aula_nav_mudar(direcao: int) -> void:
	if aula_nav_animando or not aula_nav_pode(direcao):
		return
	aula_nav_saida = aula_nav_pagina().duplicate()
	aula_nav_direcao = direcao
	aula_nav_anim_de = aula_nav_desvio
	aula_nav_anim_t = 0.0
	aula_nav_animando = true
	if direcao < 0:
		aula_nav_indice = aula_nav_anterior()
	elif aula_nav_indice >= 0:
		var proximo: int = aula_nav_indice + 1
		# Voltar à página viva não confirma a lição; só um novo avanço o faz.
		if proximo >= aula_nav_historico.size() or (proximo == aula_nav_historico.size() - 1 and aula_nav_historico[proximo] == aula_nav_atual):
			aula_nav_indice = -1
		else:
			aula_nav_indice = proximo
	elif aula_aviso_licao_ativo():
		aula_fechar_aviso_licao()
	elif aula_aviso_fada_ativo():
		aula_fechar_aviso_fada()
	aula_nav_registrar()
	queue_redraw()

func aula_nav_atualizar(delta: float) -> void:
	if not is_instance_valid(aula_nav_clip):
		return
	if aula_nav_token != identificador_partida:
		aula_nav_limpar()
		aula_nav_token = identificador_partida
	if not aula_nav_ativo():
		aula_nav_clip.hide()
		aula_nav_animando = false
		aula_nav_indice = -1
		aula_nav_cancelar_gesto()
		return
	if pausa_saida_ativa:
		return
	var anterior: Dictionary = aula_nav_visual.duplicate()
	var quantidade: int = aula_nav_historico.size()
	aula_nav_registrar()
	var r: Rect2 = aula_nav_area_texto()
	var mudou: bool = anterior != aula_nav_visual or quantidade != aula_nav_historico.size() or not aula_nav_clip.visible or aula_nav_clip.position != r.position or aula_nav_clip.size != r.size
	aula_nav_clip.position = r.position
	aula_nav_clip.size = r.size
	aula_nav_clip.show()
	if aula_nav_animando:
		aula_nav_anim_t = minf(1.0, aula_nav_anim_t + delta / 0.25)
		var alvo: float = -float(aula_nav_direcao) * r.size.x
		aula_nav_desvio = lerpf(aula_nav_anim_de, alvo, interpolar_suave(aula_nav_anim_t))
		mudou = true
		if aula_nav_anim_t >= 1.0:
			aula_nav_animando = false
			aula_nav_desvio = 0.0
			aula_nav_saida.clear()
	if mudou or aula_nav_pressao:
		aula_nav_canvas.queue_redraw()
		queue_redraw()

func aula_nav_input(event: InputEvent) -> bool:
	if not aula_nav_ativo() or pausa_saida_ativa:
		return false
	if event is InputEventMouseMotion and aula_nav_pressao:
		if aula_nav_animando or aula_nav_pressao_bloqueada:
			return true
		var dx: float = event.position.x - aula_nav_inicio.x
		if absf(dx) > 9.0:
			aula_nav_botao = 0
		var direcao: int = 1 if dx < 0.0 else -1
		aula_nav_desvio = clampf(dx, -aula_nav_area_texto().size.x, aula_nav_area_texto().size.x) if aula_nav_pode(direcao) else clampf(dx * 0.16, -16.0, 16.0)
		aula_nav_canvas.queue_redraw()
		queue_redraw()
		return true
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return false
	if event.pressed:
		if not area_dica_aprender.has_point(event.position):
			return false
		if aula_nav_animando:
			aula_nav_pressao = true
			aula_nav_pressao_bloqueada = true
			aula_nav_inicio = event.position
			aula_nav_botao = 0
			return true
		if aula_nav_indice < 0 and aula_pode_pedir_ajuda() and aula_retangulo_ajuda().has_point(event.position):
			return false
		mobile_limpar_intencao()
		aula_nav_pressao = true
		aula_nav_pressao_bloqueada = false
		aula_nav_inicio = event.position
		aula_nav_botao = -1 if aula_nav_retangulo_seta(-1).has_point(event.position) else (1 if aula_nav_retangulo_seta(1).has_point(event.position) else 0)
		aula_nav_desvio = 0.0
		return true
	if not aula_nav_pressao:
		return area_dica_aprender.has_point(event.position) and aula_nav_animando
	if aula_nav_animando or aula_nav_pressao_bloqueada:
		aula_nav_cancelar_gesto()
		return true
	var desloc: Vector2 = event.position - aula_nav_inicio
	var direcao_soltar: int = 0
	if absf(desloc.x) >= 36.0 and absf(desloc.x) > absf(desloc.y) * 1.2:
		direcao_soltar = 1 if desloc.x < 0.0 else -1
	elif desloc.length() < 14.0 and aula_nav_botao != 0 and aula_nav_retangulo_seta(aula_nav_botao).has_point(event.position):
		direcao_soltar = aula_nav_botao
	aula_nav_pressao = false
	aula_nav_botao = 0
	if direcao_soltar != 0 and aula_nav_pode(direcao_soltar):
		aula_nav_mudar(direcao_soltar)
	else:
		# Voltar ao centro se o gesto não atingiu o limiar.
		aula_nav_anim_de = aula_nav_desvio
		aula_nav_direcao = 0
		aula_nav_anim_t = 0.0
		aula_nav_animando = absf(aula_nav_desvio) > 0.1
		aula_nav_saida.clear()
	queue_redraw()
	return true

func aula_nav_desenhar_setas() -> void:
	for direcao in [-1, 1]:
		var r: Rect2 = aula_nav_retangulo_seta(direcao)
		var disponivel: bool = aula_nav_pode(direcao) and not aula_nav_animando
		var preenchimento: Color = Color("594638") if disponivel else Color("382f29")
		ui_superficie(r, preenchimento, Color("aa8d64") if disponivel else Color("56483b"), 6)
		var c: Vector2 = r.get_center()
		var d: float = float(direcao)
		var cor: Color = COR_OURO if disponivel else Color("84766b")
		draw_polyline(PackedVector2Array([c + Vector2(-5.0 * d, -8.0), c + Vector2(4.0 * d, 0.0), c + Vector2(-5.0 * d, 8.0)]), cor, 3.0, true)

func aula_nav_desenhar_pagina(pagina: Dictionary, x: float, revisao: bool = false) -> void:
	if pagina.is_empty():
		return
	var largura: float = aula_nav_clip.size.x
	var titulo: String = str(pagina.get("titulo", ""))
	if revisao and aula_nav_indice >= 0 and not aula_nav_animando and not aula_nav_pressao:
		titulo = "Revisão · " + titulo
	var texto: String = str(pagina.get("texto", ""))
	var tamanho_titulo: int = 18
	var largura_titulo: float = largura - 12.0
	if not revisao and aula_nav_indice < 0 and aula_pode_pedir_ajuda():
		largura_titulo -= 90.0
	while tamanho_titulo > 11 and ui_fonte_para(COR_OURO, tamanho_titulo).get_string_size(titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_titulo).x > largura_titulo:
		tamanho_titulo -= 1
	escrever_com_estrela_prateada(aula_nav_canvas, ui_fonte_para(COR_OURO, tamanho_titulo), titulo, Vector2(x + 7.0, 22.0), tamanho_titulo, COR_OURO, largura_titulo)
	var tamanho: int = 17
	var linhas: Array[String] = quebrar_texto_instrucoes(texto, largura - 16.0, tamanho)
	var topo_corpo: float = 43.0 if not revisao and aula_nav_indice < 0 and aula_pode_pedir_ajuda() else 27.0
	var altura: float = aula_nav_clip.size.y - topo_corpo
	while tamanho > 11 and float(linhas.size()) * float(tamanho + 4) > altura:
		tamanho -= 1
		linhas = quebrar_texto_instrucoes(texto, largura - 16.0, tamanho)
	var passo: float = float(tamanho + 4)
	var y: float = topo_corpo + fonte.get_ascent(tamanho)
	for linha in linhas:
		escrever_com_estrela_prateada(aula_nav_canvas, fonte, linha, Vector2(x + 7.0, y), tamanho, COR_TEXTO, largura - 16.0)
		y += passo

func aula_nav_desenhar_paginas() -> void:
	var largura: float = aula_nav_clip.size.x
	if aula_nav_animando and not aula_nav_saida.is_empty() and aula_nav_direcao != 0:
		aula_nav_desenhar_pagina(aula_nav_saida, aula_nav_desvio, true)
		aula_nav_desenhar_pagina(aula_nav_pagina(), aula_nav_desvio + float(aula_nav_direcao) * largura, aula_nav_indice >= 0)
	else:
		aula_nav_desenhar_pagina(aula_nav_pagina(), aula_nav_desvio, aula_nav_indice >= 0)
		if aula_nav_pressao and absf(aula_nav_desvio) > 1.0:
			var direcao: int = 1 if aula_nav_desvio < 0.0 else -1
			aula_nav_desenhar_pagina(aula_nav_vizinha(direcao), aula_nav_desvio + float(direcao) * largura, true)

func desenhar_instrucoes_da_jogada() -> void:
	desenhar_dica_pratica_aprender()

func desenhar_ajuda_tutorial_novo() -> void:
	return

func desenhar_ajuda_aprender() -> void:
	# A Original usa agora a mesma janela flutuante e os mesmos destaques
	# das primeiras seis jogadas. As ultimas duas tem texto independente.
	return

func desenhar_fada_decorativa_menu(centro: Vector2, altura: float, indice_textura: int) -> void:
	var textura: Texture2D = texturas_fadas.get(indice_textura) as Texture2D
	if textura != null:
		var largura: float = altura * float(textura.get_width()) / maxf(1.0, float(textura.get_height()))
		var ret: Rect2 = Rect2(centro - Vector2(largura, altura) * 0.5, Vector2(largura, altura))
		draw_texture_rect(textura, ret, false, Color.WHITE)
		return
	var contorno: Color = Color(1, 1, 1, 0.82) if indice_textura == 1 else Color(0, 0, 0, 0.72)
	var corpo: Color = Color("f4f4f6") if indice_textura == 1 else Color("3d4046")
	var escala: float = altura * 0.34
	for lado_asa in [-1.0, 1.0]:
		var ponta_x: float = centro.x + lado_asa * escala * 1.18
		var asa_alta: PackedVector2Array = PackedVector2Array([
			centro + Vector2(lado_asa * escala * 0.15, -escala * 0.05),
			Vector2(ponta_x, centro.y - escala * 1.30),
			centro + Vector2(lado_asa * escala * 0.80, escala * 0.03)
		])
		var asa_baixa: PackedVector2Array = PackedVector2Array([
			centro + Vector2(lado_asa * escala * 0.15, escala * 0.10),
			Vector2(ponta_x, centro.y + escala * 1.15),
			centro + Vector2(lado_asa * escala * 0.73, escala * 0.08)
		])
		draw_colored_polygon(asa_alta, Color(0.92, 0.95, 0.98, 0.84))
		draw_colored_polygon(asa_baixa, Color(0.87, 0.91, 0.96, 0.76))
		draw_polyline(asa_alta, contorno, 2.0, true)
		draw_polyline(asa_baixa, contorno, 2.0, true)
	draw_circle(centro + Vector2(0.0, escala * 0.20), escala * 0.72, contorno)
	draw_circle(centro + Vector2(0.0, escala * 0.20), escala * 0.53, corpo)
	draw_circle(centro + Vector2(0.0, -escala * 0.40), escala * 0.43, contorno)
	draw_circle(centro + Vector2(0.0, -escala * 0.40), escala * 0.30, corpo.lightened(0.08))

func desenhar_tela_menu() -> void:
	# A abertura tem sua própria direção de arte, independente do antigo cartaz.
	if estado_tela == "inicio":
		desenhar_abertura_ilustrada()
		return
	var tela: Vector2 = get_viewport_rect().size
	var centro: Vector2 = tela * 0.5
	var largura_cartaz: float = minf(540.0, ui_area_segura().size.x - 28.0)
	var altura_cartaz: float = v200_altura_painel_menu(tela)
	var painel: Rect2 = Rect2(centro - Vector2(largura_cartaz, altura_cartaz) * 0.5,
		Vector2(largura_cartaz, altura_cartaz))
	var inicio: bool = estado_tela == "inicio"
	if estado_tela == "distribuicao_final":
		# Layout em tela cheia, com todos os objetivos lado a lado.
		desenhar_final_expandida()
		return
	if inicio:
		# Fundo inteiramente marrom, sem segunda camada clara ou faixa verde.
		draw_rect(Rect2(Vector2.ZERO, tela), UI_SUPERFICIE)
	else:
		ui_superficie(painel, UI_SUPERFICIE, Color("a98a5f"), 12, true)
	if estado_tela == "resultado":
		desenhar_resumo_pontuacao_final(painel)
		juice_desenhar_final(painel)
		return
	if estado_tela == "explicacao_pontuacao":
		desenhar_explicacao_pontuacao(painel)
		return
	if estado_tela in ["regras", "catalogo_objetivos"]:
		desenhar_tela_regras(painel)
		if estado_tela == "catalogo_objetivos":
			desenhar_cartas_catalogo(painel)
		return

	var centro_x: float = centro.x
	var tam_titulo: int = 28 if tela.x < 510.0 else 43
	if inicio:
		escrever_centralizado("JARDIM DAS FADAS", centro_x, painel.position.y + 68.0, tam_titulo, COR_OURO)
	elif estado_tela == "escolha_modo":
		escrever_centralizado("Jogar", centro_x, painel.position.y + 68.0, 38, COR_OURO)
		if painel.size.y >= 430.0:
			v200_texto_central_ajustado("Escolha como deseja jogar", centro_x, painel.position.y + 108.0, painel.size.x - 28.0, 20, COR_TEXTO)
	elif estado_tela == "escolha_quantidade_maquinas":
		v200_texto_central_ajustado("Participantes", centro_x, painel.position.y + 68.0, painel.size.x - 28.0, 36, COR_OURO)
		if painel.size.y >= 430.0:
			v200_texto_central_ajustado("Escolha o número de jogadores", centro_x, painel.position.y + 108.0, painel.size.x - 28.0, 20, COR_TEXTO)
	elif estado_tela == "escolha_maquina":
		v200_texto_central_ajustado("Dificuldade", centro_x, painel.position.y + 68.0, painel.size.x - 28.0, 36, COR_OURO)
		if painel.size.y >= 430.0:
			v200_texto_central_ajustado("Escolha o nível de desafio", centro_x, painel.position.y + 108.0, painel.size.x - 28.0, 20, COR_TEXTO)
	# No menu inicial permanecem a flor amarela decorativa e as fadas.
	# A flor lilas foi retirada de todas as telas de menu.
	var centro_flor: Vector2 = Vector2(centro_x, painel.position.y + altura_cartaz * 0.39)
	var raio: float = minf(62.0, altura_cartaz * 0.10)
	if inicio:
		desenhar_flor(centro_flor, raio * 1.03, "amarela")
		var altura_fada: float = raio * 2.72
		var deslocamento_lateral: float = raio * 2.55
		var base_y: float = centro_flor.y + raio * 0.06
		# Índices conferidos no carregamento: 0 = ESCURA (preta), 3 = MARROM clara.
		desenhar_fada_decorativa_menu(Vector2(centro_flor.x - deslocamento_lateral, base_y), altura_fada, 0)
		desenhar_fada_decorativa_menu(Vector2(centro_flor.x + deslocamento_lateral, base_y), altura_fada, 3)



func perf_criar_fundo() -> void:
	perf_fundo = Node2D.new()
	perf_fundo.name = "FundoEstatico"
	perf_fundo.show_behind_parent = true
	perf_fundo.draw.connect(perf_desenhar_fundo)
	add_child(perf_fundo)
	move_child(perf_fundo, 0)
	perf_sincronizar_fundo()

func perf_sincronizar_fundo() -> void:
	if not is_instance_valid(perf_fundo):
		return
	var tela: Vector2 = get_viewport_rect().size
	var inicio: bool = estado_tela == "inicio"
	if tela != perf_fundo_tela or inicio != perf_fundo_inicio:
		perf_fundo_tela = tela
		perf_fundo_inicio = inicio
		perf_fundo.queue_redraw()

func perf_desenhar_fundo() -> void:
	var tela: Vector2 = perf_fundo_tela
	perf_fundo.draw_rect(Rect2(Vector2.ZERO, tela), UI_FUNDO)
	if not perf_fundo_inicio:
		for n in range(30):
			var yy: float = float(n) * tela.y / 29.0
			perf_fundo.draw_line(Vector2(0.0, yy),
				Vector2(tela.x, yy + sin(float(n) * 2.3) * 5.0),
				Color(0.89, 0.61, 0.39, 0.022), 2.0)

func _draw() -> void:
	atualizar_layout(false)
	perf_sincronizar_fundo()
	# As janelas modais colocam Controls atrás do desenho principal. Nesses
	# poucos frames, manter o fundo também no pai para ocultá-los como antes.
	if not is_instance_valid(perf_fundo) or conquistas_abertas or aula_aviso_licao_ativo() or aula_aviso_fada_ativo() or not mobile_objetivo_ampliado.is_empty():
		var tela_modal: Vector2 = get_viewport_rect().size
		draw_rect(Rect2(Vector2.ZERO, tela_modal), UI_FUNDO)
		if estado_tela != "inicio":
			for n in range(30):
				var yy: float = float(n) * tela_modal.y / 29.0
				draw_line(Vector2(0.0, yy), Vector2(tela_modal.x, yy + sin(float(n) * 2.3) * 5.0), Color(0.89, 0.61, 0.39, 0.022), 2.0)

	if estado_tela != "partida":
		desenhar_tela_menu()
		return

	desenhar_tabuleiro()
	if aula_guiada_ativa():
		aula_desenhar_alvo()
	elif aula_ajuda_visivel():
		aula_desenhar_ajuda()
	desenhar_compra()
	desenhar_area_objetivos()
	if mostrar_placar_parcial():
		draw_rect(area_historico.merge(botao_encerrar), UI_MESA)
		desenhar_placar_compacto()
	desenhar_animacao_compra()
	juice_desenhar_arquivo()
	juice_desenhar_plantio()
	juice_desenhar_particulas()
	desenhar_voo_do_polen_automatico()
	desenhar_efeito_coleta_aula()
	desenhar_ajuda_aprender()
	desenhar_ajuda_tutorial_novo()
	desenhar_instrucoes_da_jogada()
	desenhar_icone_saida()
	# Ultima camada: a mini-janela de cores fica acima das flores e tutoriais.
	desenhar_seletor_pintura()
	feel_desenhar_recompensas()
	feel_desenhar_mao()
	if not mobile_objetivo_ampliado.is_empty():
		mobile_desenhar_objetivo_ampliado()
	if conquistas_abertas:
		juice_transformar_modal(area_janela_conquistas)
		desenhar_historico_objetivos()
		draw_set_transform(Vector2.ZERO)
	if juice_modal == "" and juice_relogio - juice_modal_inicio < 0.20:
		var t_fechar: float = (juice_relogio - juice_modal_inicio) / 0.20
		var r_fechar: Rect2 = juice_modal_retangulo.grow(-t_fechar * 8.0)
		draw_rect(r_fechar, Color(0.88, 0.69, 0.36, 0.14 * (1.0 - t_fechar)), false, 2.0)


# ==========================================================================
# v129 — Aprender: duelo com cenário, compras e adversário preparados.
# As conquistas, voos, deslocamentos e pontuação usam as regras da partida.
# ==========================================================================
func aula_duelo_ativa() -> bool:
	return aula_duelo and estado_tela == "partida" and not partida_encerrada

func aula_passo_humano() -> int:
	return int(jogadores[0].get("turnos_proprios", 0)) if not jogadores.is_empty() else 0

func aula_guiada_ativa() -> bool:
	return aula_duelo_ativa() and jogador_atual == 0 and aula_passo_humano() < AULA_TURNOS_GUIADOS

func aula_demonstracao_ativa() -> bool:
	return aula_guiada_ativa() and aula_passo_humano() < AULA_TURNOS_DEMONSTRACAO

func aula_plano() -> Dictionary:
	if not aula_guiada_ativa():
		return {}
	var planos: Array = AULA_ALTERNATIVA
	var passo: int = aula_passo_humano()
	if passo < 0 or passo >= planos.size():
		return {}
	return planos[passo]

func aula_origem() -> Vector2i:
	return aula_plano().get("origem", CELULA_INVALIDA)

func aula_destino() -> Vector2i:
	return aula_plano().get("destino", CELULA_INVALIDA)

func aula_cor_coletiva_a_partir_de(inicio: int) -> String:
	var planos: Array = AULA_ALTERNATIVA
	for i in range(inicio, planos.size()):
		if str(planos[i]["fonte"]) == "aberta":
			return str(planos[i]["cor"])
	return ""

func aula_retirar_cor(cor: String) -> String:
	if cor != "" and baralho.has(cor):
		baralho.erase(cor)
		return cor
	return comprar_do_baralho()

func aula_carta_objetivo(id_carta: String) -> Dictionary:
	for carta in catalogo_objetivos_grandes:
		if str(carta["id"]) == id_carta:
			return carta.duplicate(true)
	if id_carta.begins_with("fada:"):
		var partes: PackedStringArray = id_carta.split(":")
		var numero: int = int(partes[1])
		var modelo: Dictionary = OBJETIVOS_FADA_MODELOS[numero]
		return {"id": id_carta, "classe": "fada", "fada_id": numero, "copia": int(partes[2]),
			"titulo": str(modelo["titulo"]), "descricao": str(modelo["descricao"]), "pontos": pontuacao_fada_na_partida(modelo)}
	push_error("Objetivo da aula inexistente: " + id_carta)
	return {}

func aula_entregar_mao(dono: int, identificadores: Array) -> void:
	var dados: Dictionary = jogadores[dono]
	var avancada: bool = int(dados["objetivos_concluidos"]) >= 3
	var anteriores: Array[Dictionary] = dados["objetivos"]
	var cartas: Array[Dictionary] = []
	var faixas: Array[String] = []
	for id_carta in identificadores:
		var id_texto: String = str(id_carta)
		var carta: Dictionary = aula_carta_objetivo(id_texto)
		for anterior in anteriores:
			if str(anterior.get("id", "")) == id_texto:
				carta = anterior.duplicate(true)
				break
		cartas.append(carta)
		if id_texto.begins_with("fada:"):
			faixas.append("fada")
			objetivos_fada_sorteados[id_texto] = true
		else:
			faixas.append("dificil" if avancada else "medio")
			objetivos_ja_sorteados[id_texto] = true
	dados["objetivos"] = cartas
	dados.erase("aula_previa_objetivos")
	dados["faixas_objetivos"] = faixas
	dados["fase_grandes_ativa"] = true
	dados["fase_dificil_ativa"] = avancada
	dados["fadas_desbloqueadas"] = avancada and eh_alternativa()

# v191: prévias puramente didáticas, fora da mão pontuável. Não consomem sorteio.
# A partir da quinta jogada branca, a mão Média fica igual à do duelo.
# Objetivos ativos são preservados; as novas cartas respeitam catálogo e unicidade.
func aula_liberar_mao_normal() -> void:
	if jogadores.is_empty() or bool(jogadores[0].get("fase_dificil_ativa", false)):
		return
	var mao: Array[Dictionary] = jogadores[0]["objetivos"]
	var faixas: Array[String] = jogadores[0]["faixas_objetivos"]
	var ativos: Array[Dictionary] = []
	for dados in jogadores:
		for carta in dados["objetivos"]:
			if not carta.is_empty():
				ativos.append(carta)
	while mao.size() < 3:
		var nova: Dictionary = novo_objetivo_grande(ativos, mao, 46)
		if nova.is_empty():
			break
		mao.append(nova)
		ativos.append(nova)
		faixas.append("medio")
	jogadores[0].erase("aula_previa_objetivos")

func aula_previa_objetivos(dono: int) -> Array:
	if not aula_duelo or dono < 0 or dono >= jogadores.size():
		return []
	var dados: Dictionary = jogadores[dono]
	if dados["objetivos"].size() != 1 or bool(dados.get("fase_dificil_ativa", false)):
		return []
	return dados.get("aula_previa_objetivos", [])

func aula_preparar_previa_objetivos(dono: int) -> void:
	var dados: Dictionary = jogadores[dono]
	var mao: Array[Dictionary] = dados["objetivos"]
	if mao.size() != 1 or mao[0].is_empty():
		return
	var exemplos: Array[Dictionary] = []
	var usados: Array[Dictionary] = [mao[0]]
	# Priorizar exemplos de objetivos médios ainda não completos nem distribuídos.
	# A segunda passagem garante a apresentação de dois exemplos mesmo em jardim grande.
	for passagem in range(2):
		for carta in catalogo_objetivos_grandes:
			if exemplos.size() == 2:
				break
			if not TIPOS_MEDIOS_ABERTURA_SEGURA.has(int(carta["tipo"])):
				continue
			if quantidade_do_tipo_na_mao(usados, carta) > 0 or objetivo_repetiria_cores_na_mao(carta, usados):
				continue
			if passagem == 0 and (objetivos_ja_sorteados.has(str(carta["id"])) or objetivo_completo_no_setup(carta)):
				continue
			var exemplo: Dictionary = carta.duplicate(true)
			exemplos.append(exemplo)
			usados.append(exemplo)
		if exemplos.size() == 2:
			break
	dados["aula_previa_objetivos"] = exemplos

func aula_dados_rotacao() -> Dictionary:
	return AULA_ROTACAO_ALTERNATIVA

func aula_indice_rotacao() -> int:
	if not aula_guiada_ativa() or turnos_jogados != AULA_TURNO_ROTACAO or jogador_atual != 0 or jogadores.is_empty():
		return -1
	var objetivos: Array[Dictionary] = jogadores[0]["objetivos"]
	for i in range(objetivos.size()):
		if str(objetivos[i].get("id", "")) == str(aula_dados_rotacao()["id"]):
			return i
	return -1

func aula_rotacao_pendente() -> bool:
	var indice: int = aula_indice_rotacao()
	if indice < 0:
		return false
	return int(jogadores[0]["objetivos"][indice].get("rotacao_visual", 0)) != int(aula_dados_rotacao()["giro"])

func aula_preparar_rotacao() -> void:
	# Chamado uma vez antes da segunda conquista da aula.
	var indice: int = aula_indice_rotacao()
	if indice >= 0:
		jogadores[0]["objetivos"][indice]["rotacao_visual"] = (int(aula_dados_rotacao()["giro"]) + 3) % 4

func aula_compra_antes_de_mover() -> bool:
	# Em qualquer deslocamento guiado com baralho, conhecer primeiro a cor.
	if not aula_guiada_ativa() or jogador_atual != 0:
		return false
	var plano: Dictionary = aula_plano()
	return aula_origem() != CELULA_INVALIDA and str(plano.get("fonte", "")) == "baralho"

func acao_automatica_compra() -> String:
	return "mover" if movimento_pendente or aula_compra_antes_de_mover() else "plantar"

func aula_pode_comprar(da_aberta: bool) -> bool:
	if aula_rotacao_pendente():
		return false
	if not aula_guiada_ativa() or jogador_atual != 0 or animacao_setup_ativa or celebracao_objetivo_ativa or etapa_fada != "" or flor_na_mao != "" or escolha_objetivo_ativa or conquistas_abertas:
		return false
	if aula_origem() != CELULA_INVALIDA:
		if aula_compra_antes_de_mover():
			if movimento_pendente or origem_selecionada != CELULA_INVALIDA:
				return false
		elif not movimento_pendente:
			return false
	if not aula_demonstracao_ativa():
		# Quarta jogada: deslocamento guiado, reposição de escolha livre.
		return true
	return str(aula_plano().get("fonte", "")) == ("aberta" if da_aberta else "baralho")

func aula_alvo_tabuleiro() -> Vector2i:
	if animacao_compra_ativa or not juice_plantar.is_empty() or not juice_repor.is_empty():
		return CELULA_INVALIDA
	if aula_rotacao_pendente():
		return CELULA_INVALIDA
	if not aula_guiada_ativa() or jogador_atual != 0 or animacao_setup_ativa or celebracao_objetivo_ativa or etapa_fada != "" or movimento_pendente or escolha_objetivo_ativa:
		return CELULA_INVALIDA
	var origem: Vector2i = aula_origem()
	if origem != CELULA_INVALIDA:
		if aula_compra_antes_de_mover() and flor_na_mao == "":
			return CELULA_INVALIDA
		return origem if origem_selecionada == CELULA_INVALIDA else aula_destino()
	return aula_destino() if flor_na_mao != "" else CELULA_INVALIDA

func aula_clique_tabuleiro(c: Vector2i) -> void:
	var alvo: Vector2i = aula_alvo_tabuleiro()
	if alvo == CELULA_INVALIDA or c != alvo:
		if alvo != CELULA_INVALIDA and tabuleiro.has(c):
			juice_erro_casa = c
			juice_erro_tempo = juice_relogio
		return
	if aula_origem() == CELULA_INVALIDA:
		colocar_carta(c)
	elif origem_selecionada == CELULA_INVALIDA:
		if pode_deslocar_origem(c):
			acao_nova = "mover" if versao_nova else ""
			modo_movimento = true
			origem_selecionada = c
			atualizar_botoes_de_movimento()
	else:
		iniciar_deslocamento(origem_selecionada, c)
	queue_redraw()

func aula_enquadrar_jardim() -> void:
	# Enquadra o tabuleiro e o próximo alvo, sem ocultar objetivos ou faixa da vez.
	if not aula_duelo_ativa() or tabuleiro.is_empty() or (not aula_guiada_ativa() and not aula_ajuda_visivel()):
		return
	if not aula_guiada_ativa():
		mobile_camera_manual()
	var menor: Vector2i = Vector2i(99999, 99999)
	var maior: Vector2i = Vector2i(-99999, -99999)
	var casas: Array = tabuleiro.keys()
	if aula_destino() != CELULA_INVALIDA:
		casas.append(aula_destino())
	if aula_ajuda_visivel() and not aula_ajuda_plano.is_empty():
		casas.append(aula_ajuda_plano["destino"])
	for chave in casas:
		var casa: Vector2i = chave
		menor = Vector2i(mini(menor.x, casa.x), mini(menor.y, casa.y))
		maior = Vector2i(maxi(maior.x, casa.x), maxi(maior.y, casa.y))
	var extensao: Vector2 = Vector2(maior - menor) + Vector2.ONE * 1.4
	var livre: Vector2 = area_tabuleiro.size - Vector2(20.0, 60.0 if interface_compacta else 80.0)
	if area_dica_aprender.has_area():
		# As faixas já foram descontadas; reservar apenas margem e revisão no PC.
		livre = area_tabuleiro.size - Vector2(20.0, 16.0 + (40.0 if controles_revisao_no_pc() else 0.0))
	var base_carta: float = tamanho_carta_base_jardim()
	zoom = clampf(minf(livre.x / maxf(1.0, extensao.x * base_carta), livre.y / maxf(1.0, extensao.y * base_carta)), 0.12, 1.0)
	var centro: Vector2 = (Vector2(menor) + Vector2(maior)) * 0.5
	deslocamento = -centro * base_carta * zoom

func aula_desenhar_alvo() -> void:
	# Mostra o desenho que a primeira coletiva irá completar, sem sugerir cliques nas flores já colocadas.
	if turnos_jogados == 0 and not animacao_setup_ativa and not celebracao_objetivo_ativa and etapa_fada == "" and indice_cenario_em_revisao < 0 and not conquistas_abertas and not jogadores.is_empty():
		var destino_inicial: Vector2i = aula_destino()
		var previsto: Dictionary = tabuleiro.duplicate()
		previsto[destino_inicial] = str(aula_plano().get("cor", ""))
		var alteradas: Array[Vector2i] = [destino_inicial]
		for carta_inicial in jogadores[0]["objetivos"]:
			if str(carta_inicial.get("id", "")) != str(aula_plano().get("objetivo", "")):
				continue
			var combinacoes: Array[String] = listar_combinacoes_objetivo(alteradas, carta_inicial, previsto)
			if not combinacoes.is_empty():
				var lado_inicial: float = tamanho_carta_base_jardim() * zoom * 0.92
				for casa_inicial in casas_do_objetivo_concluido(combinacoes[0]):
					if casa_inicial == destino_inicial:
						continue
					var quadro_inicial: Rect2 = Rect2(posicao_celula(casa_inicial) - Vector2.ONE * lado_inicial * 0.5, Vector2.ONE * lado_inicial)
					if area_tabuleiro.grow(-2.0).encloses(quadro_inicial):
						draw_rect(quadro_inicial, Color(0.48, 0.89, 1.0, 0.85), false, 2.0)
			break
	if aula_rotacao_pendente() and indice_cenario_em_revisao < 0 and not conquistas_abertas:
		# Indicar as quatro casas do desenho que será completado nesta jogada.
		var lado_rotacao: float = tamanho_carta_base_jardim() * zoom
		for casa in aula_dados_rotacao()["casas"]:
			var r_rotacao: Rect2 = Rect2(posicao_celula(casa) - Vector2.ONE * lado_rotacao * 0.46, Vector2.ONE * lado_rotacao * 0.92)
			if area_tabuleiro.grow(-2.0).encloses(r_rotacao):
				draw_rect(r_rotacao, Color(0.48, 0.89, 1.0, 0.85), false, 2.0)
		return
	var alvo: Vector2i = aula_destino() if mobile_pode_arrastar_coletiva() else aula_alvo_tabuleiro()
	if alvo == CELULA_INVALIDA or indice_cenario_em_revisao >= 0 or conquistas_abertas:
		return
	var lado: float = tamanho_carta_base_jardim() * zoom
	var r: Rect2 = Rect2(posicao_celula(alvo) - Vector2.ONE * lado * 0.46, Vector2.ONE * lado * 0.92)
	if not area_tabuleiro.grow(-2.0).encloses(r):
		return
	var pulso: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.006)
	draw_rect(r, Color(0.25, 0.70, 1.0, 0.09 + 0.09 * pulso))
	draw_rect(r.grow(2.0), Color(0.22, 0.68, 1.0, 0.25 + 0.25 * pulso), false, 5.0)
	draw_rect(r, Color(0.48, 0.89, 1.0, 0.85 + 0.15 * pulso), false, 2.5)

func aula_dica() -> String:
	if turno_da_maquina():
		return texto_vez_atual()
	if animacao_setup_ativa:
		return "Você joga com as Brancas. Enfrente as Pretas e ganhe mais estrelas."
	if animacao_compra_ativa:
		return "A flor comprada vai para sua mão, no canto inferior direito."
	if etapa_fada == "movendo":
		var ganho: Dictionary = juice_ganhos_placar.get(jogador_atual, {})
		if not ganho.is_empty():
			return "Coleta: +%s. %s" % [rotulo_estrela_compacto(int(ganho["valor"])), "Trinca: +2 estrelas por grupo!" if int(ganho["bonus"]) > 0 else "Cada pólen vale 1 estrela."]
		return "Observe: a fada recolhe os pólens existentes e deixa 1 nas flores vazias."
	if celebracao_objetivo_ativa:
		return "Objetivo concluído! Ganhe estrelas e 1 pólen extra em cada flor do desenho (até 4)."
	if aguardando_reposicao_automatica and movimento_pendente and flor_na_mao == "":
		return "A flor foi movida. O espaço será preenchido com uma nova carta."
	if movimento_pendente and flor_na_mao != "":
		return "A flor da mão vai preencher o espaço deixado pela flor movida."
	return aula_dica_proxima_acao()

func aula_dica_proxima_acao() -> String:
	if aula_rotacao_pendente():
		return "Toque no canto superior direito do objetivo até alinhar o desenho."
	if not aula_guiada_ativa():
		return aula_dica_livre()
	if not aula_demonstracao_ativa():
		if etapa_fada in ["oferta", "escolha"]:
			return aula_dica_voo_livre()
		if movimento_pendente:
			return "Escolha: coletiva (cor visível) ou baralho (surpresa). A compra é definitiva."
		if origem_selecionada != CELULA_INVALIDA:
			return "Toque no espaço azul ao lado. A fada e os pólens acompanham a flor."
		return "Arraste a flor marcada até o espaço azul, ou toque nela. A flor central é fixa."
	if etapa_fada in ["oferta", "escolha"]:
		if aula_passo_humano() == 1:
			return "Toque na casa da fada destacada. Ela voa em reta e coleta pólens."
		return "Toque na outra fada branca destacada. Ela também pode voar na diagonal."
	if flor_na_mao != "":
		if aula_passo_humano() == 0:
			return "Plante no espaço azul acima da primeira fileira. Complete o objetivo."
		if aula_passo_humano() == 1:
			return "Plante no espaço azul, alinhado com uma fada."
		return "Plante no espaço azul, na diagonal da outra fada."
	if aula_passo_humano() == 0:
		return "Arraste a coletiva ao espaço azul. Complete o objetivo e ganhe estrelas."
	if aula_passo_humano() == 1:
		return "Agora compre do baralho. A cor é surpresa; depois de comprar, jogue a flor."
	return "Compre do baralho. Vamos descobrir outra maneira de voar."

func aula_dica_livre() -> String:
	if escolha_objetivo_ativa:
		return "Mais de um objetivo atendido! Escolha apenas um para render estrelas."
	if etapa_fada in ["oferta", "escolha"]:
		return aula_dica_voo_livre()
	if movimento_pendente:
		return "Reponha o espaço: escolha a coletiva ou compre do baralho."
	if origem_selecionada != CELULA_INVALIDA:
		if aula_ajuda_visivel() and not aula_ajuda_plano.is_empty():
			return "O espaço dourado completa um objetivo. Você também pode escolher outro destino."
		return "Toque no espaço livre ao lado, ou arraste a flor. A flor central é fixa."
	if flor_na_mao != "":
		if aula_ajuda_visivel():
			if aula_ajuda_plano.is_empty():
				return "Esta cor não completa um objetivo agora. Prepare um desenho ou uma coleta."
			if aula_ajuda_plano.has("origem"):
				return "Dica: mova a flor dourada para o espaço marcado. Sua carta repõe a origem."
			return "Dica: plantar no espaço dourado completa um objetivo. A decisão é sua."
		return "Toque ou arraste para plantar sua carta ou mover uma flor da borda."
	var concluidos: int = int(jogadores[0].get("objetivos_concluidos", 0)) if not jogadores.is_empty() else 0
	if aula_passo_humano() == AULA_TURNOS_GUIADOS:
		return "Jogo livre! Escolha uma fonte e compare os objetivos. Após comprar, use Dica."
	if concluidos >= 3:
		if aula_passo_humano() % 3 == 0:
			return "Ao atingir 6 objetivos, há rodada final. Vence quem somar mais estrelas."
		if aula_passo_humano() % 3 == 1:
			return "Os desafios de fada premiam voos e posições. Toque na carta para ler."
		return "Avalie objetivos e pólens. Três da mesma cor valem 5 estrelas."
	if concluidos == 2 and not aula_previa_objetivos(0).is_empty():
		return "Complete o objetivo de cima. Os dois transparentes são apenas exemplos."
	if aula_passo_humano() % 3 == 1:
		return "Gire pelo canto superior direito. Toque no desenho para ampliar."
	if aula_passo_humano() % 3 == 2:
		return "Três pólens da mesma cor valem 5 estrelas. Confira os contadores por cor."
	return "Escolha uma fonte de compra ou mova uma flor da borda. Você não precisa voar."

# v176 — orientação por ação e ajuda opcional, somente no modo Aprender.
func aula_titulo_etapa() -> String:
	if turno_da_maquina():
		return "Vez das Pretas · observe"
	match aula_passo_humano():
		0: return "1/4 · Plantar"
		1: return "2/4 · Voo em reta"
		2: return "3/4 · Voo diagonal"
		3: return "4/4 · Mover flores"
	var concluidos: int = int(jogadores[0].get("objetivos_concluidos", 0)) if not jogadores.is_empty() else 0
	return ("Jogo livre" if concluidos < 3 else "Avançado") + " · %d/6 metas" % concluidos

func aula_dica_voo_livre() -> String:
	# Mostra uma previsão real da rota, inclusive a flor de destino.
	var opcoes: PackedStringArray = []
	for indice in fadas_elegiveis:
		var previsao: Dictionary = mobile_prever_rota(indice, destino_da_fada)
		opcoes.append("F%d: %d pólens, %d poliniz." % [int(fadas[indice]["numero"]), previsao["coleta"], previsao["produz"]])
	if opcoes.is_empty():
		return "Não há fada alinhada. O turno termina sem voo."
	return "Toque na fada ou em Cancelar Voo. " + " · ".join(opcoes)

func aula_limpar_ajuda() -> void:
	aula_ajuda_turno = -1
	aula_ajuda_cor = ""
	aula_ajuda_plano.clear()
	aula_ajuda_solicitada = false

func aula_pode_pedir_ajuda() -> bool:
	return aula_duelo_ativa() and not turno_da_maquina() and not aula_guiada_ativa() and area_dica_aprender.has_area() and flor_na_mao != "" and origem_selecionada == CELULA_INVALIDA and not movimento_pendente and etapa_fada == "" and not celebracao_objetivo_ativa and not animacao_setup_ativa and not animacao_compra_ativa and juice_plantar.is_empty() and juice_repor.is_empty() and not escolha_objetivo_ativa and not conquistas_abertas and not aula_aviso_fada_ativo() and not aula_aviso_licao_ativo()

func aula_retangulo_ajuda() -> Rect2:
	return Rect2(area_dica_aprender.end.x - 142.0, area_dica_aprender.position.y + 3.0, 80.0, 36.0)

func aula_ajuda_visivel() -> bool:
	if not aula_duelo_ativa() or turno_da_maquina() or aula_guiada_ativa() or not aula_ajuda_solicitada or aula_ajuda_turno != turnos_jogados or aula_ajuda_cor != flor_na_mao or flor_na_mao == "" or movimento_pendente or etapa_fada != "" or celebracao_objetivo_ativa or animacao_compra_ativa or not juice_plantar.is_empty() or conquistas_abertas:
		return false
	return origem_selecionada == CELULA_INVALIDA or (aula_ajuda_plano.has("origem") and origem_selecionada == aula_ajuda_plano["origem"])

func aula_pedir_ajuda() -> void:
	if not aula_pode_pedir_ajuda():
		return
	if aula_ajuda_visivel():
		aula_limpar_ajuda()
		queue_redraw()
		return
	aula_limpar_ajuda()
	aula_ajuda_solicitada = true
	aula_ajuda_turno = turnos_jogados
	aula_ajuda_cor = flor_na_mao
	# Reusar o verificador REAL de objetivos, em cópias do jardim.
	# Primeiro, buscar um plantio direto; se não existir, testar deslocamentos.
	var candidatas: Dictionary = {}
	for chave in tabuleiro:
		var casa: Vector2i = chave
		for d in VIZINHOS:
			var c: Vector2i = casa + d
			if pode_colocar(c):
				candidatas[c] = true
	var melhor_pontos: int = -1
	for chave in candidatas:
		var destino: Vector2i = chave
		var previsto: Dictionary = tabuleiro.duplicate()
		previsto[destino] = flor_na_mao
		var alteradas: Array[Vector2i] = [destino]
		var resultado: Dictionary = melhor_objetivo_da_jogada(jogador_atual, alteradas, tabuleiro, previsto)
		if not resultado.is_empty() and int(resultado["pontos"]) > melhor_pontos:
			melhor_pontos = int(resultado["pontos"])
			aula_ajuda_plano = {"destino": destino}
	if aula_ajuda_plano.is_empty():
		for chave in tabuleiro:
			var origem: Vector2i = chave
			if not pode_deslocar_origem(origem):
				continue
			for d in VIZINHOS:
				var destino: Vector2i = origem + d
				if not destino_valido_para_movimento(origem, destino):
					continue
				var previsto: Dictionary = tabuleiro.duplicate()
				previsto[destino] = tabuleiro[origem]
				previsto[origem] = flor_na_mao
				var alteradas: Array[Vector2i] = [origem, destino]
				var resultado: Dictionary = melhor_objetivo_da_jogada(jogador_atual, alteradas, tabuleiro, previsto, origem)
				if not resultado.is_empty() and int(resultado["pontos"]) > melhor_pontos:
					melhor_pontos = int(resultado["pontos"])
					aula_ajuda_plano = {"origem": origem, "destino": destino}
	if not aula_ajuda_plano.is_empty():
		var alvo: Vector2i = aula_ajuda_plano["destino"]
		var inicio: Vector2i = aula_ajuda_plano.get("origem", alvo)
		var margem: float = tamanho_carta_base_jardim() * zoom * 0.5
		if not area_tabuleiro.grow(-margem).has_point(posicao_celula(alvo)) or not area_tabuleiro.grow(-margem).has_point(posicao_celula(inicio)):
			aula_enquadrar_jardim()
	queue_redraw()

func aula_desenhar_ajuda() -> void:
	if aula_ajuda_plano.is_empty():
		return
	var lado: float = tamanho_carta_base_jardim() * zoom * 0.86
	var alvo: Vector2i = aula_ajuda_plano["destino"]
	if aula_ajuda_plano.has("origem") and origem_selecionada == CELULA_INVALIDA:
		alvo = aula_ajuda_plano["origem"]
	var r: Rect2 = Rect2(posicao_celula(alvo) - Vector2.ONE * lado * 0.5, Vector2.ONE * lado)
	if area_tabuleiro.grow(-2.0).encloses(r):
		draw_rect(r, Color(0.95, 0.73, 0.24, 0.13))
		draw_rect(r, Color("efd08a"), false, 3.0)

func aula_aviso_fada_ativo() -> bool:
	return aula_duelo_ativa() and eh_alternativa() and jogador_atual == 0 and aula_aviso_fada_partida == identificador_partida

func aula_apresentar_objetivos_fada(token: int) -> void:
	if not aula_duelo_ativa() or not eh_alternativa() or jogador_atual != 0 or token != identificador_partida:
		return
	var cartas_fada: Array[Dictionary] = []
	for carta in jogadores[0]["objetivos"]:
		if str(carta.get("classe", "flor")) == "fada":
			cartas_fada.append(carta)
	if cartas_fada.size() != 2:
		return
	aula_aviso_fada_partida = token
	aula_nav_iniciar_aviso()
	toque_tabuleiro = false
	toque_arrastou = false
	pontos_multitoque.clear()
	gesto_multitoque_ativo = false
	for filho in get_children():
		if filho is Control and filho != aula_nav_clip:
			var controle: Control = filho as Control
			aula_aviso_fada_controles[controle] = controle.show_behind_parent
			controle.show_behind_parent = true
	queue_redraw()
	# A celebração e a vez humana retomam somente após avançar a lição.
	while aula_aviso_fada_ativo() and is_inside_tree():
		await aguardar_frame_jogo()
	if aula_aviso_fada_partida == token:
		aula_fechar_aviso_fada()

func aula_fechar_aviso_fada() -> void:
	aula_aviso_fada_partida = -1
	for filho in aula_aviso_fada_controles:
		if is_instance_valid(filho):
			var controle: Control = filho as Control
			controle.show_behind_parent = bool(aula_aviso_fada_controles[filho])
	aula_aviso_fada_controles.clear()
	queue_redraw()

func aula_retangulo_aviso_fada() -> Rect2:
	return area_dica_aprender

func aula_realcar_novo_objetivo_fada(r: Rect2) -> void:
	var pulso: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.006)
	draw_rect(r.grow(3.0), Color(0.25, 0.68, 1.0, 0.22 + 0.26 * pulso), false, 5.0)
	draw_rect(r.grow(1.0), Color("8fe5ff"), false, 2.0)

func aula_desenhar_aviso_fada() -> void:
	# A apresentação já é desenhada na faixa única.
	pass

func aula_aviso_licao_ativo() -> bool:
	return aula_duelo_ativa() and aula_aviso_licao_partida == identificador_partida and aula_aviso_licao_tipo != ""

func atualizar_som_demonstracao_aula() -> void:
	return

func aula_abrir_aviso_licao(tipo: String, carta: Dictionary = {}) -> void:
	audio_aula_polens_aplicados = 0
	aula_aviso_licao_tipo = tipo
	aula_aviso_licao_partida = identificador_partida
	aula_aviso_licao_carta = carta.duplicate(true)
	aula_nav_iniciar_aviso()
	toque_tabuleiro = false
	toque_arrastou = false
	pontos_multitoque.clear()
	gesto_multitoque_ativo = false
	for filho in get_children():
		if filho is Control and filho != aula_nav_clip:
			var controle: Control = filho as Control
			aula_aviso_licao_controles[controle] = controle.show_behind_parent
			controle.show_behind_parent = true
	queue_redraw()

func aula_fechar_aviso_licao() -> void:
	aula_aviso_licao_partida = -1
	aula_aviso_licao_tipo = ""
	aula_aviso_licao_carta.clear()
	for filho in aula_aviso_licao_controles:
		if is_instance_valid(filho):
			var controle: Control = filho as Control
			controle.show_behind_parent = bool(aula_aviso_licao_controles[filho])
	aula_aviso_licao_controles.clear()
	queue_redraw()

func aula_retangulo_aviso_licao() -> Rect2:
	return area_dica_aprender

func aula_texto_modal(texto: String, area: Rect2, tamanho: int = 18) -> void:
	var linhas: Array[String] = quebrar_texto_instrucoes(texto, area.size.x, tamanho)
	while tamanho > 10 and float(linhas.size()) * float(tamanho + 5) > area.size.y:
		tamanho -= 1
		linhas = quebrar_texto_instrucoes(texto, area.size.x, tamanho)
	var passo: float = float(tamanho + 5)
	var y: float = area.get_center().y - float(linhas.size()) * passo * 0.5 + passo * 0.8
	for linha in linhas:
		escrever_centralizado(linha, area.get_center().x, y, tamanho, COR_TEXTO)
		y += passo

func aula_desenhar_aviso_licao() -> void:
	# A lição já é desenhada na faixa única.
	pass

func juice_fator_tempo() -> float:
	return [0.45, 1.0, 1.12][juice_nivel]

func juice_limpar() -> void:
	v209_retorno_borda.clear()
	v209_previsao_fila.clear()
	v209_previsao_cursor = 0
	v209_candidatas_chave.clear()
	feel_final_por_regra = false
	feel_retorno.clear()
	feel_origem_plantio.clear()
	feel_estrelas.clear()
	feel_trincas.clear()
	feel_previsao_chave.clear()
	feel_previsao_ids.clear()
	feel_previa_arrasto_chave.clear()
	feel_previa_casas.clear()
	feel_inicio_deslocamento.clear()
	feel_vento_ativo = false
	feel_vento_forca = 0.0
	v199_parar_ambiente()
	feel_turno = -1
	feel_turno_anterior = -1
	feel_turno_inicio = -10.0
	mobile_limpar_intencao()
	mobile_fechar_objetivo_ampliado()
	camera_chave_v187.clear()
	camera_manual_ate = -1.0
	camera_ajustando = false
	mobile_constelacao_floral = false
	parar_audio_voo()
	juice_efeitos.clear()
	juice_particulas.clear()
	juice_rotacoes.clear()
	juice_entradas.clear()
	juice_mao_anterior.clear()
	juice_reserva_refluxo.clear()
	juice_reserva_pousos.clear()
	animacoes_coleta_aula.clear()
	juice_transicao_objetivos.clear()
	juice_ganhos_placar.clear()
	juice_ultima_vibracao = -10.0
	juice_notas_voo = 0
	juice_arquivo.clear()
	juice_voo.clear()
	juice_fada_prontidao.clear()
	juice_mover.clear()
	juice_plantar.clear()
	juice_repor.clear()
	animacao_compra_ativa = false
	animacao_compra_cor = ""
	animacao_compra_fonte = ""
	animacao_compra_tempo = 0.0
	juice_modal = ""
	juice_modal_inicio = -10.0
	juice_fim = -10.0
	juice_final_expandida_inicio = -10.0
	juice_erro_tempo = -10.0
	juice_cancelar_tempo = -10.0

func juice_progresso(efeito: Dictionary) -> float:
	return clampf((juice_relogio - float(efeito.get("inicio", juice_relogio))) / maxf(0.001, float(efeito.get("duracao", 0.3))), 0.0, 1.0)

func juice_atualizar_prontidao_fadas(delta: float) -> bool:
	if estado_tela != "partida" or indice_cenario_em_revisao >= 0 or partida_encerrada or animacao_setup_ativa:
		var tinha: bool = not juice_fada_prontidao.is_empty()
		juice_fada_prontidao.clear()
		return tinha
	var mudou: bool = false
	var oferta: bool = etapa_fada in ["oferta", "escolha"]
	for i in range(fadas.size()):
		var atual: float = float(juice_fada_prontidao.get(i, 0.0))
		var alvo: float = 1.0 if oferta and fadas_elegiveis.has(i) else 0.0
		var novo: float = move_toward(atual, alvo, delta / (0.23 * juice_fator_tempo()))
		if novo > 0.0:
			juice_fada_prontidao[i] = novo
			mudou = true
		elif juice_fada_prontidao.has(i):
			juice_fada_prontidao.erase(i)
			mudou = true
	return mudou

func juice_atualizar(delta: float) -> void:
	juice_relogio += delta
	var redesenhar: bool = juice_atualizar_prontidao_fadas(delta)
	for dono in juice_reserva_refluxo.keys():
		if juice_relogio - float(juice_reserva_refluxo[dono]["inicio"]) >= 0.30 * juice_fator_tempo():
			juice_reserva_refluxo.erase(dono)
		redesenhar = true
	for i in range(juice_reserva_pousos.size() - 1, -1, -1):
		if juice_relogio - float(juice_reserva_pousos[i]["inicio"]) >= 0.34 * juice_fator_tempo():
			juice_reserva_pousos.remove_at(i)
		redesenhar = true
	if not juice_transicao_objetivos.is_empty():
		if juice_progresso(juice_transicao_objetivos) >= 1.0:
			juice_transicao_objetivos.clear()
		redesenhar = true
	if not juice_voo.is_empty():
		# A fase é integrada ao longo do tempo, sem reiniciar a cada flor.
		var fase: String = str(juice_voo.get("fase", ""))
		var ritmo_alvo: float = 7.5
		if fase == "decolar":
			ritmo_alvo = lerpf(2.6, 7.5, interpolar_suave(juice_progresso(juice_voo)))
		elif fase == "pousar":
			ritmo_alvo = lerpf(7.5, 2.6, interpolar_suave(juice_progresso(juice_voo)))
		var ritmo: float = move_toward(float(juice_voo.get("ritmo_asas", 2.6)), ritmo_alvo, delta * 32.0)
		juice_voo["ritmo_asas"] = ritmo
		juice_voo["fase_asas"] = fposmod(float(juice_voo.get("fase_asas", 0.0)) + TAU * ritmo * delta, TAU)
		redesenhar = true
	atualizar_audio_voo(delta)
	for efeito in [juice_mover, juice_repor, juice_arquivo]:
		if not efeito.is_empty():
			var progresso_efeito: float = juice_progresso(efeito)
			if efeito.has("som_virada") and not bool(efeito["som_virada"]) and progresso_efeito >= 0.5:
				efeito["som_virada"] = true
				tocar_som("papel_virar")
			if progresso_efeito >= 1.0:
				if efeito.has("carta"):
					juice_efeitos["arquivo_chegou"] = juice_relogio
				efeito.clear()
			redesenhar = true
	if not juice_plantar.is_empty():
		redesenhar = true
	for chave in juice_efeitos.keys():
		if juice_relogio - float(juice_efeitos[chave]) > 2.0:
			juice_efeitos.erase(chave)
	for chave in juice_rotacoes.keys():
		if juice_relogio - float(juice_rotacoes[chave]["inicio"]) >= 0.20 * juice_fator_tempo():
			juice_rotacoes.erase(chave)
		redesenhar = true
	for chave in juice_entradas.keys():
		if juice_relogio - float(juice_entradas[chave]) >= 0.40 * juice_fator_tempo():
			juice_entradas.erase(chave)
		redesenhar = true
	for i in range(juice_particulas.size() - 1, -1, -1):
		if juice_progresso(juice_particulas[i]) >= 1.0:
			juice_particulas.remove_at(i)
		redesenhar = true
	for dono in juice_ganhos_placar.keys():
		if juice_relogio - float(juice_ganhos_placar[dono]["inicio"]) >= 1.35:
			juice_ganhos_placar.erase(dono)
		redesenhar = true
	if estado_tela == "partida" and indice_cenario_em_revisao < 0 and not jogadores.is_empty():
		for i in range(jogadores.size()):
			var ids: Array[String] = []
			for carta in jogadores[i]["objetivos"]:
				if not carta.is_empty():
					ids.append(str(carta.get("id", "")))
			if juice_mao_anterior.has(i) and juice_mao_anterior[i] == ids:
				continue
			if juice_mao_anterior.has(i):
				var novas_visiveis: bool = false
				for id_carta in ids:
					if not juice_mao_anterior[i].has(id_carta):
						juice_entradas["%d:%s" % [i, id_carta]] = juice_relogio
						redesenhar = true
						novas_visiveis = novas_visiveis or i == jogador_atual
				if novas_visiveis:
					tocar_som("papel_objetivo")
			juice_mao_anterior[i] = ids
	var modal: String = ""
	if estado_tela == "partida":
		if aula_aviso_licao_ativo():
			modal = "licao"
		elif aula_aviso_fada_ativo():
			modal = "fadas"
		elif conquistas_abertas:
			modal = "conquistas"
	if modal != juice_modal:
		tocar_som("janela_abrir" if modal != "" else "janela_fechar")
		juice_modal = modal
		juice_modal_inicio = juice_relogio
		redesenhar = true
	if juice_relogio - juice_modal_inicio < 0.24 or juice_relogio - juice_pressao_tempo < 0.14 or juice_relogio - juice_erro_tempo < 0.25 or juice_relogio - juice_cancelar_tempo < 0.3 or (estado_tela == "resultado" and juice_relogio - juice_fim < 2.0 * juice_fator_tempo()) or (estado_tela == "distribuicao_final" and eh_alternativa()) or not juice_efeitos.is_empty():
		redesenhar = true
	if redesenhar:
		queue_redraw()

func juice_nascer(casa: Vector2i) -> void:
	juice_efeitos["n:%s" % str(casa)] = juice_relogio

func juice_onda(casa: Vector2i, cor: Color) -> void:
	if estado_tela != "partida" or juice_particulas.size() >= (16 if v209_leve else 32):
		return
	juice_particulas.append({"casa": casa, "cor": cor, "inicio": juice_relogio, "duracao": 0.46 * juice_fator_tempo()})
	queue_redraw()

# v163: o mesmo referencial visual acompanha carta, pólens e miniaturas.
func juice_acomodacao(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return sin(t * TAU * 1.5) * pow(1.0 - t, 2.0)

func juice_inclinacao_carta(casa: Vector2i) -> float:
	if not v209_retorno_borda.is_empty() and casa == v209_retorno_borda.get("casa"):
		return float(v209_retorno_borda["angulo"]) * (1.0 - interpolar_suave(juice_progresso(v209_retorno_borda)))
	if casa == mobile_borda_arrastada:
		return feel_angulo * v199_margem_inclinacao(feel_pos)
	if indice_cenario_em_revisao >= 0 or juice_mover.is_empty() or casa != juice_mover.get("destino"):
		return 0.0
	var t: float = juice_progresso(juice_mover)
	var dir: Vector2 = Vector2(juice_mover["destino"] - juice_mover["origem"]).normalized()
	var intensidade: float = [0.55, 1.0, 1.12][juice_nivel]
	var angulo: float = (dir.x * 0.12 + dir.y * 0.065) * intensidade
	var centro: Vector2 = posicao_celula(casa) + juice_desvio_carta(casa)
	var lado: float = tamanho_carta_base_jardim() * zoom
	# Evita que a rotação transborde o painel durante movimentos na borda.
	var margem: float = minf(minf(centro.x - area_tabuleiro.position.x, area_tabuleiro.end.x - centro.x), minf(centro.y - area_tabuleiro.position.y, area_tabuleiro.end.y - centro.y))
	var recorte: float = clampf((margem - lado * 0.50) / maxf(1.0, lado * 0.16), 0.0, 1.0)
	if juice_mover.has("angulo_arrasto"):
		return float(juice_mover["angulo_arrasto"]) * (1.0 - interpolar_suave(t)) * recorte
	if t < 0.78:
		return angulo * sin(PI * t / 0.78) * recorte
	return -angulo * 0.38 * juice_acomodacao((t - 0.78) / 0.22) * recorte

func juice_posicao_sobre_carta(casa: Vector2i, ponto: Vector2) -> Vector2:
	var centro: Vector2 = posicao_celula(casa)
	return centro + juice_desvio_carta(casa) + ((ponto - centro) * juice_escala_carta(casa)).rotated(juice_inclinacao_carta(casa))

func juice_escala_carta(casa: Vector2i) -> float:
	if not v209_retorno_borda.is_empty() and casa == v209_retorno_borda.get("casa"):
		return lerpf(0.98, 1.0, interpolar_suave(juice_progresso(v209_retorno_borda)))
	if casa == mobile_borda_arrastada:
		return 0.98
	if indice_cenario_em_revisao >= 0:
		return 1.0
	if not juice_mover.is_empty() and casa == juice_mover.get("destino"):
		var t: float = juice_progresso(juice_mover)
		if t < 0.78:
			return lerpf(float(juice_mover.get("escala_origem", 1.0)), 1.0, interpolar_suave(t / 0.78))
		return 1.0 - 0.028 * juice_acomodacao((t - 0.78) / 0.22)
	var inicio: float = float(juice_efeitos.get("encaixe:%s" % str(casa), -10.0))
	var t_encaixe: float = (juice_relogio - inicio) / (0.26 * juice_fator_tempo())
	if t_encaixe >= 0.0 and t_encaixe < 1.0:
		return 1.0 - 0.035 * juice_acomodacao(t_encaixe)
	if casa == origem_selecionada and modo_movimento and not movimento_pendente:
		return 1.035 + 0.01 * (0.5 + 0.5 * sin(juice_relogio * TAU * 1.5))
	return 1.0

func juice_abertura_flor(casa: Vector2i) -> float:
	if indice_cenario_em_revisao >= 0:
		return 1.0
	if not juice_plantar.is_empty() and casa == juice_plantar.get("casa"):
		var t_plantio: float = juice_progresso(juice_plantar)
		return minf(1.16, lerpf(0.10, 1.0, interpolar_suave((t_plantio - 0.10) / 0.68)) + sin(t_plantio * PI) * 0.14)
	var inicio: float = float(juice_efeitos.get("encaixe:%s" % str(casa), -10.0))
	var t_nascer: float = (juice_relogio - inicio) / (0.26 * juice_fator_tempo())
	if t_nascer >= 0.0 and t_nascer < 1.0:
		return 1.0 + 0.09 * sin(t_nascer * PI) * (1.0 - t_nascer)
	return 1.0

func juice_desvio_carta(casa: Vector2i) -> Vector2:
	if not v209_retorno_borda.is_empty() and casa == v209_retorno_borda.get("casa"):
		var rel: Vector2 = v209_retorno_borda["rel"]
		return rel * tamanho_carta_base_jardim() * zoom * (1.0 - interpolar_suave(juice_progresso(v209_retorno_borda)))
	if casa == mobile_borda_arrastada:
		return feel_pos - posicao_celula(casa)
	var desvio_visual: Vector2 = Vector2.ZERO
	if indice_cenario_em_revisao < 0 and not juice_mover.is_empty() and casa == juice_mover.get("destino"):
		var fase_carta: float = juice_progresso(juice_mover)
		var t: float = interpolar_suave(fase_carta / 0.78)
		var lado: float = tamanho_carta_base_jardim() * zoom
		var elevacao: float = float(juice_mover.get("elevacao_origem", 0.0)) * (1.0 - t) - sin(t * PI) * 0.065
		if juice_mover.has("inicio_rel"):
			var rel: Vector2 = juice_mover["inicio_rel"]
			desvio_visual += rel * lado * (1.0 - t)
		else:
			desvio_visual += (posicao_celula(juice_mover["origem"]) - posicao_celula(casa)) * (1.0 - t) + Vector2(0, lado * elevacao)
		if fase_carta >= 0.78:
			var amortecer: float = juice_acomodacao((fase_carta - 0.78) / 0.22)
			var dir: Vector2 = Vector2(juice_mover["destino"] - juice_mover["origem"]).normalized()
			desvio_visual += dir * lado * 0.045 * amortecer + Vector2(0.0, -lado * 0.035 * absf(amortecer))
	if indice_cenario_em_revisao < 0 and casa == origem_selecionada and modo_movimento and not movimento_pendente:
		var levantar: float = 0.5 + 0.5 * sin(juice_relogio * TAU * 1.5)
		desvio_visual += Vector2(0.0, -tamanho_carta_base_jardim() * zoom * (0.085 + levantar * 0.018))
	return desvio_visual

func juice_iniciar_plantio(casa: Vector2i) -> void:
	juice_vibrar(22)
	juice_plantar = {"casa": casa, "cor": flor_na_mao, "inicio": juice_relogio, "duracao": 0.30 * juice_fator_tempo()}
	if not feel_origem_plantio.is_empty():
		juice_plantar["origem_visual"] = feel_origem_plantio["pos"]
		juice_plantar["angulo"] = feel_origem_plantio["angulo"]
		if feel_origem_plantio.has("lado"):
			juice_plantar["lado_origem"] = feel_origem_plantio["lado"]
	juice_efeitos["pl:%s" % str(casa)] = juice_relogio
	# O som de terra é emitido somente no encaixe, em ambos os caminhos de plantio.
	queue_redraw()

func juice_desenhar_plantio() -> void:
	if juice_plantar.is_empty():
		return
	var t: float = juice_progresso(juice_plantar)
	var casa: Vector2i = juice_plantar["casa"]
	var origem_visual: Vector2 = juice_plantar.get("origem_visual", area_mao.get_center())
	var centro: Vector2 = origem_visual.lerp(posicao_celula(casa), interpolar_suave(t))
	var lado: float = lerpf(float(juice_plantar.get("lado_origem", area_mao.size.x * 0.98)), tamanho_carta_base_jardim() * zoom, t) * (1.0 + sin(t * PI) * 0.05)
	var r: Rect2 = Rect2(centro - Vector2.ONE * lado * 0.5, Vector2.ONE * lado)
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.22))
	var abertura: float = 1.0 + sin(t * PI) * 0.10 if juice_plantar.has("lado_origem") else minf(1.18, lerpf(0.08, 1.0, interpolar_suave((t - 0.12) / 0.68)) + sin(t * PI) * 0.16)
	var alfa_plantio: float = 1.0 if juice_plantar.has("lado_origem") else lerpf(0.55, 1.0, interpolar_suave((t - 0.72) / 0.28))
	var angulo: float = float(juice_plantar.get("angulo", 0.0)) * (1.0 - interpolar_suave(t))
	draw_set_transform(centro - centro.rotated(angulo), angulo)
	desenhar_carta(centro, lado, str(juice_plantar["cor"]), alfa_plantio, false, abertura, 0.0)
	draw_set_transform(Vector2.ZERO)
	if t > 0.18:
		draw_arc(centro, lado * (0.24 + 0.12 * t), 0.0, TAU, 28, Color(1.0, 0.88, 0.52, 0.16 * (1.0 - t)), maxf(1.2, lado * 0.022), true)

func juice_desenhar_reposicao() -> void:
	if juice_repor.is_empty() or indice_cenario_em_revisao >= 0:
		return
	var t: float = juice_progresso(juice_repor)
	var centro: Vector2 = area_baralho.get_center().lerp(area_aberta.get_center(), interpolar_suave(t))
	var lado: float = lerpf(area_baralho.size.x, area_aberta.size.x * 0.98, t)
	var largura: float = lado * maxf(0.035, absf(cos(t * PI)))
	var r: Rect2 = Rect2(centro - Vector2(largura, lado) * 0.5, Vector2(largura, lado))
	if t < 0.5:
		desenhar_verso_baralho(r)
	else:
		desenhar_carta_em_retangulo(r, str(juice_repor["cor"]))

func juice_desenhar_arquivo() -> void:
	if juice_arquivo.is_empty() or indice_cenario_em_revisao >= 0:
		return
	var t: float = juice_progresso(juice_arquivo)
	var origem: Rect2 = retangulo_objetivo_ativo(int(juice_arquivo["indice"]))
	var centro: Vector2 = origem.get_center().lerp(retangulo_linha_placar(int(juice_arquivo["dono"])).get_center(), interpolar_suave(t))
	var lado: Vector2 = origem.size * lerpf(1.0, 0.10, t)
	var r: Rect2 = Rect2(centro - lado * 0.5, lado)
	var fator: float = lado.x / maxf(1.0, origem.size.x)
	draw_set_transform(centro - origem.get_center() * fator, 0.0, Vector2.ONE * fator)
	desenhar_objetivo(juice_arquivo["carta"], origem, -1, true)
	draw_set_transform(Vector2.ZERO)
	if t < 0.5:
		draw_circle(r.end - Vector2(8, 8), 9, Color("41864b"))
		var p: Vector2 = r.end - Vector2(8, 8)
		draw_polyline(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(-1, 3), p + Vector2(5, -4)]), Color.WHITE, 2, true)
	else:
		draw_rect(retangulo_linha_placar(int(juice_arquivo["dono"])).grow(-1.0), Color(COR_PRATA, sin(t * PI)), false, 2.2)

func juice_desenhar_particulas() -> void:
	for e in juice_particulas:
		var t: float = juice_progresso(e)
		var centro: Vector2 = posicao_celula(e["casa"])
		if not area_tabuleiro.has_point(centro):
			continue
		var lado: float = tamanho_carta_base_jardim() * zoom
		var cor: Color = e["cor"]
		cor.a = (1.0 - t) * 0.65
		draw_arc(centro, lado * (0.15 + 0.40 * t), 0, TAU, 28, cor, 1.7, true)
		for i in range(mini(4, [3, 7, 12][juice_nivel]) if v209_leve else [3, 7, 12][juice_nivel]):
			var ang: float = float(i) * 2.399963
			var p: Vector2 = centro + Vector2(cos(ang), sin(ang)) * lado * (0.25 + 0.27 * t)
			if area_tabuleiro.has_point(p):
				draw_circle(p, maxf(0.7, lado * 0.025 * (1.0 - t)), cor)
	if juice_relogio - juice_erro_tempo < 0.24:
		var t: float = (juice_relogio - juice_erro_tempo) / 0.24
		var lado: float = tamanho_carta_base_jardim() * zoom * 0.9
		var p: Vector2 = posicao_celula(juice_erro_casa) + Vector2(sin(t * TAU * 3.0) * 5.0, 0)
		if area_tabuleiro.has_point(p):
			draw_rect(Rect2(p - Vector2.ONE * lado * 0.5, Vector2.ONE * lado), Color(1, 0.49, 0.4, 1.0 - t), false, 2.0)
	if juice_relogio - juice_cancelar_tempo < 0.25:
		var t: float = (juice_relogio - juice_cancelar_tempo) / 0.25
		var lado: float = tamanho_carta_base_jardim() * zoom * 0.92
		var p: Vector2 = posicao_celula(juice_cancelar_casa)
		if area_tabuleiro.has_point(p):
			draw_rect(Rect2(p - Vector2.ONE * lado * 0.5, Vector2.ONE * lado), Color(0.4, 0.75, 1, 0.6 * (1.0 - t)), false, 2.0)

func juice_transformar_modal(r: Rect2) -> void:
	juice_modal_retangulo = r
	var t: float = clampf((juice_relogio - juice_modal_inicio) / (0.18 * juice_fator_tempo()), 0.0, 1.0)
	var escala: float = lerpf(0.94, 1.0, interpolar_suave(t))
	draw_set_transform(r.get_center() * (1.0 - escala), 0.0, Vector2.ONE * escala)

func juice_desenhar_final(painel: Rect2) -> void:
	if not feel_final_por_regra:
		return
	var t: float = (juice_relogio - juice_fim) / (1.6 * juice_fator_tempo())
	if t < 0.0 or t >= 1.0:
		return
	var tela: Vector2 = get_viewport_rect().size
	for i in range(mini(12, [8, 20, 36][juice_nivel]) if v209_leve else [8, 20, 36][juice_nivel]):
		var x: float = fposmod(float(i) * 89.43 + sin(t * 5.0 + float(i)) * 15.0, tela.x)
		var y: float = fposmod(float(i) * 52.2 + t * tela.y * 0.9, tela.y)
		var p: Vector2 = Vector2(x, y)
		if painel.has_point(p):
			continue
		var cor: Color = Color(1.0, 0.78 + 0.15 * sin(float(i)), 0.38, (1.0 - t) * 0.75)
		if i % 3 == 0:
			feel_estrela(p, 4.0 + float(i % 4), cor.a, t * 2.0)
		else:
			draw_circle(p, 2.0 + float(i % 3), cor)


func juice_desenhar_trincas(estoque: Dictionary, area: Rect2) -> void:
	var grupos: Array[Dictionary] = []
	for cor in CORES:
		var n: int = maxi(0, int(estoque.get(cor, 0)))
		while n > 0:
			var grupo: int = mini(n, 3)
			grupos.append({"cor": cor, "n": grupo})
			n -= grupo
	if grupos.is_empty():
		return
	var colunas: int = mini(grupos.size(), maxi(1, ceili(sqrt(float(grupos.size()) * area.size.x / maxf(5.0, area.size.y * 2.5)))))
	var linhas: int = ceili(float(grupos.size()) / float(colunas))
	var w: float = minf(57.0, area.size.x / float(colunas))
	var h: float = minf(23.0, area.size.y / float(linhas))
	var raio: float = maxf(0.35, minf(4.4, minf(w / 10.0, h / 3.2)))
	for i in range(grupos.size()):
		var item: Dictionary = grupos[i]
		var n: int = int(item["n"])
		var t: float = clampf((juice_relogio - juice_fim - minf(0.35, float(i) * 0.045)) / 0.48, 0.0, 1.0)
		var centro: Vector2 = area.position + Vector2((float(i % colunas) + 0.5) * w, (float(floori(float(i) / float(colunas))) + 0.5) * h)
		var intervalo: float = raio * lerpf(3.1, 2.05, interpolar_suave(t))
		if n == 3:
			var moldura: Rect2 = Rect2(centro - Vector2(w * 0.46, h * 0.43), Vector2(w * 0.92, h * 0.86))
			draw_rect(moldura, Color(1.0, 0.8, 0.35, 0.16 * t), true)
			draw_rect(moldura, Color(1.0, 0.8, 0.35, 0.7 * t), false, 1.0)
		for j in range(n):
			var x: float = (float(j) - float(n - 1) * 0.5) * intervalo
			var p: Vector2 = centro + Vector2(x, -sin(t * PI) * raio)
			if n == 3 and w >= 43.0 and h >= 15.0:
				p.x -= 6.0
			desenhar_polen_brilhante(p, raio, str(item["cor"]))
		if n == 3 and w >= 43.0 and h >= 15.0 and t > 0.5:
			escrever("5", centro + Vector2(w * 0.30, 4.0), 10, COR_OURO)


# v160 — acomodação visual da reserva e progressão dos objetivos.
func juice_total_reserva(estoque: Dictionary) -> int:
	var total: int = 0
	for cor in CORES:
		total += int(estoque.get(cor, 0))
	return total

func juice_indice_polen(estoque: Dictionary, cor: String, ordinal: int) -> int:
	var indice: int = ordinal
	for nome in CORES:
		if nome == cor:
			break
		indice += int(estoque.get(nome, 0))
	return indice

func juice_desenhar_polen_reserva(dono: int, _estoque: Dictionary, cor: String, ordinal: int, indice: int, total: int, raio: float) -> void:
	var centro: Vector2 = centro_polen_reserva(indice, total)
	if indice_cenario_em_revisao >= 0 or partida_encerrada or duplicacao_ativa:
		desenhar_polen_brilhante(centro, raio, cor)
		return
	# A unidade está contabilizada, mas aparece na reserva apenas ao chegar.
	if not (modo_partida == "maquina" and dono >= 1):
		for lote in animacoes_coleta_aula:
			var primeiro: int = int(lote.get("primeiro_polen", -1))
			if primeiro >= 0 and int(lote["dono"]) == dono and str(lote["cor"]) == cor and ordinal >= primeiro + int(lote.get("chegados", 0)) and ordinal < primeiro + int(lote["quantidade"]):
				return
	var reflu: Dictionary = juice_reserva_refluxo.get(dono, {})
	if not reflu.is_empty():
		var anterior: Dictionary = reflu["antes"]
		if ordinal < int(anterior.get(cor, 0)):
			var t: float = clampf((juice_relogio - float(reflu["inicio"])) / (0.30 * juice_fator_tempo()), 0.0, 1.0)
			var total_antes: int = juice_total_reserva(anterior)
			var centro_antes: Vector2 = centro_polen_reserva(juice_indice_polen(anterior, cor, ordinal), total_antes)
			var raio_antes: float = minf(6.3, maxf(0.40, geometria_reserva_polens(total_antes).y * 0.30))
			centro = centro_antes.lerp(centro, interpolar_suave(t))
			raio = lerpf(raio_antes, raio, interpolar_suave(t))
	# A passagem de três para quatro objetivos reorganiza também a reserva,
	# antes de revelar as cartas novas, inclusive ao girar o celular.
	if juice_transicao_visivel():
		var slots_antes: int = int(juice_transicao_objetivos.get("slots_antes", 3))
		if slots_antes != quantidade_slots_objetivos():
			var t_etapa: float = interpolar_suave(juice_progresso(juice_transicao_objetivos) / 0.26)
			centro = centro_polen_reserva(indice, total, slots_antes).lerp(centro, t_etapa)
			var raio_antes_etapa: float = minf(6.3, maxf(0.40, geometria_reserva_polens(total, slots_antes).y * 0.30))
			raio = lerpf(raio_antes_etapa, raio, t_etapa)
	# A chegada produz um balanço amortecido, sem alterar a posição final.
	for lote in juice_reserva_pousos:
		if int(lote["dono"]) != dono or str(lote["cor"]) != cor:
			continue
		var primeiro: int = int(lote["primeiro_polen"])
		if ordinal < primeiro or ordinal >= primeiro + int(lote["quantidade"]):
			continue
		var t: float = clampf((juice_relogio - float(lote["inicio"])) / (0.34 * juice_fator_tempo()), 0.0, 1.0)
		var pulso: float = sin(t * TAU) * (1.0 - t)
		centro.y -= raio * 0.50 * maxf(0.0, pulso)
		raio *= 1.0 + pulso * 0.23
		break
	desenhar_polen_brilhante(centro, raio, cor)

func juice_iniciar_transicao_objetivos(dono: int) -> void:
	var antigos: Array[Dictionary] = []
	for carta in jogadores[dono]["objetivos"]:
		# A carta conquistada já foi arquivada; só as restantes saem do painel.
		if carta.is_empty() or linhas_pontuadas.has(str(carta.get("id", ""))):
			antigos.append({})
		else:
			antigos.append(carta.duplicate(true))
	juice_transicao_objetivos = {"dono": dono, "antigos": antigos, "slots_antes": antigos.size(), "inicio": juice_relogio, "duracao": 0.96 * juice_fator_tempo()}
	queue_redraw()

func juice_aguardar_transicao_objetivos(token: int) -> void:
	while is_inside_tree() and token == identificador_partida and estado_tela == "partida" and not partida_encerrada and not juice_transicao_objetivos.is_empty():
		await aguardar_frame_jogo()

func juice_transicao_visivel() -> bool:
	return not juice_transicao_objetivos.is_empty() and indice_cenario_em_revisao < 0 and int(juice_transicao_objetivos.get("dono", -1)) == jogador_atual

func juice_desenhar_saida_objetivos(t: float) -> void:
	var antigos: Array = juice_transicao_objetivos["antigos"]
	var suavizado: float = interpolar_suave(t)
	for i in range(antigos.size()):
		if antigos[i].is_empty():
			continue
		var r: Rect2 = retangulo_objetivo_com_slots(i, antigos.size())
		var escala: float = maxf(0.04, 1.0 - suavizado * 0.96)
		var centro: Vector2 = r.get_center() + Vector2(0.0, -r.size.y * 0.13 * suavizado)
		draw_set_transform(centro - r.get_center() * escala, 0.0, Vector2.ONE * escala)
		desenhar_objetivo(antigos[i], r, -1, false, false)
		draw_set_transform(Vector2.ZERO)

func juice_desenhar_realce_nova_etapa(r: Rect2, t: float, fada: bool) -> void:
	var pulso: float = sin(clampf((t - 0.70) / 0.30, 0.0, 1.0) * PI)
	var cor: Color = Color(0.70, 0.84, 1.0, pulso * 0.65) if fada else Color(1.0, 0.83, 0.42, pulso * 0.70)
	draw_rect(r.grow(1.5), cor, false, 2.0)
	if fada and juice_nivel > 0:
		for i in range(4):
			var angulo: float = float(i) * TAU / 4.0 + t * 2.0
			var pos: Vector2 = r.get_center() + Vector2(cos(angulo), sin(angulo)) * r.size.x * (0.38 + 0.08 * t)
			draw_circle(pos, maxf(0.8, r.size.x * 0.013), cor)


# v163 — Encerramento da Expandida: primeiro agrupa, depois apresenta o placar.
func animar_final_expandida(token: int, tocar_final: bool, pela_regra: bool) -> void:
	await get_tree().create_timer(juice_final_expandida_duracao * 0.52, false).timeout
	if not is_inside_tree() or token != identificador_partida or estado_tela != "distribuicao_final":
		return
	if not jogadores.is_empty() and tocar_final:
		var estoque: Dictionary = jogadores[0]["polens"]
		for cor in CORES:
			if int(estoque.get(cor, 0)) >= 3:
				tocar_som("coleta_4", 0.92)
				break
	await get_tree().create_timer(juice_final_expandida_duracao * 0.48, false).timeout
	if not is_inside_tree() or token != identificador_partida or estado_tela != "distribuicao_final":
		return
	finalizar_resultado_partida(tocar_final, pela_regra)

func desenhar_final_expandida() -> void:
	var tela: Vector2 = get_viewport_rect().size
	var margem: float = clampf(tela.x * 0.035, 8.0, 24.0)
	var painel: Rect2 = ui_area_segura().grow(-margem)
	ui_superficie(painel, UI_SUPERFICIE, Color("a98a5f"), 12, true)
	if jogadores.is_empty():
		return
	var estoque: Dictionary = jogadores[0]["polens"]
	var t: float = clampf((juice_relogio - juice_final_expandida_inicio) / maxf(0.01, juice_final_expandida_duracao), 0.0, 1.0)
	var base_y: float = painel.position.y + 12.0
	var compacto: bool = tela.y < 550.0
	var fonte_titulo: int = 23 if compacto else 33
	v200_texto_central_ajustado("Estrelas dos pólens", painel.get_center().x, base_y + fonte_titulo + 5.0, painel.size.x - 24.0, fonte_titulo, COR_OURO)
	v200_texto_central_ajustado(str(jogadores[0].get("nome", "Jogador")), painel.get_center().x, base_y + fonte_titulo + 32.0, painel.size.x - 24.0, 18 if compacto else 22, COR_TEXTO)
	if not compacto:
		v200_texto_central_ajustado("1 por pólen · 5 por trinca da mesma cor", painel.get_center().x, base_y + fonte_titulo + 60.0, painel.size.x - 24.0, 18, COR_TEXTO)
	var topo: float = base_y + fonte_titulo + (43.0 if compacto else 77.0)
	var rodape: float = 69.0 if compacto else 112.0
	var altura: float = maxf(16.0, (painel.end.y - rodape - topo - 12.0) / 3.0)
	var total: int = 0
	var bonus: int = 0
	for i in range(CORES.size()):
		var cor: String = CORES[i]
		var n: int = maxi(0, int(estoque.get(cor, 0)))
		var trincas: int = floori(float(n) / 3.0)
		total += n
		bonus += 2 * trincas
		var faixa: Rect2 = Rect2(Vector2(painel.position.x + 10.0, topo + float(i) * (altura + 4.0)), Vector2(painel.size.x - 20.0, altura))
		ui_superficie(faixa, Color("44372e"), Color("987c58"), 9)
		var t_cor: float = interpolar_suave((t - 0.12 - float(i) * 0.085) / 0.36)
		var bonus_cor: int = roundi(float(trincas * 2) * interpolar_suave((t_cor - 0.72) / 0.28))
		var cabecalho: float = 25.0 if compacto else 53.0
		desenhar_polen_brilhante(faixa.position + Vector2(19.0, 17.0 if compacto else 22.0), 6.0 if compacto else 10.0, cor)
		var rotulo_cor: String = "%s · %d pólens" % [nome_cor(cor).capitalize(), n]
		if compacto:
			rotulo_cor += " · +%d" % bonus_cor
		escrever_ajustado(rotulo_cor, faixa.position.x + 34.0, faixa.position.y + (22.0 if compacto else 29.0), faixa.size.x - 48.0, 16 if compacto else 24, COR_TEXTO)
		if not compacto:
			escrever_ajustado("%d trincas   ·   +%d bônus" % [trincas, bonus_cor], faixa.position.x + 14.0, faixa.position.y + 51.0, faixa.size.x - 28.0, 19, COR_PRATA)
		if n == 0:
			continue
		var area: Rect2 = Rect2(faixa.position + Vector2(10.0, cabecalho + 6.0), Vector2(maxf(1.0, faixa.size.x - 20.0), maxf(1.0, faixa.size.y - cabecalho - 12.0)))
		var grupos: int = ceili(float(n) / 3.0)
		var colunas: int = mini(grupos, maxi(1, ceili(sqrt(float(grupos) * area.size.x / maxf(1.0, area.size.y * 2.6)))))
		var linhas: int = ceili(float(grupos) / float(colunas))
		var w: float = minf(84.0, area.size.x / float(colunas))
		var h: float = minf(48.0, area.size.y / float(linhas))
		var raio: float = maxf(0.15, minf(8.0, minf(w / 10.0, h / 3.3)))
		for g in range(grupos):
			var quantidade: int = mini(3, n - 3 * g)
			var centro: Vector2 = area.get_center() - Vector2(float(colunas) * w, float(linhas) * h) * 0.5 + Vector2((float(g % colunas) + 0.5) * w, (float(floori(float(g) / float(colunas))) + 0.5) * h)
			var fechar: float = t_cor
			if quantidade == 3:
				var caixa: Rect2 = Rect2(centro - Vector2(w * 0.47, h * 0.46), Vector2(w * 0.94, h * 0.92))
				var luz: float = interpolar_suave((fechar - 0.65) / 0.35)
				draw_rect(caixa, Color(1.0, 0.82, 0.38, 0.15 * luz))
				draw_rect(caixa, Color(1.0, 0.82, 0.38, 0.82 * luz), false, 1.0)
			for j in range(quantidade):
				var x: float = (float(j) - float(quantidade - 1) * 0.5) * raio * lerpf(3.5, 2.12, fechar)
				var y: float = sin(float(j + g) * 1.9) * raio * 0.60 * (1.0 - fechar)
				desenhar_polen_brilhante(centro + Vector2(x, y), raio, cor)
	var t_bonus: float = interpolar_suave((t - 0.65) / 0.30)
	var valor: int = total + roundi(float(bonus) * t_bonus)
	v200_texto_central_ajustado("%d individuais + %d bônus" % [total, valor - total], painel.get_center().x,
		painel.end.y - (44.0 if compacto else 71.0), painel.size.x - 24.0, 17 if compacto else 21, COR_TEXTO)
	v200_texto_central_ajustado("%s por pólens" % rotulo_estrela_compacto(valor), painel.get_center().x,
		painel.end.y - (13.0 if compacto else 25.0), painel.size.x - 24.0, 26 if compacto else 38, COR_PRATA)


# Diagnóstico opcional; desativado por padrão, independente do desenho do jogo.
func perf_alternar_debug() -> void:
	if not is_instance_valid(perf_debug):
		perf_debug = Label.new()
		perf_debug.mouse_filter = Control.MOUSE_FILTER_IGNORE
		perf_debug.z_index = 100
		perf_debug.add_theme_font_size_override("font_size", 14)
		perf_debug.add_theme_color_override("font_color", Color.WHITE)
		perf_debug.add_theme_color_override("font_shadow_color", Color.BLACK)
		perf_debug.add_theme_constant_override("shadow_offset_x", 2)
		perf_debug.add_theme_constant_override("shadow_offset_y", 2)
		add_child(perf_debug)
		perf_debug.position = Vector2(10, 48)
	else:
		perf_debug.visible = not perf_debug.visible
	perf_debug_tempo = 1.0
	perf_atualizar_debug(0.0)

func perf_atualizar_debug(delta: float) -> void:
	if not is_instance_valid(perf_debug) or not perf_debug.visible:
		return
	perf_debug_tempo += delta
	if perf_debug_tempo < 0.5:
		return
	perf_debug_tempo = 0.0
	var fps: float = Engine.get_frames_per_second()
	var memoria: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var desenhos: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	perf_debug.text = "FPS %.0f | %.1f ms/frame (média) | %.1f MB estáticos | %d draw calls" % [fps, 1000.0 / maxf(fps, 1.0), memoria, desenhos]

# v177 — feedback de intenção e conexão visual da conquista.
func mobile_tem_toque() -> bool:
	return OS.has_feature("mobile") or dispositivo_mobile_web or DisplayServer.is_touchscreen_available()

func mobile_prever_rota(indice: int, destino: Vector2i) -> Dictionary:
	var coleta: int = 0
	var produz: int = 0
	var bonus: int = 0
	if indice < 0 or indice >= fadas.size():
		return {"coleta": coleta, "produz": produz, "estrelas": 0, "bonus": 0}
	var dono: int = int(fadas[indice]["dono"])
	var reserva: Dictionary = jogadores[dono]["polens"].duplicate()
	var origem: Vector2i = fadas[indice]["casa"]
	var delta: Vector2i = destino - origem
	var direcao: Vector2i = Vector2i(signi(delta.x), signi(delta.y))
	for n in range(1, maxi(absi(delta.x), absi(delta.y)) + 1):
		var c: Vector2i = origem + direcao * n
		if not CORES.has(str(tabuleiro.get(c, ""))):
			continue
		var quantidade: int = int(polens_por_casa.get(c, 0))
		if quantidade > 0:
			coleta += quantidade
			var cor: String = str(tabuleiro[c])
			var antes: int = int(reserva.get(cor, 0))
			bonus += juice_bonus_trincas(antes, quantidade)
			reserva[cor] = antes + quantidade
		else:
			produz += 1
	return {"coleta": coleta, "produz": produz, "estrelas": coleta + bonus, "bonus": bonus}

func mobile_indice_previsao_voo() -> int:
	if not mobile_contexto_jogavel() or etapa_fada not in ["oferta", "escolha"] or toque_arrastou:
		return -1
	if mobile_tem_toque() and not toque_tabuleiro:
		return -1
	var indice: int = indice_fada_clicada(mouse_pos)
	if indice < 0 or not fadas_elegiveis.has(indice) or (toque_tabuleiro and indice != mobile_fada_pressionada):
		return -1
	return indice

func mobile_desenhar_previsao_voo() -> void:
	var indice: int = mobile_indice_previsao_voo()
	if indice < 0:
		return
	var inicio: Vector2 = centro_visual_da_fada(indice)
	var fim: Vector2 = posicao_celula(destino_da_fada)
	var limite: Rect2 = area_tabuleiro.grow(-6.0)
	if limite.has_point(inicio) and limite.has_point(fim):
		draw_line(inicio, fim, Color(1.0, 0.81, 0.38, 0.22), 6.0, true)
		draw_dashed_line(inicio, fim, Color("ffe1a0"), 2.5, 6.0, true)
		var origem: Vector2i = fadas[indice]["casa"]
		var diferenca: Vector2i = destino_da_fada - origem
		var direcao: Vector2i = Vector2i(signi(diferenca.x), signi(diferenca.y))
		for passo in range(1, maxi(absi(diferenca.x), absi(diferenca.y)) + 1):
			var casa: Vector2i = origem + direcao * passo
			if not CORES.has(str(tabuleiro.get(casa, ""))):
				continue
			var quantidade: int = int(polens_por_casa.get(casa, 0))
			var centro: Vector2 = posicao_celula(casa)
			var raio: float = clampf(tamanho_carta_base_jardim() * zoom * 0.13, 5.0, 11.0)
			if limite.grow(-raio).has_point(centro):
				draw_circle(centro, raio, Color(0.12, 0.18, 0.12, 0.88))
				draw_arc(centro, raio, 0.0, TAU, 20, COR_PRATA if quantidade > 0 else Color("a1d595"), 1.4, true)
				var sinal: String = str(quantidade) if quantidade > 0 else "+"
				var largura: float = fonte.get_string_size(sinal, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
				escrever(sinal, centro + Vector2(-largura * 0.5, 4.0), 11, COR_PRATA if quantidade > 0 else Color("a1d595"))

func mobile_desenhar_constelacao() -> void:
	# Liga exclusivamente flores da combinação já validada pelo jogo.
	if not celebracao_objetivo_ativa or not mobile_constelacao_floral or celebracao_objetivo_casas.size() < 2 or indice_cenario_em_revisao >= 0:
		return
	var tempo: float = juice_relogio - float(juice_efeitos.get("celebrar", -10.0))
	var alfa: float = clampf(tempo / 0.23, 0.0, 1.0) * clampf((2.0 - tempo) / 0.35, 0.0, 1.0)
	if alfa <= 0.0:
		return
	# Árvore de vizinhos mais próximos: liga todos os componentes sem desenhar diagonais arbitrárias em excesso.
	var ligados: Array[Vector2i] = [celebracao_objetivo_casas[0]]
	var restantes: Array[Vector2i] = celebracao_objetivo_casas.duplicate()
	restantes.remove_at(0)
	var limite: Rect2 = area_tabuleiro.grow(-4.0)
	while not restantes.is_empty():
		var melhor_dist: float = INF
		var origem: Vector2i = ligados[0]
		var alvo: int = 0
		for a in ligados:
			for i in range(restantes.size()):
				var d: float = Vector2(a - restantes[i]).length_squared()
				if d < melhor_dist:
					melhor_dist = d
					origem = a
					alvo = i
		var destino: Vector2i = restantes[alvo]
		ligados.append(destino)
		restantes.remove_at(alvo)
		var a_px: Vector2 = posicao_celula(origem)
		var b_px: Vector2 = posicao_celula(destino)
		if limite.has_point(a_px) and limite.has_point(b_px):
			draw_line(a_px, b_px, Color(1.0, 0.76, 0.30, alfa * 0.20), 5.0, true)
			draw_line(a_px, b_px, Color(1.0, 0.92, 0.61, alfa * 0.88), 1.7, true)


# v185 — feedback leve: nenhuma função abaixo muda o estado das regras.
func juice_bonus_trincas(antes: int, ganho: int) -> int:
	return 2 * (floori(float(antes + ganho) / 3.0) - floori(float(antes) / 3.0))

func juice_vibrar(duracao: int) -> void:
	if estado_tela != "partida" or partida_encerrada or turno_da_maquina() or not mobile_tem_toque():
		return
	if juice_relogio - juice_ultima_vibracao < 0.12:
		return
	if not (OS.has_feature("android") or OS.has_feature("ios") or (OS.has_feature("web") and dispositivo_mobile_web)):
		return
	# A plataforma decide se o motor de vibração está disponível.
	Input.vibrate_handheld(duracao)
	juice_ultima_vibracao = juice_relogio

func juice_registrar_ganho(dono: int, valor: int, bonus: int) -> void:
	if valor <= 0:
		return
	var anterior: Dictionary = juice_ganhos_placar.get(dono, {})
	var acumular: bool = not anterior.is_empty() and juice_relogio - float(anterior.get("inicio", -10.0)) < 0.65
	juice_ganhos_placar[dono] = {"inicio": juice_relogio, "valor": valor + (int(anterior.get("valor", 0)) if acumular else 0), "bonus": bonus + (int(anterior.get("bonus", 0)) if acumular else 0)}
	queue_redraw()

func juice_desenhar_ganho(dono: int, linha: Rect2) -> void:
	var ganho: Dictionary = juice_ganhos_placar.get(dono, {})
	if ganho.is_empty():
		return
	var t: float = clampf((juice_relogio - float(ganho["inicio"])) / 1.35, 0.0, 1.0)
	var alfa: float = (1.0 - t) * (0.65 + 0.35 * sin(t * PI))
	var cor: Color = COR_PRATA_BRILHO if int(ganho["bonus"]) == 0 else Color("e2f5ca")
	# Feedback temporário no contorno; nenhum indicador de progresso permanente.
	draw_rect(linha.grow(-2.0), Color(cor, alfa * 0.75), false, 1.4)

# v187 — enquadramento não altera coordenadas lógicas nem confirma ações.
func mobile_camera_manual() -> void:
	camera_manual_ate = juice_relogio + 5.0
	camera_ajustando = false

func mobile_camera_inteligente(delta: float) -> void:
	if estado_tela != "partida" or partida_encerrada or tabuleiro.is_empty() or not area_tabuleiro.has_area() or aula_guiada_ativa():
		return
	if toque_tabuleiro or mobile_arrastando_mao or not mobile_dedos.is_empty() or mobile_fonte_pressionada >= 0 or mobile_objetivo_press >= 0 or not mobile_objetivo_ampliado.is_empty() or gesto_multitoque_ativo or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	if animacao_setup_ativa or etapa_fada == "movendo" or celebracao_objetivo_ativa or movimento_pendente or not juice_mover.is_empty() or not juice_plantar.is_empty() or aula_aviso_licao_ativo() or aula_aviso_fada_ativo() or escolha_objetivo_ativa:
		return
	var chave: Array = [identificador_partida, hash(tabuleiro), area_tabuleiro.size]
	if chave != camera_chave_v187:
		# Uma alteração do jardim pode exigir reenquadramento, mas não competir com um gesto recente.
		if juice_relogio < camera_manual_ate:
			camera_chave_v187 = chave
			return
		camera_chave_v187 = chave
		var minimo: Vector2 = Vector2(INF, INF)
		var maximo: Vector2 = Vector2(-INF, -INF)
		for casa in tabuleiro:
			minimo = minimo.min(Vector2(casa))
			maximo = maximo.max(Vector2(casa))
		var base: float = tamanho_carta_base_jardim()
		var extensao: Vector2 = maximo - minimo + Vector2.ONE * 2.0
		var livre: Vector2 = area_tabuleiro.size - Vector2.ONE * 18.0
		# Nunca aumentar automaticamente o zoom escolhido. Reduzir apenas se necessário.
		var fit: float = clampf(minf(livre.x / (extensao.x * base), livre.y / (extensao.y * base)), 0.12, 1.9)
		camera_alvo_zoom = minf(zoom, fit)
		camera_alvo_offset = -(minimo + maximo) * 0.5 * base * camera_alvo_zoom
		camera_ajustando = true
	if camera_ajustando:
		var fator: float = 1.0 - exp(-delta * 11.0)
		zoom = lerpf(zoom, camera_alvo_zoom, fator)
		deslocamento = deslocamento.lerp(camera_alvo_offset, fator)
		if absf(zoom - camera_alvo_zoom) < 0.002 and deslocamento.distance_to(camera_alvo_offset) < 0.5:
			zoom = camera_alvo_zoom
			deslocamento = camera_alvo_offset
			camera_ajustando = false
		queue_redraw()

func mobile_abrir_objetivo_ampliado(objetivo: Dictionary) -> void:
	mobile_objetivo_ampliado = objetivo.duplicate(true)
	mobile_objetivo_fechar_press = false
	for filho in get_children():
		if filho is Control:
			var controle: Control = filho as Control
			mobile_objetivo_controles[controle] = controle.show_behind_parent
			controle.show_behind_parent = true
	queue_redraw()

func mobile_fechar_objetivo_ampliado() -> void:
	mobile_objetivo_ampliado.clear()
	mobile_objetivo_fechar_press = false
	for filho in mobile_objetivo_controles:
		if is_instance_valid(filho):
			var controle: Control = filho as Control
			controle.show_behind_parent = bool(mobile_objetivo_controles[filho])
	mobile_objetivo_controles.clear()
	queue_redraw()

func mobile_desenhar_objetivo_ampliado() -> void:
	var tela: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, tela), Color(0.04, 0.03, 0.02, 0.83))
	var lado: float = minf(350.0, minf(ui_area_segura().size.x - 38.0, ui_area_segura().size.y - 160.0))
	var carta: Rect2 = Rect2((tela - Vector2.ONE * lado) * 0.5, Vector2.ONE * lado)
	var painel: Rect2 = Rect2(carta.position - Vector2(9.0, 47.0), carta.size + Vector2(18.0, 103.0))
	ui_superficie(painel, Color("342b26"), UI_BORDA, 12, true)
	escrever_centralizado("Objetivo", tela.x * 0.5, carta.position.y - 17.0, 28, COR_OURO)
	desenhar_objetivo(mobile_objetivo_ampliado, carta, -1, false, false)
	escrever_centralizado("Toque para fechar", tela.x * 0.5, carta.end.y + 33.0, 20, COR_TEXTO)


# v190 — materialidade e feedback. Todas as previsões usam cópias e validadores existentes.
func feel_casa_magnetica(pos: Vector2) -> Vector2i:
	if not area_tabuleiro.has_point(pos):
		return CELULA_INVALIDA
	var base: Vector2i = celula_na_posicao(pos)
	if mobile_pode_prever_plantio(base):
		return base
	# Não puxar uma carta ao tocar no centro de uma flor ocupada.
	var distancia: float = tamanho_carta_base_jardim() * zoom * 0.60
	var melhor: Vector2i = CELULA_INVALIDA
	for d in VIZINHOS:
		var candidata: Vector2i = base + d
		if not mobile_pode_prever_plantio(candidata):
			continue
		var dist: float = pos.distance_to(posicao_celula(candidata))
		if dist < distancia and area_tabuleiro.has_point(posicao_celula(candidata)):
			distancia = dist
			melhor = candidata
	return melhor

func feel_atualizar(delta: float) -> void:
	if not v209_retorno_borda.is_empty():
		if not mobile_contexto_jogavel() or juice_progresso(v209_retorno_borda) >= 1.0:
			v209_retorno_borda.clear()
		queue_redraw()
	if v199_arrasto_ativo() and not mobile_contexto_jogavel():
		mobile_limpar_intencao()
	if estado_tela != "partida" or partida_encerrada:
		feel_retorno.clear()
		feel_estrelas.clear()
		feel_trincas.clear()
		return
	if feel_turno != jogador_atual:
		feel_turno_anterior = feel_turno
		feel_turno = jogador_atual
		feel_turno_inicio = juice_relogio
		feel_retorno.clear()
	var vento_alvo: float = 0.0
	if not juice_voo.is_empty() and str(juice_voo.get("fase", "")) == "viajar":
		var t_voo: float = voo_progresso_espacial(juice_progresso(juice_voo), int(juice_voo["total"]))
		feel_vento_centro = posicao_celula(juice_voo["origem"]).lerp(posicao_celula(juice_voo["destino"]), t_voo)
		vento_alvo = 1.0
	feel_vento_forca = move_toward(feel_vento_forca, vento_alvo, delta * 5.0)
	feel_vento_ativo = feel_vento_forca > 0.001
	if feel_vento_ativo:
		queue_redraw()
	if mobile_borda_arrastada != CELULA_INVALIDA:
		var lado_borda: float = tamanho_carta_base_jardim() * zoom
		var margem_borda: Vector2 = Vector2.ONE * lado_borda * 0.52
		feel_alvo = mouse_pos - Vector2(0.0, minf(12.0, lado_borda * 0.12))
		var casa_borda: Vector2i = v199_destino_borda(mouse_pos)
		if casa_borda != CELULA_INVALIDA:
			feel_alvo = feel_alvo.lerp(posicao_celula(casa_borda), 0.90)
		feel_alvo = feel_alvo.clamp(area_tabuleiro.position + margem_borda, area_tabuleiro.end - margem_borda)
		feel_pos = feel_pos.lerp(feel_alvo, 1.0 - exp(-delta * 30.0))
		feel_angulo = lerpf(feel_angulo, feel_inclinacao_alvo, 1.0 - exp(-delta * 20.0))
		feel_inclinacao_alvo *= exp(-delta * 15.0)
		queue_redraw()
	if mobile_arrastando_mao or mobile_arrastando_coletiva:
		feel_alvo = mouse_pos - Vector2(0.0, 18.0)
		var casa: Vector2i = feel_casa_magnetica(mouse_pos)
		if casa != CELULA_INVALIDA:
			feel_alvo = feel_alvo.lerp(posicao_celula(casa), 0.85)
		feel_pos = feel_pos.lerp(feel_alvo, 1.0 - exp(-delta * 26.0))
		feel_angulo = lerpf(feel_angulo, feel_inclinacao_alvo, 1.0 - exp(-delta * 18.0))
		feel_inclinacao_alvo *= exp(-delta * 13.0)
		queue_redraw()
	if not feel_retorno.is_empty():
		if juice_progresso(feel_retorno) >= 1.0 or flor_na_mao != str(feel_retorno["cor"]) or not mobile_contexto_jogavel():
			feel_retorno.clear()
		queue_redraw()
	for efeitos in [feel_estrelas, feel_trincas]:
		for i in range(efeitos.size() - 1, -1, -1):
			if juice_progresso(efeitos[i]) >= 1.0:
				efeitos.remove_at(i)
			queue_redraw()
	if juice_relogio - feel_turno_inicio < 0.30:
		queue_redraw()
	if v199_arrasto_ativo():
		v209_atualizar_encaixe()
		v199_atualizar_previa_arrasto()
	else:
		v209_encaixe = CELULA_INVALIDA
		feel_previa_casas.clear()
		feel_previa_arrasto_chave.clear()
		feel_atualizar_previsao()

func v209_casas_candidatas() -> Array[Vector2i]:
	var chave: Array = [identificador_partida, turnos_jogados, tabuleiro.hash()]
	if chave != v209_candidatas_chave:
		v209_candidatas_chave = chave
		var vistas: Dictionary = {}
		v209_candidatas.clear()
		for origem in tabuleiro:
			for d in VIZINHOS:
				var c: Vector2i = origem + d
				if not vistas.has(c) and pode_colocar(c):
					vistas[c] = true
					v209_candidatas.append(c)
	return v209_candidatas

func feel_atualizar_previsao() -> void:
	# A busca global é um auxílio visual. Fatias cooperativas evitam travar o toque.
	if not mobile_contexto_jogavel() or pratica_com_dicas_breves() or etapa_fada != "" or flor_na_mao == "" or movimento_pendente or origem_selecionada != CELULA_INVALIDA:
		if not feel_previsao_ids.is_empty():
			queue_redraw()
		feel_previsao_chave.clear()
		feel_previsao_ids.clear()
		v209_previsao_fila.clear()
		v209_previsao_cursor = 0
		return
	var chave: Array = [identificador_partida, turnos_jogados, jogador_atual, flor_na_mao, tabuleiro.hash(), jogadores[jogador_atual]["objetivos"].hash()]
	if chave != feel_previsao_chave:
		feel_previsao_chave = chave
		feel_previsao_ids.clear()
		v209_previsao_fila = v209_casas_candidatas().duplicate()
		v209_previsao_cursor = 0
		queue_redraw()
	if v209_previsao_cursor >= v209_previsao_fila.size():
		return
	var inicio: int = Time.get_ticks_usec()
	var alterou: bool = false
	while v209_previsao_cursor < v209_previsao_fila.size():
		var c: Vector2i = v209_previsao_fila[v209_previsao_cursor]
		v209_previsao_cursor += 1
		var previsto: Dictionary = tabuleiro.duplicate()
		previsto[c] = flor_na_mao
		var alteradas: Array[Vector2i] = [c]
		for opcao in opcoes_florais_concluidas_na_jogada(jogador_atual, alteradas, tabuleiro, previsto, CELULA_INVALIDA):
			var id_carta: String = str(opcao["id"])
			if not feel_previsao_ids.has(id_carta):
				feel_previsao_ids[id_carta] = true
				alterou = true
		if Time.get_ticks_usec() - inicio >= (1200 if v209_leve else 2400):
			break
	if alterou:
		queue_redraw()

func feel_lado_arrasto() -> float:
	var lado: float = (area_aberta.size.x if mobile_arrastando_coletiva else area_mao.size.x) * 0.94
	return minf(lado, tamanho_carta_base_jardim() * zoom) if area_tabuleiro.has_point(mouse_pos) else lado

func feel_desenhar_mao() -> void:
	var pos: Vector2
	var angulo: float
	var cor: String = flor_aberta if mobile_arrastando_coletiva else flor_na_mao
	var lado: float = area_mao.size.x * 0.94
	if (mobile_arrastando_mao or mobile_arrastando_coletiva) and cor != "":
		pos = feel_pos
		angulo = feel_angulo
		lado = feel_lado_arrasto()
	elif not feel_retorno.is_empty() and flor_na_mao == str(feel_retorno["cor"]):
		var t: float = interpolar_suave(juice_progresso(feel_retorno))
		var inicio: Vector2 = feel_retorno["pos"]
		pos = inicio.lerp(area_mao.get_center(), t)
		angulo = float(feel_retorno["angulo"]) * (1.0 - t)
		lado = lerpf(float(feel_retorno.get("lado", lado)), lado, t)
	else:
		return
	var sombra: Vector2 = pos + Vector2(4.0 + absf(angulo) * 12.0, 8.0)
	for i in range(3, 0, -1):
		var borda: float = float(i) * 2.0
		draw_rect(Rect2(sombra - Vector2.ONE * lado * 0.5, Vector2.ONE * lado).grow(borda), Color(0.03, 0.02, 0.01, 0.045))
	draw_set_transform(pos, angulo)
	desenhar_carta(Vector2.ZERO, lado, cor, 1.0)
	draw_set_transform(Vector2.ZERO)

func feel_desenhar_grama() -> void:
	var lado: float = tamanho_carta_base_jardim() * zoom
	for c in tabuleiro:
		var idade: float = juice_relogio - float(juice_efeitos.get("encaixe:%s" % str(c), -10.0))
		if idade < 0.0 or idade > 0.42:
			continue
		var t: float = idade / 0.42
		var centro: Vector2 = posicao_celula(c)
		for d in VIZINHOS:
			var vizinha: Vector2i = c + d
			if not tabuleiro.has(vizinha):
				continue
			var p: Vector2 = centro + Vector2(d) * lado * (0.48 + 0.22 * t)
			if area_tabuleiro.grow(-5.0).has_point(p):
				draw_arc(p, lado * 0.13, 0.0, TAU, 12, Color(0.74, 0.93, 0.46, 0.24 * sin(t * PI)), 1.5, true)
		for i in range(5):
			var rumo: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / 5.0)
			var p: Vector2 = centro + rumo * lado * (0.22 + 0.33 * t)
			if area_tabuleiro.grow(-3.0).has_point(p):
				draw_line(p, p + rumo * 4.0, Color(0.81, 0.94, 0.57, 0.55 * (1.0 - t)), 1.6, true)

func feel_estrela(pos: Vector2, raio: float, alfa: float, angulo: float = 0.0) -> void:
	var pontos: PackedVector2Array = PackedVector2Array()
	for i in range(10):
		var a: float = -PI * 0.5 + float(i) * PI / 5.0 + angulo
		pontos.append(pos + Vector2(cos(a), sin(a)) * raio * (1.0 if i % 2 == 0 else 0.43))
	draw_colored_polygon(pontos, Color(COR_PRATA_BRILHO, alfa))

func feel_lancar_estrelas(dono: int, origem: Vector2, valor: int) -> void:
	feel_estrelas.append({"dono": dono, "origem": origem, "valor": valor, "inicio": juice_relogio, "duracao": 0.62 * juice_fator_tempo()})

func feel_trinca(dono: int, cor: String) -> void:
	feel_trincas.append({"dono": dono, "cor": cor, "inicio": juice_relogio, "duracao": 0.56 * juice_fator_tempo()})
	feel_lancar_estrelas(dono, centro_grupo_polen(cor), 2)

func feel_desenhar_recompensas() -> void:
	for e in feel_trincas:
		if int(e["dono"]) != jogador_atual:
			continue
		var t: float = juice_progresso(e)
		var p: Vector2 = centro_grupo_polen(str(e["cor"]))
		for i in range(3):
			var a: float = float(i) * TAU / 3.0 - PI * 0.5
			var q: Vector2 = p + Vector2(cos(a), sin(a)) * lerpf(14.0, 5.0, t)
			draw_circle(q, 3.0 * (1.0 - t) + 1.0, Color(COR_PRATA_BRILHO, 1.0 - t))
		draw_arc(p, 8.0 + t * 9.0, 0, TAU, 20, Color(COR_PRATA, sin(t * PI)), 1.5, true)
	for e in feel_estrelas:
		var t: float = juice_progresso(e)
		var origem: Vector2 = e["origem"]
		var fim: Vector2 = retangulo_linha_placar(int(e["dono"])).get_center()
		var n: int = mini(5, int(e["valor"]))
		for i in range(n):
			var u: float = clampf((t - float(i) * 0.045) / 0.82, 0.0, 1.0)
			var q: Vector2 = origem.lerp(fim, interpolar_suave(u)) + Vector2(sin(u * PI) * (18.0 + float(i) * 5.0), -sin(u * PI) * 28.0)
			if u < 1.0:
				feel_estrela(q, lerpf(8.0, 3.0, u), 0.95, u * 1.2)
		if t > 0.82:
			draw_arc(fim, 5.0 + (t - 0.82) * 45.0, 0, TAU, 18, Color(COR_PRATA, (1.0 - t) * 4.0), 1.6, true)


# v199 — gestos, prévias locais e atmosfera; não há mutação de regra antes da confirmação.
func v199_arrasto_ativo() -> bool:
	return mobile_arrastando_mao or mobile_arrastando_coletiva or mobile_borda_arrastada != CELULA_INVALIDA

func v199_pode_arrastar_borda(origem: Vector2i) -> bool:
	if not mobile_contexto_jogavel() or etapa_fada != "" or movimento_pendente or aguardando_reposicao_automatica or not juice_mover.is_empty():
		return false
	if acao_nova not in ["", "plantar", "mover"] or not pode_deslocar_origem(origem) or not acao_permitida_no_tutorial_novo("mover"):
		return false
	if origem_selecionada != CELULA_INVALIDA and origem_selecionada != origem:
		return false
	if aula_guiada_ativa():
		return origem == aula_origem() and (aula_alvo_tabuleiro() == origem or (origem_selecionada == origem and aula_alvo_tabuleiro() == aula_destino()))
	return not tutorial_novo_ativo()

func v199_destino_borda(pos: Vector2) -> Vector2i:
	var origem: Vector2i = mobile_borda_arrastada
	if not area_tabuleiro.has_point(pos) or not v199_pode_arrastar_borda(origem):
		return CELULA_INVALIDA
	var melhor: Vector2i = CELULA_INVALIDA
	var distancia: float = tamanho_carta_base_jardim() * zoom * 0.61
	for d in VIZINHOS:
		var c: Vector2i = origem + d
		if not destino_valido_para_movimento(origem, c) or (aula_guiada_ativa() and c != aula_destino()):
			continue
		var centro: Vector2 = posicao_celula(c)
		var dist: float = centro.distance_to(pos)
		if dist < distancia and area_tabuleiro.has_point(centro):
			distancia = dist
			melhor = c
	return melhor

func v199_soltar_borda(pos: Vector2) -> void:
	var origem: Vector2i = mobile_borda_arrastada
	var destino: Vector2i = v199_destino_borda(pos)
	var valido: bool = mobile_token_tabuleiro == identificador_partida and mobile_turno_tabuleiro == turnos_jogados and not mobile_gesto_cancelado and not gesto_multitoque_ativo and destino != CELULA_INVALIDA
	var rel: Vector2 = (feel_pos - posicao_celula(destino)) / maxf(1.0, tamanho_carta_base_jardim() * zoom) if valido else Vector2.ZERO
	var angulo: float = feel_angulo * v199_margem_inclinacao(feel_pos)
	var retorno: Vector2 = (feel_pos - posicao_celula(origem)) / maxf(1.0, tamanho_carta_base_jardim() * zoom)
	var pode_retornar: bool = mobile_token_tabuleiro == identificador_partida and mobile_turno_tabuleiro == turnos_jogados and not mobile_gesto_cancelado and not gesto_multitoque_ativo and tabuleiro.has(origem) and mobile_contexto_jogavel()
	mobile_limpar_intencao()
	if not valido:
		if pode_retornar:
			v209_retorno_borda = {"casa": origem, "rel": retorno, "angulo": angulo, "inicio": juice_relogio, "duracao": 0.22}
			queue_redraw()
		return
	# Passa pelo mesmo fluxo de dois toques, inclusive nas lições guiadas.
	if origem_selecionada != origem:
		executar_acao_no_tabuleiro(origem, posicao_celula(origem))
	if origem_selecionada == origem:
		feel_inicio_deslocamento = {"rel": rel, "angulo": angulo}
		executar_acao_no_tabuleiro(destino, posicao_celula(destino))
		feel_inicio_deslocamento.clear()
	queue_redraw()

func v199_margem_inclinacao(centro: Vector2) -> float:
	var lado: float = tamanho_carta_base_jardim() * zoom
	var margem: float = minf(minf(centro.x - area_tabuleiro.position.x, area_tabuleiro.end.x - centro.x), minf(centro.y - area_tabuleiro.position.y, area_tabuleiro.end.y - centro.y))
	return clampf((margem - lado * 0.50) / maxf(1.0, lado * 0.16), 0.0, 1.0)

func v199_camera_arrasto(delta: float) -> void:
	# Não mudar o enquadramento didático enquanto um alvo é obrigatório.
	if not v199_arrasto_ativo() or not mobile_contexto_jogavel() or aula_guiada_ativa() or not area_tabuleiro.has_point(mouse_pos) or gesto_multitoque_ativo:
		return
	var faixa: float = minf(38.0, minf(area_tabuleiro.size.x, area_tabuleiro.size.y) * 0.13)
	var centro: Vector2 = area_tabuleiro.get_center()
	var livre: Vector2 = area_tabuleiro.size * 0.5 - Vector2.ONE * faixa
	var dif: Vector2 = mouse_pos - centro
	var eixo: Vector2 = Vector2(signf(dif.x) * clampf((absf(dif.x) - livre.x) / faixa, 0.0, 1.0), signf(dif.y) * clampf((absf(dif.y) - livre.y) / faixa, 0.0, 1.0))
	if eixo.length_squared() < 0.001:
		return
	var passo: float = tamanho_carta_base_jardim() * zoom
	var menor: Vector2 = Vector2(INF, INF)
	var maior: Vector2 = Vector2(-INF, -INF)
	for c in tabuleiro:
		menor = menor.min(Vector2(c))
		maior = maior.max(Vector2(c))
	var antes: Vector2 = deslocamento
	var desejado: Vector2 = deslocamento - eixo * passo * 1.65 * minf(delta, 0.05)
	# Só limita o eixo que se move, sem saltar se o usuário já afastou a câmera.
	var limite_min: Vector2 = -maior * passo - area_tabuleiro.size * 0.5 + Vector2.ONE * passo * 0.6
	var limite_max: Vector2 = -menor * passo + area_tabuleiro.size * 0.5 - Vector2.ONE * passo * 0.6
	deslocamento = desejado.clamp(limite_min.min(antes), limite_max.max(antes))
	if antes != deslocamento:
		mobile_camera_manual()
		queue_redraw()

func v199_atualizar_previa_arrasto() -> void:
	# Em aula, não revelar respostas além dos destaques/dicas já previstos.
	feel_previsao_chave.clear()
	if not mobile_contexto_jogavel() or pratica_com_dicas_breves() or etapa_fada != "":
		feel_previa_casas.clear()
		feel_previsao_ids.clear()
		feel_previa_arrasto_chave.clear()
		return
	var origem: Vector2i = mobile_borda_arrastada
	var destino: Vector2i = v199_destino_borda(mouse_pos) if origem != CELULA_INVALIDA else feel_casa_magnetica(mouse_pos)
	var cor: String = flor_aberta if mobile_arrastando_coletiva else flor_na_mao
	var chave: Array = [identificador_partida, turnos_jogados, jogador_atual, origem, destino, cor, tabuleiro.hash(), jogadores[jogador_atual]["objetivos"].hash()]
	if chave == feel_previa_arrasto_chave:
		return
	feel_previa_arrasto_chave = chave
	feel_previa_casas.clear()
	feel_previsao_ids.clear()
	if destino == CELULA_INVALIDA or cor == "":
		return
	var previsto: Dictionary = tabuleiro.duplicate()
	var alteradas: Array[Vector2i] = [destino]
	if origem != CELULA_INVALIDA:
		# Só há previsão certa de deslocamento quando a reposição já é conhecida.
		previsto[destino] = previsto[origem]
		previsto[origem] = cor
		alteradas.append(origem)
	else:
		previsto[destino] = cor
	for opcao in opcoes_florais_concluidas_na_jogada(jogador_atual, alteradas, tabuleiro, previsto, origem):
		feel_previsao_ids[str(opcao["id"])] = true
		for casa in casas_do_objetivo_concluido(str(opcao["chave"])):
			feel_previa_casas[casa] = true
	queue_redraw()

func v199_desenhar_previa_arrasto() -> void:
	var lado: float = tamanho_carta_base_jardim() * zoom
	if mobile_borda_arrastada != CELULA_INVALIDA:
		var origem: Vector2i = mobile_borda_arrastada
		var destino: Vector2i = v199_destino_borda(mouse_pos)
		for d in VIZINHOS:
			var c: Vector2i = origem + d
			if not destino_valido_para_movimento(origem, c) or (aula_guiada_ativa() and c != aula_destino()):
				continue
			var r: Rect2 = Rect2(posicao_celula(c) - Vector2.ONE * lado * 0.46, Vector2.ONE * lado * 0.92).intersection(area_tabuleiro)
			if r.has_area():
				draw_rect(r, Color(0.40, 0.76, 1.0, 0.12 if c != destino else 0.28))
				draw_rect(r, Color(0.49, 0.80, 1.0, 0.80), false, 2.0)
	for c in feel_previa_casas:
		var r: Rect2 = Rect2(posicao_celula(c) - Vector2.ONE * lado * 0.47, Vector2.ONE * lado * 0.94).intersection(area_tabuleiro.grow(-1.0))
		if r.has_area():
			draw_rect(r, Color(1.0, 0.79, 0.30, 0.12))
			draw_rect(r, Color(1.0, 0.88, 0.48, 0.85), false, 2.0)

func v199_desenhar_reacao_grama() -> void:
	if not v199_arrasto_ativo() or not area_tabuleiro.has_point(mouse_pos):
		return
	var lado: float = tamanho_carta_base_jardim() * zoom
	var base: Vector2i = celula_na_posicao(feel_pos)
	# No máximo nove casas próximas e três traços por casa; não percorrer o jardim inteiro.
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var c: Vector2i = base + Vector2i(dx, dy)
			if not tabuleiro.has(c) or c == mobile_borda_arrastada:
				continue
			var centro: Vector2 = posicao_celula(c)
			var direcao: Vector2 = (centro - feel_pos).normalized()
			var forca: float = clampf(1.0 - centro.distance_to(feel_pos) / maxf(1.0, lado * 1.25), 0.0, 1.0)
			if forca <= 0.0:
				continue
			for i in range(3):
				var p: Vector2 = centro - direcao * lado * 0.30 + direcao.orthogonal() * float(i - 1) * lado * 0.13
				var ponta: Vector2 = p + (direcao * 0.13 + Vector2.UP * 0.08) * lado * forca
				if area_tabuleiro.grow(-2.0).has_point(p) and area_tabuleiro.grow(-2.0).has_point(ponta):
					draw_line(p, ponta, Color(0.77, 0.94, 0.57, 0.55 * forca), 1.4, true)

func v199_gerar_ambiente() -> AudioStreamWAV:
	# Vento suave original; harmônicos de período inteiro formam um loop contínuo.
	var taxa: int = 11025
	var duracao: float = 8.0
	var n: int = int(duracao * float(taxa))
	var dados: PackedByteArray = PackedByteArray()
	dados.resize(n * 2)
	var rng_ambiente: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_ambiente.seed = 19937
	var ruido: PackedFloat32Array = PackedFloat32Array()
	ruido.resize(n)
	for i in range(n):
		ruido[i] = rng_ambiente.randf_range(-1.0, 1.0)
	for i in range(n):
		var t: float = float(i) / float(taxa)
		var ar: float = 0.0
		for k in range(-8, 9, 2):
			ar += ruido[posmod(i + k, n)] / 9.0
		var envoltoria: float = 0.67 + 0.18 * sin(TAU * t / duracao) + 0.07 * sin(TAU * t * 0.375)
		var amostra: float = ar * envoltoria * 0.45
		# Dois chamados distantes, breves e sem melodia repetitiva de destaque.
		for inicio in [1.7, 5.4]:
			var dt: float = t - float(inicio)
			if dt > 0.0 and dt < 0.22:
				amostra += 0.025 * pow(sin(PI * dt / 0.22), 2.0) * sin(TAU * (1420.0 * dt + 440.0 * dt * dt))
		var valor: int = clampi(roundi(amostra * 32767.0), -32768, 32767)
		dados[i * 2] = valor & 255
		dados[i * 2 + 1] = (valor >> 8) & 255
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = taxa
	wav.stereo = false
	wav.data = dados
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = n
	return wav

func v199_parar_ambiente() -> void:
	if ambiente_web_ativo and audio_web_disponivel:
		var ponte: JavaScriptObject = JavaScriptBridge.get_interface("__jardimAudio121")
		if ponte != null:
			ponte.stopAmbient()
	ambiente_web_ativo = false
	ambiente_proximo = 0.0
	if is_instance_valid(ambiente_canal):
		ambiente_canal.stop()
		ambiente_canal.volume_db = -60.0

func v199_atualizar_ambiente(delta: float) -> void:
	if not audio_ativo or not ambiente_foco or estado_tela != "partida" or partida_encerrada or pausa_saida_ativa or indice_cenario_em_revisao >= 0:
		if ambiente_web_ativo or (is_instance_valid(ambiente_canal) and ambiente_canal.playing):
			v199_parar_ambiente()
		return
	if not is_instance_valid(ambiente_canal):
		return
	var alvo: float = -28.0 if etapa_fada != "movendo" else -34.0
	if audio_web_disponivel:
		if ambiente_web_ativo and juice_relogio < ambiente_proximo:
			return
		ambiente_proximo = juice_relogio + 0.20
		var ponte: JavaScriptObject = JavaScriptBridge.get_interface("__jardimAudio121")
		if ponte != null and ponte.setAmbient(alvo) == true:
			ambiente_web_ativo = true
			if ambiente_canal.playing:
				ambiente_canal.stop()
			return
		ambiente_web_ativo = false
	ambiente_canal.volume_db = lerpf(ambiente_canal.volume_db, alvo, 1.0 - exp(-delta * 4.0))
	if not ambiente_canal.playing:
		ambiente_canal.play()


# v209 — Web mobile: orçamento adaptativo de detalhes e feedback magnético.
func v209_atualizar_qualidade(delta: float) -> void:
	if not OS.has_feature("web") or not mobile_tem_toque() or not ambiente_foco:
		return
	v209_amostra += minf(delta, 0.1)
	if v209_amostra < 1.0:
		return
	v209_amostra = 0.0
	var fps: float = Engine.get_frames_per_second()
	if fps < 42.0:
		v209_lento += 1
		v209_rapido = 0
	elif fps >= 56.0:
		v209_rapido += 1
		v209_lento = 0
	else:
		v209_lento = 0
		v209_rapido = 0
	if v209_lento >= 2 and not v209_leve:
		v209_leve = true
		queue_redraw()
	elif v209_rapido >= 8 and v209_leve:
		v209_leve = false
		queue_redraw()

func v209_atualizar_encaixe() -> void:
	var c: Vector2i = v199_destino_borda(mouse_pos) if mobile_borda_arrastada != CELULA_INVALIDA else feel_casa_magnetica(mouse_pos)
	if c == v209_encaixe:
		return
	v209_encaixe = c
	v209_encaixe_inicio = juice_relogio
	if c != CELULA_INVALIDA and juice_relogio - v209_encaixe_som >= 0.18:
		juice_vibrar(8)
		v209_encaixe_som = juice_relogio

func v209_desenhar_encaixe() -> void:
	if not v199_arrasto_ativo() or v209_encaixe == CELULA_INVALIDA:
		return
	var lado: float = tamanho_carta_base_jardim() * zoom
	var centro: Vector2 = posicao_celula(v209_encaixe)
	var r: Rect2 = Rect2(centro - Vector2.ONE * lado * 0.48, Vector2.ONE * lado * 0.96)
	if not area_tabuleiro.encloses(r):
		return
	var t: float = clampf((juice_relogio - v209_encaixe_inicio) / 0.18, 0.0, 1.0)
	var cor: Color = Color("f9dc8c") if not feel_previsao_ids.is_empty() else Color("d5f1ad")
	var comprimento: float = minf(14.0, lado * 0.23)
	var expansao: float = 3.0 * (1.0 - interpolar_suave(t))
	r = r.grow(expansao)
	for canto in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var ponto: Vector2 = r.get_center() + canto * r.size * 0.5
		draw_line(ponto, ponto - Vector2(canto.x * comprimento, 0), cor, 2.5, true)
		draw_line(ponto, ponto - Vector2(0, canto.y * comprimento), cor, 2.5, true)
