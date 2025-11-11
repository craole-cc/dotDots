<#
.SYNOPSIS
    Installs the Mise environment manager if not present,
    sets up the configuration by linking your dotfiles,
    and initializes the environment.

.DESCRIPTION
    This script defines a centralized config initializer function and three primary global functions:
      - Get-MiseConfig: Returns all config variables as a hashtable.
      - Install-Mise: Installs the mise CLI if necessary.
      - Set-Mise: Symlinks the dotfiles config to the expected user config location.
      - Initialize-Mise: Orchestrates installation and config setup.

    Calls Initialize-Mise on script load.

.NOTES
    Designed with configurable central settings for easy adaptation.
#>

function Global:Get-MiseConfig {
  <#
    .SYNOPSIS
        Returns structured config variables for the mise tool.
    #>
  [CmdletBinding()]
  param()

  $cmd = 'mise'
  $name = 'mise-en-place'
  $pkg = @{
    scoop  = 'mise'
    winget = 'jdx.mise'
  }
  $conf = 'config.toml'

  return @{
    cmd  = $cmd
    name = $name
    desc = if ($cmd -like $name) { $name } else { "$name ($cmd)" }
    env  = ($cmd.ToUpper() + '_RC')
    pkg  = $pkg
    cfg  = @{
      dots = [IO.Path]::Combine($env:DOTS , 'Configuration', $name, $conf)
      user = [IO.Path]::Combine($env:USERPROFILE , '.config', $cmd, $conf)
    }
  }
}

function Global:Install-Mise {
  <#
    .SYNOPSIS
        Installs mise if not already present.

    .OUTPUTS
        [bool] Success status.
    #>
  [CmdletBinding()]
  param()

  $app = Get-MiseConfig

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
    scoop install $app.pkg.scoop
  }
  elseif (Get-Command -Name 'winget' -ErrorAction SilentlyContinue) {
    Write-Pretty -Tag 'Trace' "Installing $($app.desc) with winget..."
    winget install $app.pkg.winget
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

  #~@ Install dependencies defined in the config
  Write-Pretty -Tag 'Info' 'Running `mise install` to set up tools...'
  mise install --quiet

  if ($LASTEXITCODE -eq 0) {
    Write-Pretty -Tag 'Success' 'mise has been successfully installed and its tools are set up.'
    return $true
  }

  #~@ Installation successful
  Write-Pretty -Tag 'Success' "$($app.desc) installed successfully."
  return $true
}

function Global:Set-Mise {
  <#
    .SYNOPSIS
        Symlinks the dotfiles config file to mise's user config path.

    .OUTPUTS
        [bool] Success status.
    #>
  [CmdletBinding()]
  param()

  $app = Get-MiseConfig

  #~@ Compose needed paths
  $dotsConfigPath = $app.cfg.dots
  $userConfigPath = $app.cfg.user
  $userConfigDir = Split-Path -Path $userConfigPath -Parent

  #~@ Export environment variables for session and global scope
  $envVars = @{
    $app.env             = $dotsConfigPath
    ("$($app.env)_LINK") = $userConfigPath
  }
  foreach ($key in $envVars.Keys) {
    if (Test-Path -Path $envVars[$key] -PathType Leaf) {
      [Environment]::SetEnvironmentVariable($key, $envVars[$key], 'Process')
      Set-Variable -Name $key -Value $envVars[$key] -Scope Global
      Write-Pretty -DebugEnv $key $($envVars[$key])
    }
  }

  #~@ Verify dotfiles config exists
  if (-not (Test-Path -Path $dotsConfigPath)) {
    Write-Pretty -Tag 'Error' "Dotfiles config not found at $dotsConfigPath"
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
      if ($target -eq $dotsConfigPath) {
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
    Write-Pretty -Tag 'Info' "Creating symlink from $dotsConfigPath to $userConfigPath"
    New-Item -Path $userConfigPath -ItemType SymbolicLink -Value $dotsConfigPath -Force | Out-Null
  }
  catch {
    Write-Pretty -Tag 'Error' "Failed to create symlink: $_"
    Write-Pretty -Tag 'Suggestion' 'Run PowerShell as admin or developer mode for symlink permissions, or fallback to copying config.'
    return $false
  }

  Write-Pretty -Tag 'Success' 'Config successfully linked and environment variables set.'
  return $true
}

function Global:Initialize-Mise {
  <#
    .SYNOPSIS
        Initializes the Mise environment.

    .DESCRIPTION
        Installs mise if needed and links configuration.
    #>


  [CmdletBinding()]
  param()

  try {
    #~@ Retrieve config
    $time = Get-Date
    $app = Get-MiseConfig

    #~@ Install if missing
    if (-not (Get-Command -Name $app.cmd -ErrorAction SilentlyContinue)) {
      if (-not (Install-Mise)) {
        Write-Pretty -Tag 'Error' "Failed to install $($app.desc), aborting."
        return
      }
    }

    #~@ Link config
    if (-not (Set-Mise)) {
      Write-Pretty -Tag 'Error' 'Unable to set configuration.'
      return
    }

    #~@ Activate config
    mise activate pwsh | Out-String | Invoke-Expression
    if ($LASTEXITCODE -ne 0) {
      Write-Pretty -Tag 'Error' 'Failed to activate mise environment based on config.'
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
Initialize-Mise
