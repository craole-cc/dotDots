<#
.SYNOPSIS
    System and PowerShell update utility.

.DESCRIPTION
    Updates PowerShell (using winget on Windows, for preview version) and Windows updates.
    Skips updates on non-Windows OSes for now.

.NOTES
    Place in $DOTS/Bin/powershell/Admin/updates.ps1
#>

function Global:Install-Updates {
  [CmdletBinding()]
  param()

  Write-Host 'Starting update process...' -ForegroundColor Cyan

  $platform = $PSVersionTable.PSPlatform

  if ($IsWindows) {
    Write-Host 'Detected Windows.' -ForegroundColor Green

    # Update PowerShell preview via winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
      Write-Host 'Updating PowerShell Preview using winget...' -ForegroundColor Yellow
      try {
        winget upgrade --id Microsoft.PowerShell.Preview --accept-package-agreements --accept-source-agreements --silent
      }
      catch {
        Write-Warning "winget upgrade failed: $_"
      }
    }
    else {
      Write-Warning 'winget not found; skipping PowerShell update.'
    }

    # Update Windows OS using PSWindowsUpdate
    try {
      Install-ModuleIfMissing -Name 'PSWindowsUpdate' -Scope CurrentUser
      Import-Module PSWindowsUpdate
      Write-Host 'Installing Windows updates...' -ForegroundColor Yellow
      Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -IgnoreReboot
    }
    catch {
      Write-Warning "Windows update failed or PSWindowsUpdate not available: $_"
    }
  }
  elseif ($platform -eq 'Linux' -or $platform -eq 'MacOS') {
    Write-Host "Non-Windows platform detected ($platform). Skipping Windows and PowerShell updates." -ForegroundColor Yellow
    Write-Host 'Update PowerShell manually using your system package manager.' -ForegroundColor Yellow
  }
  else {
    Write-Warning 'Unknown platform; skipping updates.'
  }
}
