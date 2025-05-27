#region Module Loading
#@ Load all component scripts with error handling
$scriptFiles = @(
  'command.ps1',
  'context.ps1',
  'filesystem.ps1',
  'verbosity.ps1',
  'write.ps1'
)

foreach ($scriptFile in $scriptFiles) {
  $scriptPath = Join-Path $PSScriptRoot $scriptFile
  if (Test-Path $scriptPath) {
    try {
      . $scriptPath
      Write-Verbose "Successfully loaded: $scriptFile"
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

#region Consolidated Exports
#@ Export all functions from all modules
Export-ModuleMember -Function @(
  # From command.ps1
  'Invoke-Process',
  'Test-InvokeProcess',

  # From context.ps1
  'Get-Context',
  'Test-GetContext',

  # From filesystem.ps1
  'Format-PathPOSIX',
  'Resolve-PathPOSIX',

  # From verbosity.ps1
  'Get-VerbosityDefault',
  'Get-VerbosityLevel',
  'Get-VerbosityNumeric',
  'Get-VerbosityColor',
  'Get-VerbosityTag',
  'Get-Verbosity',
  'Set-Verbosity',
  'Test-Verbosity',
  'Get-VerbosityAllAliases',
  'Get-VerbosityAliasesFor',
  'Format-VerbosityMessage',
  'Write-VerbosityMessage',
  'Compare-VerbosityLevel',
  'Test-VerbosityLevelMeetsThreshold',

  # From write.ps1
  'Write-Pretty',
  'Test-WritePretty'
)

#@ Export aliases
Export-ModuleMember -Alias @(
  'posix',
  'resolve-posix',
  'pout'
)
#endregion

#region Optional Testing
#@ Uncomment these lines to run tests when module loads
# Test-GetContext
# Test-WritePretty
# Test-InvokeProcess
#endregion
