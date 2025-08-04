<#
.SYNOPSIS
    Cross-platform alias management for removing conflicting command aliases.

.DESCRIPTION
  Provides functions to register/unregister aliases for various command sets like coreutils.
  Designed to clean up PowerShell's default aliases that conflict with external tools.

.NOTES
  Author: PowerShell Community
  Version: 1.0
  Last Modified: 2025-08-25
  License: MIT

  Performance: Fast alias removal optimized for shell startup
  Dependencies: None (uses built-in PowerShell cmdlets only)

.EXAMPLE
  Unregister-CoreutilsAliases
  Register-CoreutilsAliases
  Get-RegisteredAliases -CommandSet Coreutils
#>

# Global list of coreutils commands that may be aliased in PowerShell
$Global:CoreutilsCommands = @(
  'arch', 'b2sum', 'b3sum', 'base32', 'base64', 'basename', 'basenc', 'cat', 'cksum', 'comm',
  'cp', 'csplit', 'cut', 'date', 'dd', 'df', 'dir', 'dircolors', 'dirname', 'du', 'echo',
  'env', 'expand', 'expr', 'factor', 'false', 'fmt', 'fold', 'hashsum', 'head', 'hostname',
  'join', 'link', 'ln', 'ls', 'md5sum', 'mkdir', 'mktemp', 'more', 'mv', 'nl', 'nproc',
  'numfmt', 'od', 'paste', 'pr', 'printenv', 'printf', 'ptx', 'pwd', 'readlink', 'realpath',
  'rm', 'rmdir', 'seq', 'sha1sum', 'sha224sum', 'sha256sum', 'sha3-224sum', 'sha3-256sum',
  'sha3-384sum', 'sha3-512sum', 'sha384sum', 'sha3sum', 'sha512sum', 'shake128sum', 'shake256sum',
  'shred', 'shuf', 'sleep', 'sort', 'split', 'sum', 'sync', 'tac', 'tail', 'tee', 'test',
  'touch', 'tr', 'true', 'truncate', 'tsort', 'uname', 'unexpand', 'uniq', 'unlink', 'vdir',
  'wc', 'whoami', 'yes'
)

function Global:Unregister-CoreutilsAliases {
  <#
  .SYNOPSIS
    Removes PowerShell aliases that conflict with coreutils commands.
  .DESCRIPTION
    Removes built-in PowerShell aliases for common coreutils commands to allow
    external coreutils tools to be called directly without conflicts.
  .PARAMETER Verbose
    Show detailed output of which aliases are being removed.
  .EXAMPLE
    Unregister-CoreutilsAliases
  .EXAMPLE
    Unregister-CoreutilsAliases -Verbose
  #>
  [CmdletBinding()]
  param()

  $removedCount = 0
  $totalCount = $Global:CoreutilsCommands.Count

  foreach ($aliasName in $Global:CoreutilsCommands) {
    $existingAlias = Get-Alias -Name $aliasName -ErrorAction SilentlyContinue
    if ($existingAlias) {
      try {
        Remove-Item "Alias:$aliasName" -Force -ErrorAction Stop
        Write-Verbose "Removed alias: $aliasName -> $($existingAlias.ResolvedCommandName)"
        $removedCount++
      }
      catch {
        Write-Warning "Failed to remove alias '$aliasName': $($_.Exception.Message)"
      }
    }
  }

  Write-Verbose "Removed $removedCount of $totalCount potential coreutils aliases"
}

function Global:Register-CoreutilsAliases {
  <#
  .SYNOPSIS
      Restores PowerShell's default aliases for coreutils-named commands.
  .DESCRIPTION
      Recreates common PowerShell aliases that may have been removed by Unregister-CoreutilsAliases.
      Only restores aliases for PowerShell cmdlets that actually exist.
  .EXAMPLE
      Register-CoreutilsAliases
  #>
  [CmdletBinding()]
  param()

  # Common PowerShell aliases that overlap with coreutils
  $defaultAliases = @{
    'cat'   = 'Get-Content'
    'cd'    = 'Set-Location'
    'cp'    = 'Copy-Item'
    'dir'   = 'Get-ChildItem'
    'echo'  = 'Write-Output'
    'ls'    = 'Get-ChildItem'
    'mkdir' = 'New-Item'
    'more'  = 'Get-Content'
    'mv'    = 'Move-Item'
    'pwd'   = 'Get-Location'
    'rm'    = 'Remove-Item'
    'rmdir' = 'Remove-Item'
    'sleep' = 'Start-Sleep'
    'sort'  = 'Sort-Object'
    'tee'   = 'Tee-Object'
    'touch' = 'New-Item'
    'wc'    = 'Measure-Object'
  }

  $restoredCount = 0

  foreach ($alias in $defaultAliases.GetEnumerator()) {
    $cmdExists = Get-Command -Name $alias.Value -ErrorAction SilentlyContinue
    if ($cmdExists -and -not (Get-Alias -Name $alias.Key -ErrorAction SilentlyContinue)) {
      try {
        New-Alias -Name $alias.Key -Value $alias.Value -Force -Scope Global
        Write-Verbose "Restored alias: $($alias.Key) -> $($alias.Value)"
        $restoredCount++
      }
      catch {
        Write-Warning "Failed to restore alias '$($alias.Key)': $($_.Exception.Message)"
      }
    }
  }

  Write-Verbose "Restored $restoredCount PowerShell aliases"
}

function Global:Get-RegisteredAliases {
  <#
  .SYNOPSIS
    Gets information about aliases for a specific command set.
  .DESCRIPTION
    Returns details about which aliases exist or have been removed for command sets
    like coreutils, showing current alias state.
  .PARAMETER CommandSet
    The command set to check aliases for (currently supports 'Coreutils').
  .EXAMPLE
    Get-RegisteredAliases -CommandSet Coreutils
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateSet('Coreutils')]
    [string]$CommandSet
  )

  switch ($CommandSet) {
    'Coreutils' {
      $commands = $Global:CoreutilsCommands
      break
    }
  }

  $results = foreach ($cmdName in $commands) {
    $alias = Get-Alias -Name $cmdName -ErrorAction SilentlyContinue
    [PSCustomObject]@{
      Command     = $cmdName
      HasAlias    = [bool]$alias
      AliasTarget = if ($alias) { $alias.ResolvedCommandName } else { $null }
      AliasSource = if ($alias) { $alias.Source } else { $null }
    }
  }

  $aliasCount = ($results | Where-Object HasAlias).Count
  $totalCount = $results.Count

  Write-Host "$CommandSet Aliases: $aliasCount of $totalCount commands have PowerShell aliases"
  return $results | Sort-Object Command
}
