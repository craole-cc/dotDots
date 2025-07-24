
function Global:Install-Mise {
  <#
    .SYNOPSIS
        Installs mise if not already present.
    .DESCRIPTION
        Installs mise using scoop or winget if not found, then runs `mise install` to set up tools.
    .OUTPUTS
        [bool] Returns $true on success, $false on failure.
    #>
  [CmdletBinding()]
  param()

  if (Get-Command -Name 'mise' -ErrorAction SilentlyContinue) {
    Write-Pretty -Tag 'Trace' 'mise is already installed.'
    return $true
  }

  Write-Pretty -Tag 'Warning' 'mise is not installed. Attempting to install...'
  if (Get-Command -Name 'scoop' -ErrorAction SilentlyContinue) {
    Write-Pretty -Tag 'Trace' 'Installing mise with scoop...'
    scoop install mise
  }
  elseif (Get-Command -Name 'winget' -ErrorAction SilentlyContinue) {
    Write-Pretty -Tag 'Trace' 'Installing mise with winget...'
    winget install jdx.mise
  }
  else {
    Write-Pretty -Tag 'Error' 'Neither scoop nor winget is available. Please install mise manually.'
    return $false
  }

  #~@ Verify installation
  if (-not (Get-Command -Name 'mise' -ErrorAction SilentlyContinue)) {
    Write-Pretty -Tag 'Error' 'mise command is still not available after installation attempt.'
    return $false
  }

  #~@ Install dependencies defined in mise config
  Write-Pretty -Tag 'Info' 'Running `mise install` to set up tools...'
  mise install --quiet

  if ($LASTEXITCODE -eq 0) {
    Write-Pretty -Tag 'Success' 'mise has been successfully installed and its tools are set up.'
    return $true
  }
  return $false
}

function Global:Initialize-Mise {
  <#
    .SYNOPSIS
        Initializes the mise environment for PowerShell.
    .DESCRIPTION
        Ensures mise is installed and activated, sets up environment variables and aliases.
    #>
  [CmdletBinding()]
  param()

  $InitTime = Get-Date

  if (-not (Get-Command -Name 'mise' -ErrorAction SilentlyContinue)) {
    if (-not (Install-Mise)) {
      Write-Pretty -Tag 'Error' 'Mise installation failed. Cannot initialize.'
      return
    }
  }

  try {
    mise activate pwsh | Out-String | Invoke-Expression
    Set-MiseEnv
    Write-Pretty -Tag 'Info' -NoNewLine -As 'mise-en-place' -Init $InitTime
  }
  catch {
    Write-Pretty -Tag 'Error' 'Activation failed' "Details: $($_.Exception.Message)"
  }
}

function Global:Set-MiseEnv {
  <#
    .SYNOPSIS
        Sets environment variables and aliases for mise.
    .DESCRIPTION
        Dynamically sets CMD_MISE and MISE_RC for the current user, and defines convenient aliases.
    #>

  #~@ Locate the path to the mise executable.
  $miseCmd = Get-CommandFirst -Name 'mise' -ErrorAction SilentlyContinue
  if ($miseCmd) {
    #~@ Define the CMD_MISE environment variable.
    $cmdPath = Format-PathSafe $miseCmd.Source
    Write-Host "CMD_MISE: $cmdPath"
    # Set-Env -Name 'CMD_MISE' -Target $cmdPath
  }

  #~@ Ensure the MISE_RC file exists.
  #TODO: Create symlink of the mise_rc from DOTS_CFG to USERPROFILE
  # $miseRC = Join-Path $env:USERPROFILE '.config\mise\config.toml'
  # Write-Host "DOTS_CFG: $env:DOTS"
  $DOTS_CFG = $env:DOTS_CFG
  $DOTS_CFG_MISE = Join-Path $env:DOTS 'Configuration\mise\config.toml'
  Write-Host "MISE_RC: $DOTS_CFG_MISE"
  # Set-Env 'MiseRC' $(Resolve-PathSafely $DOTS_CFG_MISE)
  Invoke-Fyls -Path $DOTS_CFG_MISE
  Write-Host "HERE"
return $true

  #~@ Define the MISE_RC environment variable.
  # $rcPath = [System.IO.Path]::GetFullPath($rcStr)
  # $escapedRcPath = Format-PathSafe $rcPath
  # Set-Env -Name 'MISE_RC' -Target $escapedRcPath -Type 'variable'

  #~@ Define convenient aliases for mise commands
  #     Set-Env -Name 'm' -Target Invoke-Mise -Type 'alias'
  # Set-Env -Name 'push' -Target Push-Mise -Type 'alias'
  # Set-Env -Name 'lint' -Target Format-Mise -Type 'alias'
  # Set-Alias -Name m -Value Invoke-Mise -Scope Global -Force
  # Write-Pretty -DebugEnv 'Alias' 'm' "$escapedRcPath"
  # Set-Alias -Name push -Value Push-Mise -Scope Global -Force
  # Set-Alias -Name lint -Value Format-Mise -Scope Global -Force
}

Initialize-Mise
