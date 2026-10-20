@echo off
setlocal
cd /d "%~dp0"
python "%~dp0Upload.py"
set "taskExit=%errorlevel%"
echo.
echo Result code: %taskExit%. See Evidence\upload-result.txt when created.
pause
exit /b %taskExit%
