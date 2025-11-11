function Restore-Links {
  <#
    .SYNOPSIS
    Restores links from a backup created by Backup-Links.

    .DESCRIPTION
    Takes a backup object created by Backup-Links and recreates all the links
    with their original types and targets.

    .PARAMETER Backup
    The backup object created by Backup-Links containing link information.

    .EXAMPLE
    $backup = Backup-Links -Directory "C:\MyLinks"
    # ... some operations that modify links ...
    Restore-Links -Backup $backup
    Restores all links from the backup.
    #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Backup
  )

  if ($Backup.Count -eq 0) {
    Write-Warning 'No links to restore in the provided backup'
    return
  }

  Write-Host "Restoring $($Backup.Count) links from backup..." -ForegroundColor Yellow

  $successCount = 0
  $failureCount = 0

  foreach ($path in $Backup.Keys) {
    $info = $Backup[$path]

    # Remove existing item if it exists
    if (Test-Path $path) {
      try {
        Remove-Item $path -Force
        Write-Verbose "Removed existing item: $path"
      }
      catch {
        Write-Warning "Failed to remove existing item: $path"
      }
    }

    try {
      if ($info.Type -eq 'SymbolicLink') {
        New-Item -ItemType SymbolicLink -Path $path -Target $info.Target -Force | Out-Null
      }
      elseif ($info.Type -eq 'HardLink') {
        New-Item -ItemType HardLink -Path $path -Target $info.Target -Force | Out-Null
      }
      elseif ($info.Type -eq 'Junction') {
        New-Item -ItemType Junction -Path $path -Target $info.Target -Force | Out-Null
      }

      Write-Host "✓ Restored: $(Split-Path $path -Leaf)" -ForegroundColor Green
      $successCount++
    }
    catch {
      Write-Error "Failed to restore: $path - $($_.Exception.Message)"
      $failureCount++
    }
  }

  Write-Host "`nRestore completed:" -ForegroundColor Yellow
  Write-Host "  Successfully restored: $successCount links" -ForegroundColor Green
  if ($failureCount -gt 0) {
    Write-Host "  Failed to restore: $failureCount links" -ForegroundColor Red
  }
}
