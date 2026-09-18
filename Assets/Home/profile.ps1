<#
.SYNOPSIS
    Locates and initializes the DOTS environment for PowerShell.
.DESCRIPTION
    This script searches for a DOTS directory (where dotfiles are stored) by looking in specified parent directories,
    checking for target directory names, and validating with marker files. It sets global variables and environment variables
    for the DOTS path and loads the default profile if found.
.NOTES
    File Name      : Profile.ps1
    Author         : Craig 'Craole' Cole
    Prerequisite   : PowerShell 5.1 or later
    Copyright      : (c) Craig 'Craole' Cole, 2025
#>

#Requires -Version 5.1

#region DOTS Manager

<#
.SYNOPSIS
    Locates the DOTS directory by searching parent directories for target folders with marker files.
.DESCRIPTION
    Searches through specified parent directories for target folder names (like `.dots`, 'dotfiles', etc.) and checks for the presence
    of marker files (like `.dotsrc`, `.git`, `flake.nix`) to identify the DOTS directory.
.PARAMETER Parents
    An array of parent directories to search. Defaults to common dotfiles locations.
.PARAMETER Targets
    An array of target directory names to look for within parent directories. Defaults to common dotfiles names.
.PARAMETER Markers
    An array of marker file names used to validate the DOTS directory. Defaults to common marker files.
.EXAMPLE
    Get-DOTS -Parents "D:/Projects/GitHub/CC", "D:/Dotfiles" -Targets ".dots", "dotfiles" -Markers ".dotsrc", ".git"
    Returns the path to the first valid DOTS directory found.
#>
function Global:Get-DOTS {
  [CmdletBinding()]
  param(
    [Parameter()]
    [string[]]$Parents = @(
      'D:/Projects/GitHub/CC',
      'D:/Configuration',
      'D:/Dotfiles',
      $env:USERPROFILE
    ),
    [Parameter()]
    [string[]]$Targets = @(
      '.dots',
      'dotDots',
      'dots',
      'dotfiles',
      'global',
      'config',
      'common'
    ),
    [Parameter()]
    [string[]]$Markers = @(
      '.dotsrc',
      '.git',
      'flake.nix'
    )
  )

  if ($env:DOTS) {
    $dotsRc = Join-Path $env:DOTS '.dotsrc'
    if (Test-Path -LiteralPath $dotsRc -PathType Leaf) {
      $Global:DOTS = $env:DOTS
      $Global:DOTS_RC = $dotsRc
      Set-Item -Path 'env:DOTS_RC' -Value $DOTS_RC
      return
    }
  }

  foreach ($parent in $Parents) {
    # Normalize to full system path
    try { $absParent = [IO.Path]::GetFullPath($parent) } catch { continue }
    if (-not (Test-Path -Path $absParent -PathType Container)) { continue }

    foreach ($target in $Targets) {
      $potentialDOTS = [IO.Path]::Combine($absParent, $target)
      if (-not (Test-Path -Path $potentialDOTS -PathType Container)) { continue }

      foreach ($marker in $Markers) {
        $markerPath = [IO.Path]::Combine($potentialDOTS , $marker)
        if (Test-Path -Path $markerPath -PathType Leaf) {
          $Global:DOTS = $potentialDOTS
          [Environment]::SetEnvironmentVariable('DOTS', $DOTS, 'User')
          Set-Item -Path 'env:DOTS' -Value $DOTS
          Write-Debug "DOTS => $DOTS"

          $Global:DOTS_RC = $markerPath
          [Environment]::SetEnvironmentVariable('DOTS_RC', $DOTS_RC, 'Process')
          Set-Item -Path 'env:DOTS_RC' -Value $DOTS_RC
          Write-Debug "DOTS_RC => $DOTS_RC"

          return
        }
      }
    }
  }

  Write-Error 'Unable to determine the DOTS directory from the potential locations'
  return $null
}

<#
.SYNOPSIS
    Initializes the DOTS environment by locating the DOTS directory and loading its polyglot RC file.
.DESCRIPTION
    Uses Get-DOTS to find the DOTS directory, sets global and environment variables, and loads the polyglot RC file.
.EXAMPLE
    Invoke-DOTS
    Locates the DOTS directory and loads its polyglot RC file.
