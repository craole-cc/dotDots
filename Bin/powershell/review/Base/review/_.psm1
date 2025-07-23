#region Modules
#~@ Load all component scripts with error handling
$scriptFiles = @(
  'command.ps1',
  'context.ps1',
  'filesystem.ps1',
  'time.ps1',
  'verbosity.ps1',
  'types.ps1'
)

foreach ($scriptFile in $scriptFiles) {
  $scriptPath = Join-Path $PSScriptRoot $scriptFile
  if (Test-Path $scriptPath) {
    try {
      . $scriptPath
      Write-Verbose "Initialized script: $scriptFile"
    }
    catch {
      Write-Error "Failed to load $scriptFile`: $_"
    }
  }
  else {
    Write-Warning "Script file not found: $scriptPath"
  }
}
#endregion

#region Exports
Export-ModuleMember -Function * -Alias *
#endregion

#region Testing
#~@ Uncomment these lines to run tests when module loads
# Test-GetContext
# Test-WritePretty
# Test-InvokeProcess
#endregion


Write-Host "Hello from $($PSScriptRoot)"
