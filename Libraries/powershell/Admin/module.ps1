<#
.SYNOPSIS
    Helper functions for module and environment management.

.DESCRIPTION
    Contains functions to set module location and install modules conditionally.

.NOTES
    Place in Bin\powershell\Admin\module.ps1
#>

function Global:Set-ModuleLocation {
  param([ValidateNotNullOrEmpty()][string]$DriveLetter)

  $letter = $DriveLetter.TrimEnd(':')
  $modulePath = "$letter`:\PowerShell\Modules"

  if (-not (Test-Path $modulePath)) {
    Write-Debug "Creating module directory: $modulePath"
    New-Item -ItemType Directory -Path $modulePath -Force | Out-Null
  }

  # Add to PSModulePath if not already present
  if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$($env:PSModulePath)"
    Write-Debug "Updated PSModulePath to include: $modulePath"
  }
}

function Global:Get-PSModulePaths {
  <#
    .SYNOPSIS
        Lists each path from the PSModulePath environment variable on its own line.

    .DESCRIPTION
        Splits the PSModulePath string by path separator ';' and outputs each path.

    .OUTPUTS
        [string[]] Array of individual PSModulePath strings.

    .EXAMPLE
        Get-PSModulePaths
    #>
  param ()

  $cmd = (Get-ChildItem Env:PSModulePath).Value -split ';'
  $cmd = Get-Env -Name PSModulePath -SplitValue

  $cmd
}

function Global:Install-ModuleIfMissing {
  param(
    [Parameter(Mandatory)][string]$Name,
    [string]$MinimumVersion = '',
    [ValidateSet('CurrentUser', 'AllUsers')][string]$Scope = 'CurrentUser',
    [string]$AlternativeName = ''
  )

  $existingModule = Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue
  if ($existingModule) {
    if ($MinimumVersion -and $existingModule.Version -lt [version]$MinimumVersion) {
      if ($VerbosePreference -eq 'Continue' -or $DebugPreference -eq 'Continue') {
        Write-Host "Updating '$Name' to minimum version $MinimumVersion..." -ForegroundColor Yellow
      }
    }
    else {
      Write-Debug "Module '$Name' already available (Version: $($existingModule.Version))"
      Import-Module -Name $Name -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
      return
    }
  }

  $installParams = @{
    Name         = $Name
    Scope        = $Scope
    Force        = $true
    AllowClobber = $true
    ErrorAction  = 'Stop'
  }
  if ($MinimumVersion) {
    $installParams.MinimumVersion = $MinimumVersion
  }

  try {
    if ($VerbosePreference -eq 'Continue' -or $DebugPreference -eq 'Continue') {
      Write-Host "Installing '$Name'..." -ForegroundColor Yellow
    }
    Install-Module @installParams
    Import-Module -Name $Name -Force -WarningAction SilentlyContinue
  }
  catch {
    if ($AlternativeName) {
      if ($VerbosePreference -eq 'Continue' -or $DebugPreference -eq 'Continue') {
        Write-Host "Failed to install '$Name'. Trying alternative '$AlternativeName'..." -ForegroundColor Yellow
      }
      try {
        $installParams.Name = $AlternativeName
        Install-Module @installParams
        Import-Module -Name $AlternativeName -Force -WarningAction SilentlyContinue
      }
      catch {
        Write-Error "Failed to install both '$Name' and '$AlternativeName': $($_.Exception.Message)"
      }
    }
    else {
      Write-Error "Failed to install '$Name': $($_.Exception.Message)"
    }
  }
}
