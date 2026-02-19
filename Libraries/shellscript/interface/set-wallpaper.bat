:: This needs to be in the same directory as setwallaper.ps1 (on system PATH ideally)

:: & set-wallpaper.bat (& .\wallheaven.exe -t)

@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0set-wallpaper.ps1" -path %1
