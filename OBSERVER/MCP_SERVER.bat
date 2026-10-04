@echo off
chcp 65001 >nul
setlocal
set "SCRIPT=%~dp0mcp_server.py"

where py >nul 2>nul
if %ERRORLEVEL%==0 (
    py -3 "%SCRIPT%"
    exit /b %ERRORLEVEL%
)

where python >nul 2>nul
if %ERRORLEVEL%==0 (
    python "%SCRIPT%"
    exit /b %ERRORLEVEL%
)

echo ERROR: Python 3 not found in PATH. 1>&2
exit /b 2
