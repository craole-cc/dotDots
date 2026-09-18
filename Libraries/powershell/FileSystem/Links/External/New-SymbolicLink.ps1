function New-SymbolicLink {
  <#
    .SYNOPSIS
    Creates symbolic links and validates their integrity.

    .DESCRIPTION
    A wrapper function for New-Link that specifically creates symbolic links and then validates
    each created link to ensure it's working correctly.

    .PARAMETER Target
    The target directory where links will be created.

    .PARAMETER Source
    One or more source paths to create links from.

    .PARAMETER Type
    Type of link to create (defaults to 'Symbolic').

    .EXAMPLE
    New-SymbolicLink -Target "C:\links" -Source "C:\data\file.txt"
    Creates a symbolic link and validates it works correctly.
    #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Target,

    [Parameter(Mandatory = $true)]
    [string[]]$Source,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Symbolic', 'Hard')]
    [string]$Type = 'Symbolic'
  )

  # Create the link
  $result = New-Link -Target $Target -Source $Source -Type $Type -Force

  # Validate each created link
  if ($result.SuccessCount -gt 0) {
    Write-Host "`nValidating created links..." -ForegroundColor Yellow

    $targetDir = if ($Target.EndsWith('\')) { $Target } else { "$Target\" }
    Get-ChildItem $targetDir | ForEach-Object {
      $linkStatus = Test-Link $_.FullName -Quiet
      if ($linkStatus.IsLink -and -not $linkStatus.IsValid) {
        Write-Warning "Created link is broken: $($_.Name)"
      }
    }
  }

  return $result
}
