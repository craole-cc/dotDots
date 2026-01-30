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
  Write-Debug 'Registering PSGallery repository...'
  Register-PSRepository -Name PSGallery -SourceLocation 'https://www.powershellgallery.com/api/v2' -InstallationPolicy Trusted
}
elseif ($psGallery.InstallationPolicy -ne 'Trusted') {
  Write-Debug 'Setting PSGallery as trusted...'
  Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}
