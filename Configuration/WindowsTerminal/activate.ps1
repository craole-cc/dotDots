
if (Test-IsWindowsTerminal) {
  if ($env:DOTS -and (Test-Path $env:DOTS)) {
    Set-Location $env:DOTS
    $msg = "Changed directory to: $env:DOTS"
    Write-Debug "$msg"
  }
  else {
    $msg = "DOTS environment variable not set or path does not exist: $env:DOTS"
    Write-Warning "$msg"
  }
}
else {
  $msg = 'Not in Windows Terminal - skipping directory change'
  Write-Debug "$msg"
}
