#!/usr/bin/env python3
"""Comparação experimental: fórmulas preservadas e rastreamento dos pólens florais."""
import argparse,json,time,hashlib
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path
from simular import Game, SOURCE, ROOT, seat_profiles, aggregate, write_csv
FLOR={5:4,11:4,15:5,17:5,19:4,23:4,13:7,14:6,21:6,24:6,25:8,26:8,28:8,29:7,30:8}
FADA={10:3,14:3,25:3,26:5,27:4,41:5,42:5,43:5,44:4,45:6,46:5,47:7,48:3,49:6}
FADA_FOCAL={14:3,25:4,26:5,27:4,45:7,48:4}
# Controle histórico v205, anterior à adoção oficial da candidata focal.
# A simulação padrão (simular.py) usa o catálogo oficial atual.
FLOR_CONTROLE={14:5,25:6,26:6}
FADA_CONTROLE={14:4,25:5,26:7,27:6,45:8,48:5}
def pontos_controle(c):
    return (FADA_CONTROLE if c.category=='fada' else FLOR_CONTROLE).get(c.kind,c.points)
TABLES=('controle','compensacao','seletiva','moderada','focal')
class Calibration(Game):
    def __init__(self,n,seed,scenario,profiles,limit):
        self.scenario=scenario;super().__init__(n,seed,0,profiles,limit)
    def points(self,c):
        base=pontos_controle(c)
        if self.scenario=='controle':return base
        if self.scenario=='compensacao':return base+(c.category!='fada')
        if self.scenario=='focal':
            return FADA_FOCAL.get(c.kind,base) if c.category=='fada' else base+int(c.kind in (14,25,26))
        if c.category=='fada':return FADA.get(c.kind,base)
        if self.scenario=='moderada':return max(base, FLOR[c.kind]-1)
        return FLOR[c.kind]
def run(job):
    n,seed,s,ps,lim=job;p,g,m=Calibration(n,seed,s,ps,lim).run();meta=dict(jogadores=n,semente=seed,cenario=s,amostra_jogadas=lim)
    return [meta|r for r in p],[meta|r|{'jogador':r['jogador']+1} for r in g],meta|m
def main():
    a=argparse.ArgumentParser();a.add_argument('--partidas',type=int,default=36);a.add_argument('--semente',type=int,default=205101);a.add_argument('--amostra-jogadas',type=int,default=36);a.add_argument('--processos',type=int,default=4);a.add_argument('--cenarios',nargs='+',choices=TABLES,default=list(TABLES));a.add_argument('--saida',type=Path,default=ROOT/'simulador/resultados_v205');args=a.parse_args()
    jobs=[(n,args.semente+100000*n+j,s,seat_profiles(n,j),args.amostra_jogadas) for n in (2,3,4) for j in range(args.partidas) for s in args.cenarios]
    p,g,m=[],[],[];t=time.monotonic();args.saida.mkdir(parents=True,exist_ok=True)
    with ProcessPoolExecutor(max_workers=args.processos) as pool:
        for i,(pp,gg,mm) in enumerate(pool.map(run,jobs),1):
            p+=pp;g+=gg;m.append(mm)
            if i%max(1,len(jobs)//12)==0:print(f'{i}/{len(jobs)}',flush=True)
    s,pr,ob=aggregate(p,m,g)
    for name,rs in [('partidas',m),('jogadores',p),('objetivos',g),('resumo',s),('perfis',pr),('frequencia_objetivos',ob)]:write_csv(args.saida/(name+'.csv'),rs)
    (args.saida/'metadados.json').write_text(json.dumps({'versao':'v205','sha256_gdscript':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'parametros':vars(args)|{'saida':str(args.saida)},'total_partidas':len(m),'segundos':round(time.monotonic()-t,2),'florais_seletiva':FLOR,'fadas_seletiva':FADA,'fadas_focal':FADA_FOCAL,'atribuicao':'FIFO por flor; estrelas marginais no momento da coleta; origem marcada por objetivo','limites':'agentes heurísticos, amostragem de candidatos, sem execução Godot'},ensure_ascii=False,indent=2),encoding='utf8')
if __name__=='__main__':main()
