@echo off
setlocal
cd /d "%~dp0"
python "%~dp0Make_Achievement_CSV.py"
set "taskExit=%errorlevel%"
echo.
echo Result code: %taskExit%. Upload only the generated CSVs after PASS.
pause
exit /b %taskExit%
