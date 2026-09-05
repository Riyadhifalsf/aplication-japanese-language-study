@echo off
REM Fast push helper for the Japanese Study repo.
REM Usage: tool\git_push.bat "commit message"
setlocal

if "%~1"=="" (
  echo Usage: tool\git_push.bat "commit message"
  exit /b 1
)

git add -A
if errorlevel 1 exit /b 1
git commit -m "%~1"
if errorlevel 1 exit /b 0
git push origin master
if errorlevel 1 exit /b 1
echo Done.
endlocal