# $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')

function Global:Get-EnvPath {
  param (
    [Parameter(HelpMessage = 'Scope to search for environment variables')]
    [ValidateSet('Process', 'User', 'Machine', 'All')]
    [string]$Scope = 'Process',

    [Parameter(HelpMessage = 'Split the returned string value on semicolons into multiple elements')]
    [switch]$Print
  )

  if ($Print) { Get-Env -Name Path -Scope $Scope }
  else { Get-Env -Name Path -Scope $Scope -SplitValue }
}
