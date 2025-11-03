<#
.SYNOPSIS
    Installs Neovim if not present and sets up the configuration
    by linking your dotfiles to the expected config location.

.DESCRIPTION
    This script defines a centralized config initializer function and three primary global functions:
      - Get-NeovimConfig: Returns all config variables as a hashtable.
      - Install-Neovim: Installs the neovim CLI if necessary.
      - Set-Neovim: Symlinks the dotfiles config to the expected user config location.
      - Initialize-Neovim: Orchestrates installation and config setup.

    Calls Initialize-Neovim on script load.

.NOTES
    Designed with configurable central settings for easy adaptation.
    Handles cross-platform paths (Windows: $ENV:USERPROFILE\AppData\Local\nvim | Unix: ~/.config/nvim)
#>

function Global:Get-NeovimConfig {
  <#
    .SYNOPSIS
        Returns structured config variables for the neovim tool.
    #>
  [CmdletBinding()]
  param()

  $cmd = 'nvim'
  $name = 'neovim'

  # Determine config paths based on platform
  $dotsConfigPath = Join-Path $env:DOTS 'Configuration' $name

  if ($IsWindows -or $env:OS -match 'Windows') {
    $userConfigPath = Join-Path $env:LOCALAPPDATA $cmd
  }
  else {
    # Unix-like systems (Linux, macOS)
    $configDir = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
    $userConfigPath = Join-Path $configDir $cmd
  }

  return @{
    cmd       = $cmd
    name      = $name
    desc      = "$cmd ($name)"
    conf      = @{
      dots = $dotsConfigPath
      user = $userConfigPath
    }
    # scoopPkg  = $name
    scoopPkg  = 'neovim-nightly'
    # wingetPkg = 'Neovim.Neovim'
    wingetPkg = 'Neovim.Neovim.Nightly'
    envBase   = 'NVIM_CONFIG'
  }
}

function Global:Install-Neovim {
  <#
    .SYNOPSIS
        Installs neovim if not already present.

    .OUTPUTS
        [bool] Success status.
    #>
  [CmdletBinding()]
  param()

  $app = Get-NeovimConfig

  #~@ Check if command exists via custom lookup
  if (Get-Command -Name $app.cmd -ErrorAction SilentlyContinue) {
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
  if (-not (Get-Command -Name $app.cmd -ErrorAction SilentlyContinue)) {
    Write-Pretty -Tag 'Error' "$($app.desc) still not available after installation."
    return $false
  }

  #~@ Installation successful
  Write-Pretty -Tag 'Success' "$($app.desc) installed successfully."
  return $true
}

function Global:Set-Neovim {
  <#
    .SYNOPSIS
        Symlinks the dotfiles config directory to neovim's user config path.

    .OUTPUTS
        [bool] Success status.
    #>
  [CmdletBinding()]
  param()

  $app = Get-NeovimConfig

  #~@ Compose needed paths
  $dotConfigPath = $app.conf.dots
  $userConfigPath = $app.conf.user
  $userConfigDir = Split-Path -Path $userConfigPath -Parent

  #~@ Export environment variables for session and global scope
  $envVars = @{
    $app.envBase             = $dotConfigPath
    ("$($app.envBase)_LINK") = $userConfigPath
  }
  foreach ($key in $envVars.Keys) {
    if (Test-Path -Path $envVars[$key] -PathType Container) {
      [Environment]::SetEnvironmentVariable($key, $envVars[$key], 'Process')
      Set-Variable -Name $key -Value $envVars[$key] -Scope Global
      Write-Pretty -DebugEnv $key $($envVars[$key])
    }
  }

  #~@ Verify dotfiles config exists
  if (-not (Test-Path -Path $dotConfigPath)) {
    Write-Pretty -Tag 'Error' "Dotfiles config not found at $dotConfigPath"
    return $false
  }

  #~@ Create parent config directory if missing
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
      #~@ Existing real directory: rename to backup with timestamp
      Write-Pretty -Tag 'Info' 'Existing config found and is not a symlink. Renaming to backup.'
      $backupName = "nvim.bak_$(Get-Date -Format 'yyyyMMddHHmmss')"
      $backupPath = Join-Path $userConfigDir $backupName
      Rename-Item -Path $userConfigPath -NewName $backupPath
    }
  }

  #~@ Create symlink from user config path to dotfiles config path
  try {
    Write-Pretty -Tag 'Info' "Creating symlink from $dotConfigPath to $userConfigPath"
    New-Item -Path $userConfigPath -ItemType SymbolicLink -Value $dotConfigPath -Force | Out-Null
  }
  catch {
    Write-Pretty -Tag 'Error' "Failed to create symlink: $_"
    Write-Pretty -Tag 'Suggestion' 'Run PowerShell as admin or enable developer mode for symlink permissions, or fallback to copying config.'
    return $false
  }

  Write-Pretty -Tag 'Success' 'Config successfully linked and environment variables set.'
  return $true
}

function Global:Initialize-Neovim {
  <#
    .SYNOPSIS
        Initializes the Neovim environment.

    .DESCRIPTION
        Installs neovim if needed and links configuration.
    #>

  [CmdletBinding()]
  param()

  try {
    #~@ Retrieve config
    $time = Get-Date
    $app = Get-NeovimConfig

    #~@ Install if missing
    if (-not (Get-Command -Name $app.cmd -ErrorAction SilentlyContinue)) {
      if (-not (Install-Neovim)) {
        Write-Pretty -Tag 'Error' "Failed to install $($app.desc), aborting."
        return
      }
    }

    #~@ Link config
    if (-not (Set-Neovim)) {
      Write-Pretty -Tag 'Error' 'Unable to set configuration.'
      return
    }

    #~@ Return success message with timing
    Write-Pretty -Tag 'Info' -NoNewLine -As $($app.desc) -Init $time
  }
  catch {
    #~@ Return failure message with exception details
    Write-Pretty -Tag 'Error' "Failed to initialize $($app.desc)" "$($_.Exception.Message)"
  }
}

#~@ Auto-initialize on script load
Initialize-Neovim
