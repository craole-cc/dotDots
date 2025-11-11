function Backup-Folder {
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
        New-PathBackup
        Creates a backup of the current directory in the parent directory.
    .EXAMPLE
        New-PathBackup -Path "C:\MyProject"
        Creates a backup of C:\MyProject in C:\archive with format: MyProject-20241104_143022
    #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$Path = (Get-Location).Path
    ,
    [Parameter(Mandatory = $false)]
    [Alias ('Dry', 'Dry-Run' , 'Simulate')]
    [switch]$WhatIf
  )


  $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
  $source = Resolve-Path $Path
  $parent = Split-Path $source -Parent
  $itemName = Split-Path $source -Leaf
  $destination = Join-Path $parent 'archive' "$itemName-$timestamp"

  try {
    if ($WhatIf) {
      Write-Pretty -NoNewLine -Tag 'Warn' "Would attempt to copy '$source' to '$destination'"

    }
    else {
      Copy-Item -Path $source -Destination $destination -Recurse -Force
      Write-Pretty -NoNewLine -Tag 'Info' 'Backup created successfully'
      return $destination
    }
  }
  catch {
    Write-Pretty -NoNewLine -Tag 'Error' "Failed to create backup: $($_.Exception.Message)"
    return $null
  }
}

# Alias for convenience (though not following approved verbs)
Set-Alias -Name Backup-Path -Value New-PathBackup -Scope Global -Force
