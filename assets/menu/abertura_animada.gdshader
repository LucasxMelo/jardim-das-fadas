shader_type canvas_item;
render_mode unshaded;

// v168: a ilustração inteira permanece estática, sem deformações.
// Apenas a iluminação, o brilho e as partículas são animados.
uniform bool retrato = false;
uniform bool modo_leve = false;
uniform float tempo = 0.0;
uniform float intensidade : hint_range(0.0, 1.25) = 1.0;

float mascara(vec2 p, vec2 c, vec2 r) {
	float d = length((p - c) / r);
	return 1.0 - smoothstep(0.55, 1.0, d);
}
float rand2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float poeira(vec2 p, vec2 grade, float velocidade, float camada) {
	vec2 q = p * grade + vec2(sin(tempo * 0.19 + camada) * 0.20, tempo * velocidade);
	vec2 cel = floor(q);
	float s = rand2(cel + camada);
	vec2 local = fract(q) - vec2(0.20 + 0.60 * s, 0.20 + 0.60 * rand2(cel + 19.0 + camada));
	float d = length(local);
	float pulso = 0.35 + 0.65 * pow(0.5 + 0.5 * sin(tempo * 1.8 + s * 38.0), 2.0);
	return (1.0 - smoothstep(0.015, 0.055, d)) * pulso * step(0.55, s);
}

void fragment() {
	vec2 p = UV;
	float cx = retrato ? 0.500 : 0.279;
	vec2 flor = vec2(cx, retrato ? 0.466 : 0.700);
	vec2 rf = retrato ? vec2(0.139, 0.077) : vec2(0.070, 0.114);
	vec4 base = texture(TEXTURE, UV);
	vec3 cor = base.rgb;
	float ouro = smoothstep(0.37, 0.83, cor.r) * smoothstep(0.13, 0.55, cor.g);
	// Reflexo curto, confinado às letras douradas; sem faixa retangular.
	vec2 titulo = vec2(cx, retrato ? 0.182 : 0.273);
	vec2 rt = retrato ? vec2(0.405, 0.107) : vec2(0.200, 0.150);
	vec2 borda_titulo = abs((p - titulo) / rt);
	float mt = (1.0 - smoothstep(0.83, 1.0, borda_titulo.x)) * (1.0 - smoothstep(0.72, 1.0, borda_titulo.y));
	float ciclo = mod(tempo + 0.55, 7.5);
	float varredura = clamp(ciclo / 1.65, 0.0, 1.0);
	float x_reflexo = mix(titulo.x - rt.x * 1.4, titulo.x + rt.x * 1.4, varredura);
	float faixa = 1.0 - smoothstep(0.0, rt.x * 0.17, abs(p.x - x_reflexo + (p.y - titulo.y) * 0.22));
	float brilho = faixa * mt * ouro * (1.0 - smoothstep(1.4, 1.65, ciclo));
	cor += vec3(0.24, 0.16, 0.055) * brilho * intensidade;
	// Estrela e iluminação de palco já presentes na pintura.
	vec2 estrela = vec2(cx, retrato ? 0.069 : 0.109);
	float luz_estrela = mascara(p, estrela, retrato ? vec2(0.061, 0.042) : vec2(0.032, 0.065));
	float respirar = 0.5 + 0.5 * sin(tempo * 1.5);
	cor += vec3(0.14, 0.09, 0.025) * luz_estrela * (0.35 + 0.65 * respirar) * intensidade;
	// Um feixe de luz se abre da estrela até o jardim na entrada e respira depois.
	float y_feixe = smoothstep(estrela.y - 0.04, estrela.y + 0.06, p.y) * (1.0 - smoothstep(flor.y - 0.05, flor.y + 0.10, p.y));
	float largura_feixe = (retrato ? 0.025 : 0.014) + max(0.0, p.y - estrela.y) * (retrato ? 0.35 : 0.20);
	float feixe = (1.0 - smoothstep(0.0, largura_feixe, abs(p.x - cx))) * y_feixe;
	cor += vec3(0.09, 0.045, 0.008) * feixe * (0.30 + 0.70 * respirar) * intensidade;
	float luz_flor = mascara(p, flor, rf * 1.45);
	cor += vec3(0.075, 0.042, 0.006) * luz_flor * respirar * intensidade;
	// Partículas dispersas somente na área ilustrada, nunca sobre os botões.
	vec2 cp = retrato ? vec2(0.50, 0.34) : vec2(0.28, 0.47);
	vec2 rp = retrato ? vec2(0.48, 0.30) : vec2(0.25, 0.46);
	float area = mascara(p, cp, rp) * (1.0 - mt * 0.90);
	vec2 grade = retrato ? vec2(11.0, 19.5) : vec2(20.0, 11.25);
	if (area > 0.0 && intensidade > 0.0) {
		float pontos = poeira(p, grade, 0.16, 1.0);
		if (!modo_leve) {
			pontos += 0.50 * poeira(p, grade * 1.37, 0.23, 8.0);
		}
		cor += vec3(0.60, 0.37, 0.09) * pontos * area * intensidade;
	}
	// Entrada em luz, não em preto: a arte permanece legível desde o primeiro quadro.
	float entrada = smoothstep(0.0, 1.05, tempo);
	cor *= mix(0.84, 1.0, entrada);
	COLOR = vec4(clamp(cor, vec3(0.0), vec3(1.0)), base.a);
}
