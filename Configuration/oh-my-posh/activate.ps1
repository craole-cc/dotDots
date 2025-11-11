
function Global:Get-OhMyPoshConfig {
  <#
    .SYNOPSIS
        Returns structured config variables for the mise tool.
    #>
  [CmdletBinding()]
  param()

  $cmd = 'oh-my-posh'
  $name = 'oh-my-posh'
  $pkg = @{
    scoop  = 'oh-my-posh'
    winget = 'JanDeDobbeleer.OhMyPosh'
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

function Global:Initialize-OhMyPosh {
  <#
    .SYNOPSIS
        Initializes the OhMyPosh environment.

    .DESCRIPTION
        Installs mise if needed and links configuration.
    #>


  [CmdletBinding()]
  param()

  try {
    #~@ Retrieve config
    $time = Get-Date
    $app = Get-OhMyPoshConfig
    $cfg = $app.cfg.dots

    #~@ Install if missing
    if (-not (Get-Command -Name $app.cmd -ErrorAction SilentlyContinue)) {
      if (-not (Install-Mise)) {
        Write-Pretty -Tag 'Error' "Failed to install $($app.desc), aborting."
        return
      }
    }

    #~@ Activate config
    if (-not $cfg) {
      Write-Pretty -Tag 'Debug' `
        'No custom Oh My Posh config found, using the default'
      oh-my-posh init pwsh | Invoke-Expression
    }
    else {
      Write-Pretty -DebugEnv $app.env $cfg
      oh-my-posh init pwsh --config $cfg | Invoke-Expression
    }
    if ($LASTEXITCODE -ne 0) {
      Write-Pretty -Tag 'Error' 'Failed to activate oh-my-posh.'
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
Initialize-OhMyPosh
