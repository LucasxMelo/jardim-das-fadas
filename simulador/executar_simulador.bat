@echo off
cd /d "%~dp0.."
where py >nul 2>nul
if %errorlevel%==0 (
    py -3 simulador\simular.py --partidas 180 --jogadores 2 3 4 --bonus 0 1 --processos 4
) else (
    python simulador\simular.py --partidas 180 --jogadores 2 3 4 --bonus 0 1 --processos 4
)
if errorlevel 1 echo Falha na simulacao. Verifique se Python 3.10 ou superior esta instalado.
pause
