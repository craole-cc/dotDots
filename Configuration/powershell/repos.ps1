<#
.SYNOPSIS
    PowerShell environment configuration.

.DESCRIPTION
    Configures PSGallery repository trust.

.NOTES
    Place in Configuration\powershell\setup.ps1
#>

# Ensure PSGallery is registered and trusted
$psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
if (-not $psGallery) {
  if ($VerbosePreference -eq 'Continue' -or $DebugPreference -eq 'Continue') {
    Write-Host 'Registering PSGallery repository...' -ForegroundColor Yellow
  }
  Register-PSRepository -Name PSGallery -SourceLocation 'https://www.powershellgallery.com/api/v2' -InstallationPolicy Trusted
}
elseif ($psGallery.InstallationPolicy -ne 'Trusted') {
  if ($VerbosePreference -eq 'Continue' -or $DebugPreference -eq 'Continue') {
    Write-Host 'Setting PSGallery as trusted...' -ForegroundColor Yellow
  }
  Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}
