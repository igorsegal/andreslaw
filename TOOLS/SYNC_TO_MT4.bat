@echo off
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync_to_mt4.ps1"
exit /b %ERRORLEVEL%
