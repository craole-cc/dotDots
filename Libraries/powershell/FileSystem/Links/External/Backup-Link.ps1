function Backup-Links {
  <#
    .SYNOPSIS
    Creates a backup of all links in a directory.

    .DESCRIPTION
    Scans a directory for all types of links and creates a backup object containing
    their paths, types, and targets for later restoration.

    .PARAMETER Directory
    The directory to backup links from.

    .EXAMPLE
    $backup = Backup-Links -Directory "C:\MyLinks"
    Creates a backup of all links in the specified directory.
    #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Directory
  )

  if (-not (Test-Path $Directory)) {
    Write-Error "Directory does not exist: $Directory"
    return
  }

  Write-Host "Creating backup of links in: $Directory" -ForegroundColor Yellow

  $links = Get-ChildItem $Directory | Test-Link -Quiet | Where-Object { $_.IsLink }
  $backup = @{}

  foreach ($link in $links) {
    $backup[$link.Path] = @{
      Type   = $link.LinkType
      Target = $link.Target
    }
    Write-Verbose "Backed up $($link.LinkType): $($link.Path) -> $($link.Target)"
  }

  Write-Host "Backup created for $($backup.Count) links" -ForegroundColor Green
  return $backup
}