#>
function Global:Invoke-DOTS {
  [CmdletBinding()]
  param()

  Get-DOTS
  if (-not $DOTS -or -not $DOTS_RC) {
    Write-Error 'Invoke-DOTS: DOTS and DOTS_RC variables must be set to proceed.'
    return $null
  }
  else {
    try {
      Set-DOTSPowerShellPath
      Write-Verbose "Attempting to invoke polyglot RC: ${DOTS_RC}"
      Invoke-PolyglotRC $DOTS_RC
    }
    catch {
      Write-Error "Failed to load DOTS_RC: $_"
      return $null
    }
  }
}

#endregion

#region Shell Path

<#
.SYNOPSIS
    Places the discovered PowerShell library directories before other libraries.

.DESCRIPTION
    Keeps the system PATH language-neutral while giving a PowerShell session
    precedence to its native .ps1 command directories. The paths have already
    been discovered by the Nix script environment; this function only reorders
    them and does not walk the library tree at shell startup.
#>
function Global:Set-DOTSPowerShellPath {
  [CmdletBinding()]
  param()

  $library = $env:DOTS_LIB_PWSH
  if (-not $library) {
    $library = Join-Path $DOTS 'Libraries/powershell'
  }

  $separator = [string][IO.Path]::PathSeparator
  $entries = @($env:PATH -split [Regex]::Escape($separator) | Where-Object { $_ })
  $native = @($entries | Where-Object {
      $_ -eq $library -or
      $_.StartsWith("$library/") -or
      $_.StartsWith("$library\\")
    })

  if ($native.Count -gt 0) {
    $env:PATH = (@($native) + @($entries | Where-Object { $_ -notin $native }) |
      Select-Object -Unique) -join $separator
  }
}

#endregion

#region Polyglot RC Handler

<#
.SYNOPSIS
    Executes PowerShell commands from a polyglot RC file using improved parsing.
.DESCRIPTION
    Parses the polyglot RC file and extracts the PowerShell section for execution as a complete block.
.PARAMETER RcPath
    Path to the polyglot RC file.
#>
function Global:Invoke-PolyglotRC {
  [CmdletBinding()]
  param(
    # [Parameter(Mandatory = $true)]
    # [string]$RcPath,
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$RcPath
  )

  if (-not (Test-Path -Path $RcPath -PathType Leaf)) {
    Write-Error "RC file not found: $RcPath"
    return
  }

  try {
    $content = Get-Content -Path $RcPath -Raw

    $powershellPattern = '(?s)# === POWERSHELL ===.*?(?=# === \w+ ===|\z)'

    if ($content -match $powershellPattern) {
      $powershellSection = $matches[0]
      Write-Verbose 'Found PowerShell section in polyglot RC'

      $lines = $powershellSection -split "`n"
      $cleanLines = @()
      $inCommentBlock = $false
      $foundFirstCode = $false

      foreach ($line in $lines) {
        if ($line -match '# === POWERSHELL ===') { continue }

        if ($line -match '^\s*<#') {
          $inCommentBlock = $true
          continue
        }
        if ($line -match '^\s*#>') {
          $inCommentBlock = $false
          continue
        }
        if ($inCommentBlock) { continue }

        if (-not $foundFirstCode -and ($line -match '^\s*#' -or
            $line -match '^\s*\.' -or
            $line.Trim() -eq '')) {
          continue
        }

        if ($line.Trim() -ne '' -and $line -notmatch '^\s*#' -and $line -notmatch '^\s*\.') {
          $foundFirstCode = $true
        }

        if ($foundFirstCode) {
          $cleanLines += $line
        }
      }

      if ($cleanLines.Count -gt 0) {
        $powershellCode = $cleanLines -join "`n"
        Write-Verbose 'Executing PowerShell section from polyglot RC'
        Write-Verbose "PowerShell code:`n$powershellCode"

        try {
          $scriptBlock = [ScriptBlock]::Create($powershellCode)
          & $scriptBlock
        }
        catch {
          Write-Error "Failed to execute PowerShell section |> $_"
        }
      }
      else {
        Write-Error 'No executable PowerShell code found in polyglot RC file'
      }
    }
    else {
      Write-Error 'No PowerShell section found in polyglot RC file'
    }
  }
  catch {
    Write-Error "Failed to process polyglot RC file |> $_"
  }
}

#endregion

#region Main

<#
.SYNOPSIS
    Main execution block for the DOTS initialization script.
.DESCRIPTION
    Sets output preferences and initializes the DOTS environment.
#>

Invoke-DOTS

#endregion
