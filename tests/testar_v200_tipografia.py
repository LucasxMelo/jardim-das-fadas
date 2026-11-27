"""Geometria independente das novas telas; não substitui execução no Godot."""
from pathlib import Path
from math import ceil

casos = 0
for w in (320, 360, 390, 420, 480, 540, 720):
    for h in (360, 400, 480, 520, 600, 720, 800, 920, 1000):
        pw, ph = min(540, w-28), min(860, h-24)
        y = (h-ph)/2
        compacto = ph < 370
        bh = 40 if ph < 420 else 48 if ph < 600 else 56
        gap, bottom = (5, 10) if compacto else (8, 12)
        col = 2 if ph < 420 else 1
        rows = ceil(2/col)
        buttons_y = y+ph-bottom-rows*bh-(rows-1)*gap
        nav_y = y+(43 if ph < 500 else 53)
        nav_h = 36 if ph < 500 else 44
        topo = y+(87 if ph < 500 else 108)
        assert nav_y+nav_h <= topo
        for n in range(1,5):
            por = 2 if n>1 and ph>=710 else 1
            for page in range(ceil(n/por)):
                q=min(por,n-page*por)
                avail=buttons_y-14-topo
                gh=(avail-12*(q-1))/q
                start=topo
                if q==1:
                    gh=min(355,gh)
                    start+=max(0,(avail-gh)*.30)
                assert gh>0 and start+q*gh+(q-1)*12<=buttons_y-14+1e-6
                escala=min(1,gh/224)
                # Contadores e divisores cabem na área da carta.
                assert 191*escala < gh
                assert pw-28-32>0
                casos+=1
        # Apuração dos pólens: cabeçalho, três zonas e rodapé.
        margem=max(8,min(24,w*.035))
        ph2=h-2*margem
        compact2=h<550
        top2=12+(23 if compact2 else 33)+(43 if compact2 else 77)
        footer=69 if compact2 else 112
        rh=(ph2-footer-top2-12)/3
        assert rh>=(25 if compact2 else 53)+12
        assert top2+3*rh+8 <= ph2-footer

s=(Path(__file__).resolve().parents[1]/'scripts/jogo/jardim.gd').read_text()
assert 'var limite: float = 860.0 if estado_tela' in s
assert 'roundi(37.0 * escala)' in s
assert 'normal_font_size", 17 if compacto else 22' in s
assert 'grupos_total += quantidade + 2 * floori(float(quantidade) / 3.0)' in s
assert 'botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART' in s
print(f'OK: {casos} configurações de placar/paginação e 63 geometrias da apuração final; verificações estáticas.')
