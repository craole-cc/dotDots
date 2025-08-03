# PowerShell Profile Loader - Simplified and Refactored

function Import-ProfileScript {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$ScriptName,

    [string]$Description = $ScriptName
  )

  $scriptPath = Join-Path $PSScriptRoot $ScriptName

  if (Test-Path $scriptPath) {
    Write-Debug "Loading $Description from: $scriptPath"
    try {
      . $scriptPath
      Write-Debug "Successfully loaded $Description"
    }
    catch {
      Write-Error "Failed to load $Description`: $($_.Exception.Message)"
    }
  }
  else {
    Write-Debug "$Description not found at: $scriptPath"
  }
}

# Make available used as a module
Export-ModuleMember -Function Import-ProfileScript

# Load profile components in order
Import-ProfileScript -ScriptName 'utils.ps1' -Description 'utilities'
Import-ProfileScript -ScriptName 'config.ps1' -Description 'configuration'
