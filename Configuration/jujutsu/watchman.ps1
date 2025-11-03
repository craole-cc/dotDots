function Global:Get-WatchmanConfig {
  <#
    .SYNOPSIS
        Returns structured config variables for Watchman.
    #>
  [CmdletBinding()]
  param()  $cmd = 'watchman'
  $name = 'watchman'
  $pkg = @{
    scoop  = 'watchman'
    winget = 'facebook.watchman'
  }

  return @{
    cmd     = $cmd
    name    = $name
    desc    = if ($cmd -like $name) { $name } else { "$name ($cmd)" }
    pkg     = $pkg
    envBase = ($cmd.ToUpper() + '_CONFIG')  # No config files expected
  }
}

function Global:Install-Watchman {
  <#
    .SYNOPSIS
        Installs Watchman if not already present.

    .OUTPUTS
        [bool] Success status.
    #>
  [CmdletBinding()]
  param()

  $app = Get-WatchmanConfig

  #~@ Check if Watchman command or service exists
  if (Get-CommandFirst -Name $app.cmd -ErrorAction SilentlyContinue) {
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
  if (-not (Get-CommandFirst -Name $app.cmd -ErrorAction SilentlyContinue)) {
    Write-Pretty -Tag 'Error' "$($app.desc) still not available after installation."
    return $false
  }

  Write-Pretty -Tag 'Success' "$($app.desc) installed successfully."
  return $true
}

function Global:Initialize-Watchman {
  <#
    .SYNOPSIS
        Initializes Watchman installation.

    .DESCRIPTION
        Installs Watchman if missing.
    #>
  [CmdletBinding()]
  param()

  try {
    $time = Get-Date
    $app = Get-WatchmanConfig

    if (-not (Get-CommandFirst -Name $app.cmd -ErrorAction SilentlyContinue)) {
      if (-not (Install-Watchman)) {
        Write-Pretty -Tag 'Error' "Unable to install $($app.desc)."
        return
      }
    }

    Write-Pretty -Tag 'Info' -NoNewLine -As $($app.desc) -Init $time
  }
  catch {
    Write-Pretty -Tag 'Error' "Failed to initialize $($app.desc)" "$($_.Exception.Message)"
  }
}

#~@ Auto-initialize on script load
Initialize-Watchman
