function Get-LinkReport {
  <#
    .SYNOPSIS
    Generates a comprehensive report of links in a directory.

    .DESCRIPTION
    Analyzes all items in a directory tree and provides statistics about different types of links,
    including broken links and regular files.

    .PARAMETER Path
    The directory path to analyze for links.

    .EXAMPLE
    Get-LinkReport -Path "C:\MyData"
    Generates a report of all links and files in the specified directory.
    #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path $Path)) {
    Write-Error "Path does not exist: $Path"
    return
  }

  Write-Host "Analyzing directory: $Path" -ForegroundColor Yellow

  $allItems = Get-ChildItem $Path -Recurse -Force
  $linkInfo = $allItems | Test-Link -Quiet

  $report = @{
    TotalItems    = $allItems.Count
    SymbolicLinks = ($linkInfo | Where-Object { $_.LinkType -eq 'SymbolicLink' }).Count
    HardLinks     = ($linkInfo | Where-Object { $_.LinkType -eq 'HardLink' }).Count
    Junctions     = ($linkInfo | Where-Object { $_.LinkType -eq 'Junction' }).Count
    BrokenLinks   = ($linkInfo | Where-Object { $_.IsLink -and -not $_.IsValid }).Count
    RegularFiles  = ($linkInfo | Where-Object { -not $_.IsLink }).Count
  }

  $reportObject = [PSCustomObject]$report

  # Display formatted report
  Write-Host "`nLink Report for: $Path" -ForegroundColor Cyan
  Write-Host '================================' -ForegroundColor Cyan
  Write-Host "Total Items:     $($reportObject.TotalItems)" -ForegroundColor White
  Write-Host "Symbolic Links:  $($reportObject.SymbolicLinks)" -ForegroundColor Green
  Write-Host "Hard Links:      $($reportObject.HardLinks)" -ForegroundColor Blue
  Write-Host "Junctions:       $($reportObject.Junctions)" -ForegroundColor Magenta
  Write-Host "Broken Links:    $($reportObject.BrokenLinks)" -ForegroundColor Red
  Write-Host "Regular Files:   $($reportObject.RegularFiles)" -ForegroundColor Gray

  return $reportObject
}
