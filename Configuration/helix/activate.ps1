<#
.SYNOPSIS
    Installs Helix (hx) if not present,
    sets up the configuration by linking your dotfiles (config.toml and languages.toml),
    and initializes the environment.

.DESCRIPTION
    This script defines a centralized config initializer function and three primary global functions:
      - Get-HelixConfig: Returns all config variables as a hashtable.
      - Install-Helix: Installs the hx CLI if necessary.
      - Set-Helix: Symlinks the dotfiles config files to user config location.
      - Initialize-Helix: Orchestrates installation and config setup.

    Calls Initialize-Helix on script load.

.NOTES
    Designed for easy adaptation to multiple config files per tool.
#>

function Global:Get-HelixConfig {
  <#
    .SYNOPSIS
        Returns structured config variables for the helix tool.
    #>
  [CmdletBinding()]
  param()

  $cmd = 'hx'
  $name = 'helix'
  $cfgFiles = @('config.toml', 'languages.toml')
  $cfgPath = @{
    dots = $cfgFiles | ForEach-Object { Join-Path $env:DOTS 'Configuration' $name $_ }
    user = $cfgFiles | ForEach-Object { Join-Path $env:APPDATA $name $_ }
  }

  return @{
    cmd       = $cmd
    name      = $name
    desc      = "$name ($cmd)"
    cfgFiles  = $cfgFiles
    cfgPath   = $cfgPath
    scoopPkg  = $name
    wingetPkg = 'Helix.Helix'
    envBase   = ($cmd.ToUpper() + '_CONFIG')
  }
}

function Global:Install-Helix {
  <#
    .SYNOPSIS
        Installs helix if not already present.

    .OUTPUTS
        [bool] Success status.
    #>
  [CmdletBinding()]
  param()

  $app = Get-HelixConfig

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

function Global:Set-Helix {
  <#
    .SYNOPSIS
        Symlinks multiple dotfiles config files to helix's user config path.

    .OUTPUTS
        [bool] Success status.
    #>
  [CmdletBinding()]
  param()

  $app = Get-HelixConfig

  #~@ Export environment variables per config file (dots and user paths)
  for ($i = 0; $i -lt $app.cfgFiles.Count; $i++) {
    $dotConfigPath = $app.cfgPath.dots[$i]
    $userConfigPath = $app.cfgPath.user[$i]
    $userConfigDir = Split-Path -Path $userConfigPath -Parent

    $envVarName = $app.envBase + '_' + ($app.cfgFiles[$i] -replace '\.toml$', '').ToUpper()
    $envVarLinkName = "${envVarName}_LINK"

    #~@ Export environment variables for current config file
    if (Test-Path -Path $dotConfigPath -PathType Leaf) {
      [Environment]::SetEnvironmentVariable($envVarName, $dotConfigPath, 'Process')
      Set-Variable -Name $envVarName -Value $dotConfigPath -Scope Global
      Write-Pretty -DebugEnv $envVarName $dotConfigPath

      [Environment]::SetEnvironmentVariable($envVarLinkName, $userConfigPath, 'Process')
      Set-Variable -Name $envVarLinkName -Value $userConfigPath -Scope Global
      Write-Pretty -DebugEnv $envVarLinkName $userConfigPath
    }
    else {
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
          Write-Pretty -Tag 'Trace' "Correct symlink for $($app.cfgFiles[$i]) already exists."
          continue
        }
        else {
          Write-Pretty -Tag 'Info' "Existing symlink for $($app.cfgFiles[$i]) points elsewhere. Removing it."
          Remove-Item -Path $userConfigPath -Force
        }
      }
      else {
        #~@ Existing real file: rename to backup with timestamp
        Write-Pretty -Tag 'Info' "Existing $($app.cfgFiles[$i]) is not a symlink. Renaming to backup."
        Rename-Item -Path $userConfigPath -NewName ("$($app.cfgFiles[$i]).bak_$(Get-Date -Format 'yyyyMMddHHmmss')")
      }
    }

    #~@ Create symlink from user config path to dotfiles config path
    try {
      Write-Pretty -Tag 'Info' "Creating symlink from $dotConfigPath to $userConfigPath"
      New-Item -Path $userConfigPath -ItemType SymbolicLink -Value $dotConfigPath -Force | Out-Null
    }
    catch {
      Write-Pretty -Tag 'Error' "Failed to create symlink for $($app.cfgFiles[$i]): $_"
      Write-Pretty -Tag 'Suggestion' 'Run PowerShell as admin or developer mode for symlink permissions, or fallback to copying.'
      return $false
    }
  }
  return $true
}

function Global:Initialize-Helix {
  <#
    .SYNOPSIS
        Initializes the Helix environment.

    .DESCRIPTION
        Installs hx if needed and links multiple configuration files.
    #>
  [CmdletBinding()]
  param()

  try {
    $time = Get-Date
    $app = Get-HelixConfig

    #~@ Attempt installation and throw if fails
    if (-not (Install-Helix)) {
      throw 'Unable to complete installation.'
    }

    #~@ Attempt config linking and throw if fails
    if (-not (Set-Helix)) {
      throw 'Unable to set up configuration.'
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
Initialize-Helix
