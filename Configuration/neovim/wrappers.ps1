function Global:Invoke-Neovim {
  <#
    .SYNOPSIS
        Invokes the nvim command with provided arguments.
    .PARAMETER Arguments
        Arguments to pass to the nvim command.
    #>
  param (
    [Parameter(ValueFromRemainingArguments = $true, Position = 0)]
    [string[]]$Arguments = @()
  )
  & nvim @Arguments
}

function Global:Open-NeovimConfig {
  <#
    .SYNOPSIS
        Opens the Neovim configuration directory in Neovim.
    #>
  $config = Get-NeovimConfig
  $configPath = $config.conf.dots

  if (Test-Path -Path $configPath) {
    & nvim $configPath
    $ctx = 'nvim config'
    if ($LASTEXITCODE -eq 0) {
      Write-Pretty -Tag 'Info' -NoNewLine -As $ctx 'Opened Neovim configuration.'
    }
    else {
      Write-Pretty -Tag 'Error' -NoNewLine -As $ctx 'Failed to open Neovim configuration.'
    }
  }
  else {
    Write-Pretty -Tag 'Error' "Configuration directory not found at $configPath"
  }
}

function Global:Update-NeovimPlugins {
  <#
    .SYNOPSIS
        Updates Neovim plugins using the configured plugin manager.
    .DESCRIPTION
        Runs headless plugin update commands for lazy.nvim or packer.nvim.
    #>
  $ctx = 'nvim plugins'
  Write-Pretty -Tag 'Info' -NoNewLine -As $ctx 'Updating plugins...'

  # Try lazy.nvim first (most common modern plugin manager)
  & nvim --headless '+Lazy! sync' +qa

  if ($LASTEXITCODE -eq 0) {
    Write-Pretty -Tag 'Success' -NoNewLine -As $ctx 'Plugins updated successfully.'
  }
  else {
    Write-Pretty -Tag 'Error' -NoNewLine -As $ctx 'Failed to update plugins.'
  }
}

function Global:Test-NeovimHealth {
  <#
    .SYNOPSIS
        Runs Neovim's health check diagnostics.
    #>
  & nvim +checkhealth
  $ctx = 'nvim health'
  if ($LASTEXITCODE -eq 0) {
    Write-Pretty -Tag 'Info' -NoNewLine -As $ctx 'Health check completed.'
  }
  else {
    Write-Pretty -Tag 'Error' -NoNewLine -As $ctx 'Health check encountered issues.'
  }
}

function Global:Clear-NeovimCache {
  <#
    .SYNOPSIS
        Clears Neovim cache and state files.
    #>
  $ctx = 'nvim clean'

  # Define cache locations based on platform
  if ($IsWindows -or $env:OS -match 'Windows') {
    $cacheDir = Join-Path $env:LOCALAPPDATA 'nvim-data'
    $stateDir = Join-Path $env:LOCALAPPDATA 'nvim-data' 'state'
  }
  else {
    $dataHome = if ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME } else { Join-Path $HOME '.local' 'share' }
    $stateHome = if ($env:XDG_STATE_HOME) { $env:XDG_STATE_HOME } else { Join-Path $HOME '.local' 'state' }
    $cacheDir = Join-Path $dataHome 'nvim'
    $stateDir = Join-Path $stateHome 'nvim'
  }

  $cleanedAny = $false

  # Clean cache directories
  foreach ($dir in @($cacheDir, $stateDir)) {
    if (Test-Path -Path $dir) {
      Write-Pretty -Tag 'Trace' "Cleaning $dir"
      Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
      $cleanedAny = $true
    }
  }

  if ($cleanedAny) {
    Write-Pretty -Tag 'Success' -NoNewLine -As $ctx 'Cache and state files cleaned.'
  }
  else {
    Write-Pretty -Tag 'Info' -NoNewLine -As $ctx 'No cache files to clean.'
  }
}

# Set convenient aliases
Set-Alias -Name v -Value Invoke-Neovim -Scope Global -Force
Set-Alias -Name vim -Value Invoke-Neovim -Scope Global -Force
Set-Alias -Name vi -Value Invoke-Neovim -Scope Global -Force
Set-Alias -Name nv -Value Invoke-Neovim -Scope Global -Force
Set-Alias -Name vconf -Value Open-NeovimConfig -Scope Global -Force
Set-Alias -Name vupdate -Value Update-NeovimPlugins -Scope Global -Force
Set-Alias -Name vhealth -Value Test-NeovimHealth -Scope Global -Force
Set-Alias -Name vclean -Value Clear-NeovimCache -Scope Global -Force
