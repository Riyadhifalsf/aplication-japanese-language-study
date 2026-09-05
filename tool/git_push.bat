@echo off
REM Cross-platform repo push helper (works on any OS via Python).
REM Usage: tool\git_push.bat "commit message"
python "%~dp0deploy.py" push %*
exit /b %errorlevel%