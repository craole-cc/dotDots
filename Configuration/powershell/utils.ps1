# -------------------------------
# 1) Ensure PSGallery is registered and trusted
# -------------------------------
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

# -------------------------------
# 2) Create and prepend custom module path
# -------------------------------
function Set-ModuleLocation {
  param([ValidateNotNullOrEmpty()][string]$DriveLetter)

  $letter = $DriveLetter.TrimEnd(':')
  $modulePath = "$letter`:\PowerShell\Modules"

  if (-not (Test-Path $modulePath)) {
    Write-Debug "Creating module directory: $modulePath"
    New-Item -ItemType Directory -Path $modulePath -Force | Out-Null
  }

  # Only add to PSModulePath if not already present
  if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$($env:PSModulePath)"
    Write-Debug "Updated PSModulePath to include: $modulePath"
  }
}

# -------------------------------
# 3) Enhanced module installation function
# -------------------------------
function Install-ModuleIfMissing {
  param(
    [Parameter(Mandatory)][string]$Name,
    [string]$MinimumVersion = '',
    [ValidateSet('CurrentUser', 'AllUsers')][string]$Scope = 'CurrentUser',
    [string]$AlternativeName = ''
  )

  # Check if module is already available
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

  # Try to install the primary module name
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

    Write-Debug "Importing '$Name'..."
    if ($MinimumVersion) {
      Import-Module -Name $Name -MinimumVersion $MinimumVersion -Force -WarningAction SilentlyContinue
    }
    else {
      Import-Module -Name $Name -Force -WarningAction SilentlyContinue
    }
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

# -------------------------------
# 4) Main execution
# -------------------------------
try {
  # Set up custom module path
  Set-ModuleLocation -DriveLetter $Env:SystemDrive

  # Install PSScriptAnalyzer (this should work fine)
  Install-ModuleIfMissing -Name 'PSScriptAnalyzer' -MinimumVersion '1.21.0' -Scope CurrentUser

  # For PowerShell Editor Services, try the correct module name
  # Note: PowerShellEditorServices might not be the right module name
  # The actual VS Code PowerShell extension uses a different approach
  Write-Debug 'Checking for PowerShell Editor Services...'

  # Try common alternatives for editor services
  $editorServiceModules = @(
    'PowerShellEditorServices',
    'Microsoft.PowerShell.EditorServices',
    'EditorServicesCommandSuite'
  )

  $editorServiceInstalled = $false
  foreach ($moduleName in $editorServiceModules) {
    try {
      if (Get-Module -ListAvailable -Name $moduleName -ErrorAction SilentlyContinue) {
        Write-Debug "Found existing module: $moduleName"
        Import-Module -Name $moduleName -Force -WarningAction SilentlyContinue
        $editorServiceInstalled = $true
        break
      }
    }
    catch {
      continue
    }
  }

  if (-not $editorServiceInstalled -and ($VerbosePreference -eq 'Continue' -or $DebugPreference -eq 'Continue')) {
    Write-Host 'PowerShell Editor Services modules not found in PSGallery.' -ForegroundColor Yellow
    Write-Host 'These are typically installed automatically by VS Code PowerShell extension.' -ForegroundColor Cyan
    Write-Host "If you're using VS Code, ensure the PowerShell extension is installed and up to date." -ForegroundColor Cyan
  }

  Write-Debug 'Module setup completed successfully!'
}
catch {
  Write-Error "Error during module setup: $($_.Exception.Message)"
  Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
