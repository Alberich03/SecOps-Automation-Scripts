@echo off
setlocal
REM Launcher yang memanggil PowerShell dengan bypass policy
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0nuclei_scan.ps1"
