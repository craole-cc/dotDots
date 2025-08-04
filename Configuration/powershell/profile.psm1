function Import-ProfileScript {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$ScriptName,

    [string]$Description = $ScriptName
  )

  $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $ScriptName

  if (Test-Path $scriptPath) {
    Write-Debug "Loading '$Description' from: $scriptPath"
    try {
      . $scriptPath
      Write-Debug "Successfully loaded '$Description'"
    }
    catch {
      Write-Error "Failed to load '$Description': $($_.Exception.Message)"
    }
  }
  else {
    Write-Debug "Script '$Description' not found at: $scriptPath"
  }
}

function Test-IsVSCode {
  return $env:VSCODE_PID -or
  ($env:TERM_PROGRAM -eq 'vscode') -or
  ($env:VSCODE_INJECTION -eq '1')
}

# Export the function for module usage
Export-ModuleMember -Function Import-ProfileScript

# Import profile components
@(
  @{Name = 'utils.ps1'; Description = 'utilities' },
  @{Name = 'config.ps1'; Description = 'configuration' }
  # @{Name = 'Get-Wallpaper.ps1'; Description = 'wallpaper' },
  # @{Name = 'coreutils.ps1'; Description = 'coreutils' }
) | ForEach-Object {
  Import-ProfileScript -ScriptName $_.Name -Description $_.Description
}

# Change directory logic
if (-not (Test-IsVSCode)) {
  if ($env:DOTS -and (Test-Path $env:DOTS)) {
    Set-Location $env:DOTS
    Write-Debug "Changed directory to: $env:DOTS"
  }
  else {
    Write-Warning "DOTS environment variable not set or path does not exist: $env:DOTS"
  }
}
else {
  Write-Debug 'VSCode detected - staying in current workspace directory'
}

#TODO: This should be Invoke-Coreutils which should install the GNU Coreutils and unregister the default powershel aliases
Unregister-CoreutilsAliases
Register-Wallpaper
