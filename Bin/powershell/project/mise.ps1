#region Installation and Initialization

function Install-Mise {
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

function Initialize-Mise {
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

function Set-MiseEnv {
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
  $rcStr = Join-Path $env:USERPROFILE '.config\mise\config2.toml'
  if (-not (Test-Path $rcStr -PathType Leaf)) {
    $escapedRcPath = Format-PathSafe $rcStr
    Set-Content `
      -Path $rcStr `
      -Value "[env]`nMISE_RC = '$escapedRcPath'"
  }

  #~@ Define the MISE_RC environment variable.
  $rcPath = [System.IO.Path]::GetFullPath($rcStr)
  $escapedRcPath = Format-PathSafe $rcPath
  # Set-Env -Name 'MISE_RC' -Target $escapedRcPath -Type 'variable'

  #~@ Define convenient aliases for mise commands
  #     Set-Env -Name 'm' -Target Invoke-Mise -Type 'alias'
  # Set-Env -Name 'push' -Target Push-Mise -Type 'alias'
  # Set-Env -Name 'lint' -Target Format-Mise -Type 'alias'
  # Set-Alias -Name m -Value Invoke-Mise -Scope Global -Force
  Write-Pretty -DebugEnv 'Alias' 'm' "$escapedRcPath"
  # Set-Alias -Name push -Value Push-Mise -Scope Global -Force
  # Set-Alias -Name lint -Value Format-Mise -Scope Global -Force
}

#endregion

#region Wrappers

function Invoke-Mise {
  <#
    .SYNOPSIS
        Invokes the mise command with provided arguments.
    .PARAMETER Arguments
        Arguments to pass to the mise command.
    #>
  param (
    [Parameter(ValueFromRemainingArguments = $true, Position = 0)]
    [string[]]$Arguments = @()
  )
  & mise @Arguments
}

function Push-Mise {
  <#
    .SYNOPSIS
        Pushes changes to the remote repository using mise.
    #>
  mise push
  $ctx = 'mise push'
  if ($LASTEXITCODE -eq 0) {
    Write-Pretty -Tag 'Info' -NoNewLine -As $ctx 'Successfully committed changes to the remote repository.'
  }
  else {
    Write-Pretty -Tag 'Error' -NoNewLine -As $ctx 'Failed to push changes to the remote repository.'
  }
}

function Format-Mise {
  <#
    .SYNOPSIS
        Lints the mise configuration.
    #>
  mise lint
  $ctx = 'mise lint'
  if ($LASTEXITCODE -eq 0) {
    Write-Pretty -Tag 'Info' -NoNewLine -As $ctx 'Linting completed without any issues.'
  }
  else {
    Write-Pretty -Tag 'Error' -NoNewLine -As $ctx 'Issues encountered during linting.'
  }
}

#endregion

#~@ Initialize mise environment on script import
Initialize-Mise
