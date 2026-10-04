@echo off
chcp 65001 >nul
setlocal
set "SCRIPT=%~dp0andreslaw_observer.py"

where py >nul 2>nul
if %ERRORLEVEL%==0 (
    py -3 "%SCRIPT%" fast-start
    exit /b %ERRORLEVEL%
)

where python >nul 2>nul
if %ERRORLEVEL%==0 (
    python "%SCRIPT%" fast-start
    exit /b %ERRORLEVEL%
)

echo ERROR: Python 3 not found in PATH.
exit /b 2
