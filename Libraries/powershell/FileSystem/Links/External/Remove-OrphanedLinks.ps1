function Remove-OrphanedLinks {
  <#
    .SYNOPSIS
    Removes orphaned (broken) links from a directory.

    .DESCRIPTION
    Scans a directory for links whose targets no longer exist and removes them.
    Provides a WhatIf parameter to preview what would be removed.

    .PARAMETER Directory
    The directory to scan for orphaned links.

    .PARAMETER WhatIf
    Shows what would be removed without actually deleting anything.

    .EXAMPLE
    Remove-OrphanedLinks -Directory "C:\Links"
    Removes all orphaned links from the specified directory.

    .EXAMPLE
    Remove-OrphanedLinks -Directory "C:\Links" -WhatIf
    Shows what orphaned links would be removed without deleting them.
    #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Directory,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
  )

  if (-not (Test-Path $Directory)) {
    Write-Pretty -NoNewLine -Tag 'Error' "Directory does not exist: $Directory"
    return
  }

  Write-Pretty -NoNewLine -Tag 'Info' "Scanning for orphaned links in: $Directory" -ForegroundColor Yellow

  $orphanedLinks = Get-ChildItem $Directory -Recurse | Test-Link -Quiet |
  Where-Object { $_.IsLink -and -not $_.IsValid }

  if ($orphanedLinks.Count -eq 0) {
    Write-Pretty -NoNewLine -Tag 'Info' 'No orphaned links found' -ForegroundColor Green
    return
  }

  Write-Pretty -NoNewLine -Tag 'Info' "Found $($orphanedLinks.Count) orphaned links:" -ForegroundColor Yellow

  $removedCount = 0

  foreach ($link in $orphanedLinks) {
    $linkName = Split-Path $link.Path -Leaf
    $targetInfo = if ($link.Target) { " -> $($link.Target)" } else { '' }

    if ($WhatIf) {
      Write-Pretty -NoNewLine -Tag 'Info' "Would remove orphaned $($link.LinkType.ToLower()): $linkName$targetInfo" -ForegroundColor Yellow
      $removedCount++
    }
    else {
      try {
        Remove-Item $link.Path -Force
        Write-Pretty -NoNewLine -Tag 'Info' "✗ Removed orphaned $($link.LinkType.ToLower()): $linkName$targetInfo" -ForegroundColor Red
        $removedCount++
      }
      catch {
        Write-Pretty -NoNewLine -Tag 'Error' "Failed to remove orphaned link: $linkName - $($_.Exception.Message)"
      }
    }
  }

  $actionText = if ($WhatIf) { 'Would remove' } else { 'Removed' }
  # TODO: This is not using Write-Preety in the right way
  Write-Pretty -NoNewLine -Tag 'Info' "`nCleanup summary:" -ForegroundColor Yellow
  Write-Pretty -NoNewLine -Tag 'Info' "  $actionText $removedCount orphaned links" -ForegroundColor $(if ($WhatIf) { 'Yellow' } else { 'Red' })
}
