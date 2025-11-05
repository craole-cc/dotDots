function Global:New-BackupCopy {
  <#
    .SYNOPSIS
        Creates a timestamped backup of a file or directory.
    .DESCRIPTION
        Backs up the specified path (or current location) to its parent directory with a timestamp.
    .PARAMETER Path
        The path to backup. Defaults to current location.
    .OUTPUTS
        [string] Path to the backup directory/file
    .EXAMPLE
        New-BackupCopy
        Creates a backup of the current directory in the parent directory.
    .EXAMPLE
        New-BackupCopy -Path "C:\MyProject"
        Creates a backup of C:\MyProject in C:\ with format: MyProject-backup-20241104-143022
    #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$Path = (Get-Location).Path
  )

  $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $source = Resolve-Path $Path
  $parent = Split-Path $source -Parent
  $itemName = Split-Path $source -Leaf
  $destination = Join-Path $parent "$itemName-backup-$timestamp"

  try {
    Copy-Item -Path $source -Destination $destination -Recurse -Force
    Write-Pretty -Tag 'Success' "Backup created at $destination"
    return $destination
  }
  catch {
    Write-Pretty -Tag 'Error' "Failed to create backup: $($_.Exception.Message)"
    return $null
  }
}

# Alias for convenience (though not following approved verbs)
Set-Alias -Name Backup-Path -Value New-BackupCopy -Scope Global -Force
