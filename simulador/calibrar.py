#!/usr/bin/env python3
"""Teste de tabelas por modelo, sem modificar o catálogo oficial.
Os números são estrelas; as fórmulas atuais ficam no controle. As variantes
seletivas imprimem um valor fixo por objetivo, igual para 2–4 participantes.
HISTÓRICO v203: não usar para decisões atuais; v205 usa calibrar_v205.py.
"""
import argparse, hashlib, json, time
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path
from simular import Game, SOURCE, ROOT, seat_profiles, aggregate, write_csv
from calibrar_v205 import pontos_controle
# Tabelas pré-especificadas após a triagem de 432 partidas (semente distinta).
FLOR={5:3,11:3,15:4,17:4,19:3,23:3,13:6,14:6,21:5,24:5,25:7,26:7,28:7,29:6,30:7}
FADA={10:3,14:3,25:3,26:5,27:5,41:5,42:5,43:5,44:5,45:7,46:7,47:8,48:3,49:7,61:6,64:3,65:3,66:5,67:7,69:4,70:7}
TABLES=('atual','menos_1','seletiva','seletiva_flor_menos_1','seletiva_fada_mais_1')
class Calibration(Game):
    def __init__(self,n,seed,scenario,profiles,limit):
        self.scenario=scenario
        super().__init__(n,seed,0,profiles,limit)
    def points(self,c):
        s=self.scenario
        if s=='atual':return pontos_controle(c)
        if s=='menos_1':return max(1,pontos_controle(c)-1)
        p=(FADA if c.category=='fada' else FLOR)[c.kind]
        if s=='seletiva_flor_menos_1' and c.category!='fada':p=max(1,p-1)
        if s=='seletiva_fada_mais_1' and c.category=='fada':p+=1
        return p

def run(job):
    n,seed,s,ps,lim=job
    p,g,m=Calibration(n,seed,s,ps,lim).run()
    meta=dict(jogadores=n,semente=seed,cenario=s,amostra_jogadas=lim)
    return [meta|r for r in p],[meta|r|{'jogador':r['jogador']+1} for r in g],meta|m

def main():
    a=argparse.ArgumentParser();a.add_argument('--partidas',type=int,default=108);a.add_argument('--semente',type=int,default=203101);a.add_argument('--amostra-jogadas',type=int,default=36);a.add_argument('--processos',type=int,default=4);a.add_argument('--cenarios',nargs='+',choices=TABLES,default=list(TABLES));a.add_argument('--saida',type=Path,default=ROOT/'simulador'/'resultados_v203_calibracao');args=a.parse_args()
    jobs=[(n,args.semente+100000*n+j,s,seat_profiles(n,j),args.amostra_jogadas) for n in (2,3,4) for j in range(args.partidas) for s in args.cenarios]
    p,g,m=[],[],[];t=time.monotonic();args.saida.mkdir(parents=True,exist_ok=True)
    with ProcessPoolExecutor(max_workers=args.processos) as pool:
        for i,(pp,gg,mm) in enumerate(pool.map(run,jobs),1):
            p+=pp;g+=gg;m.append(mm)
            if i%max(1,len(jobs)//12)==0 or i==len(jobs):print(f'{i}/{len(jobs)}',flush=True)
    s,pr,ob=aggregate(p,m,g)
    for name,rs in [('partidas',m),('jogadores',p),('objetivos',g),('resumo',s),('perfis',pr),('frequencia_objetivos',ob)]:write_csv(args.saida/(name+'.csv'),rs)
    (args.saida/'metadados.json').write_text(json.dumps({'versao':'v203','sha256_gdscript':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'parametros':vars(args)|{'saida':str(args.saida)},'total_partidas':len(m),'segundos':round(time.monotonic()-t,2),'floral_seletiva':FLOR,'fada_seletiva':FADA,'limites':'agentes heurísticos independentes; não teste humano nem execução Godot'},ensure_ascii=False,indent=2),encoding='utf8')
if __name__=='__main__':main()
