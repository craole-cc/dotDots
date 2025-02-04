@echo off

@REM @REM ### Force Elevated Prompt
@REM @pushd %~dp0 & fltmc | find "." && (
@REM   Powershell Start-Process '%~f0' ^
@REM   ' %*' ^
@REM   -verb runas 2>nul && exit /b
@REM )

pwsh-preview ^
  -NoProfile ^
  -WindowStyle Hidden ^
  -NonInteractive ^
  -ExecutionPolicy Bypass ^
  -NoExit ^
  -File ""%~dp0\pshrc.ps1""

@REM @REM "%PROGRAMFILES%"\PowerShell\7-preview\pwsh.exe ^
  @REM -NoProfile ^
  @REM -NonInteractive ^
  @REM -ExecutionPolicy Bypass ^
  @REM -NoExit ^
  @REM -NoLogo ^
  @REM -File ""%~dp0\pshrc.ps1""
  @REM -Command "Invoke-Expression 'Import-Module ''%~dp0\pshrc.ps1'''"