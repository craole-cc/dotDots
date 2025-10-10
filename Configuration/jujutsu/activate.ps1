<#
.SYNOPSIS
    Installs the Jujutsu (jj) version control system if not present,
    sets up the configuration by linking your dotfiles,
    and initializes the environment.

.DESCRIPTION
    This script defines a centralized config initializer function and three primary global functions:
      - Get-JujutsuConfig: Returns all config variables as a hashtable.
      - Install-Jujutsu: Installs the jj CLI if necessary.
      - Set-Jujutsu: Symlinks the dotfiles config to user config path.
      - Initialize-Jujutsu: Orchestrates installation and config setup.

    Calls Initialize-Jujutsu on script load.

.NOTES
    Designed with configurable central settings for easy adaptation.
#>

# $timeBegan = Get-Date

function Global:Get-JujutsuConfig {
  <#
    .SYNOPSIS
        Returns structured config variables for the jujutsu tool.
    #>
  [CmdletBinding()]
  param()

  $cmd = 'jj'
  $name = 'jujutsu'
  $cfg = 'config.toml'

  return @{
    cmd       = $cmd
    name      = $name
    desc      = "$cmd ($name)"
    conf      = @{
      dots = Join-Path $env:DOTS 'Configuration' $name $cfg
      user = Join-Path $env:APPDATA $cmd $cfg
    }
    scoopPkg  = 'jj'
    wingetPkg = 'jj-vcs.jj'
    envBase   = ($cmd.ToUpper() + '_CONFIG')
  }
}

function Global:Install-Jujutsu {
  <#
    .SYNOPSIS
        Installs jujutsu (jj) if not already present.

    .OUTPUTS
        [bool] Success status.
    #>
  [CmdletBinding()]
  param()

  $app = Get-JujutsuConfig

  #~@ Check if command exists via custom lookup
  if (Get-CommandFirst -Name $app.cmd -ErrorAction SilentlyContinue) {
    Write-Pretty -Tag 'Trace' "$($app.desc) is already installed."
    return $true
  }

  #~@ Log install attempt
  Write-Pretty -Tag 'Warning' "$($app.desc) not found. Attempting installation..."

  #~@ Try install via scoop or winget
  if (Get-Command -Name 'scoop' -ErrorAction SilentlyContinue) {
    Write-Pretty -Tag 'Trace' "Installing $($app.desc) with scoop..."
    scoop install $app.scoopPkg
  }
  elseif (Get-Command -Name 'winget' -ErrorAction SilentlyContinue) {
    Write-Pretty -Tag 'Trace' "Installing $($app.desc) with winget..."
    winget install $app.wingetPkg
  }
  else {
    Write-Pretty -Tag 'Error' 'No package manager (scoop or winget) found. Please install manually.'
    return $false
  }

  #~@ Verify installation
  if (-not (Get-CommandFirst -Name $app.cmd -ErrorAction SilentlyContinue)) {
    Write-Pretty -Tag 'Error' "$($app.desc) still not available after installation."
    return $false
  }

  #~@ Installation successful
  Write-Pretty -Tag 'Success' "$($app.desc) installed successfully."
  return $true
}

function Global:Set-Jujutsu {
  <#
    .SYNOPSIS
        Symlinks the dotfiles config file to jujutsu's user config path.

    .OUTPUTS
        [bool] Success status.
    #>
  [CmdletBinding()]
  param()

  #~@ Compose needed paths
  $app = Get-JujutsuConfig
  $dotConfigPath = $app.conf.dots
  $userConfigPath = $app.conf.user
  $userConfigDir = Split-Path -Path $userConfigPath -Parent

  #~@ Export environment variables for current session and global scope
  $envVars = @{
    $app.envBase             = $dotConfigPath
    ("$($app.envBase)_LINK") = $userConfigPath
  }
  foreach ($key in $envVars.Keys) {
    if (Test-Path -Path $envVars[$key] -PathType Leaf) {
      [Environment]::SetEnvironmentVariable($key, $envVars[$key], 'Process')
      Set-Variable -Name $key -Value $envVars[$key] -Scope Global
      Write-Verbose "Exported variable: $key => $($envVars[$key])"
    }
  }

  #~@ Verify dotfiles config exists
  if (-not (Test-Path -Path $dotConfigPath)) {
    Write-Pretty -Tag 'Error' "Dotfiles config not found at $dotConfigPath"
    return $false
  }

  #~@ Create user config directory if missing
  if (-not (Test-Path -Path $userConfigDir)) {
    Write-Pretty -Tag 'Trace' "Creating config directory at $userConfigDir"
    New-Item -ItemType Directory -Path $userConfigDir -Force | Out-Null
  }

  #~@ Handle existing config or symlink at user config path
  if (Test-Path -Path $userConfigPath) {
    $existingItem = Get-Item $userConfigPath -Force
    if ($existingItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
      #~@ Existing symlink: check target
      $target = (Get-Item $userConfigPath -Force).Target
      if ($target -eq $dotConfigPath) {
        Write-Pretty -Tag 'Trace' 'Correct symlink already exists.'
        return $true
      }
      else {
        Write-Pretty -Tag 'Info' 'Existing symlink points elsewhere. Removing it.'
        Remove-Item -Path $userConfigPath -Force
      }
    }
    else {
      #~@ Existing real file: rename to backup with timestamp
      Write-Pretty -Tag 'Info' 'Existing config found and is not a symlink. Renaming to backup.'
      Rename-Item -Path $userConfigPath -NewName ("config.toml.bak_$(Get-Date -Format 'yyyyMMddHHmmss')")
    }
  }

  #~@ Create symlink from user config path to dotfiles config path
  try {
    Write-Pretty -Tag 'Info' "Creating symlink from $dotConfigPath to $userConfigPath"
    New-Item -Path $userConfigPath -ItemType SymbolicLink -Value $dotConfigPath -Force | Out-Null
  }
  catch {
    Write-Pretty -Tag 'Error' "Failed to create symlink: $_"
    Write-Pretty -Tag 'Suggestion' 'Run PowerShell as admin or developer mode, or fallback to copying.'
    return $false
  }

  #~@ Success message
  Write-Pretty -Tag 'Success' 'Config successfully linked and environment variables set.'
  return $true
}

function Global:Initialize-Jujutsu {
  <#
    .SYNOPSIS
        Initializes the Jujutsu environment.

    .DESCRIPTION
        Installs jj if needed and links configuration.
    #>
  [CmdletBinding()]
  param()

  $app = Get-JujutsuConfig

  #~@ Install if missing
  if (-not (Get-CommandFirst -Name $app.cmd -ErrorAction SilentlyContinue)) {
    if (-not (Install-Jujutsu)) {
      Write-Pretty -Tag 'Error' "Failed to install $($app.desc), aborting."
      return
    }
  }

  #~@ Link config
  if (-not (Set-Jujutsu)) {
    Write-Pretty -Tag 'Error' "Failed to activate $($app.desc) config."
    return
  }

  Write-Pretty -Tag 'Success' "$($app.desc) environment initialized."
}

#~@ Auto-initialize on script load
Initialize-Jujutsu
