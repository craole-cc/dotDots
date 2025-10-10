function Global:Get-MeldConfig {
  <#
    .SYNOPSIS
        Returns structured config variables for meld tool.
    #>
  [CmdletBinding()]
  param()

  $cmd = 'meld'
  $name = 'meld'
  $desc = "$cmd ($name)"

  return @{
    cmd       = $cmd
    name      = $name
    desc      = $desc
    scoopPkg  = 'meld'
    wingetPkg = 'Meld.Meld'
    envBase   = ($cmd.ToUpper() + '_CONFIG')  # Not used since no config file
  }
}

function Global:Install-Meld {
  <#
    .SYNOPSIS
        Installs meld if not already present.

    .OUTPUTS
        [bool] Success status.
    #>
  [CmdletBinding()]
  param()

  $app = Get-MeldConfig

  #~@ Check if meld command exists
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

function Global:Initialize-Meld {
  <#
    .SYNOPSIS
        Initializes the Meld environment (installs Meld).

    .DESCRIPTION
        Installs Meld tool if needed.
    #>
  [CmdletBinding()]
  param()

  try {
    $time = Get-Date
    $app = Get-MeldConfig

    if (-not (Get-CommandFirst -Name $app.cmd -ErrorAction SilentlyContinue)) {
      if (-not (Install-Meld)) {
        Write-Pretty -Tag 'Error' 'Unable to install Meld.'
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
Initialize-Meld
