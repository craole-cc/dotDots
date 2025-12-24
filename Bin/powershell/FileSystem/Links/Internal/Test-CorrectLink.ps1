function Test-CorrectLink {
  <#
    .SYNOPSIS
    Helper function to check if existing link points to correct source.

    .DESCRIPTION
    Validates whether an existing link (symbolic or hard) points to the expected source path.

    .PARAMETER TargetPath
    The path of the existing link to test.

    .PARAMETER ExpectedSourcePath
    The expected source path the link should point to.

    .PARAMETER LinkType
    The type of link to test ('Symbolic' or 'Hard').
    #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,

    [Parameter(Mandatory = $true)]
    [string]$ExpectedSourcePath,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Symbolic', 'Hard')]
    [string]$LinkType
  )

  if (-not (Test-Path $TargetPath)) {
    return $false
  }

  $Item = Get-Item $TargetPath -Force

  # For symbolic links
  if ($LinkType -eq 'Symbolic') {
    if ($Item.LinkType -ne 'SymbolicLink') {
      return $false
    }

    $ActualTarget = $Item.Target
    if ($ActualTarget -is [array]) {
      $ActualTarget = $ActualTarget[0]
    }

    try {
      $ResolvedActual = Resolve-Path $ActualTarget -ErrorAction Stop
      $ResolvedExpected = Resolve-Path $ExpectedSourcePath -ErrorAction Stop
      return $ResolvedActual.Path -eq $ResolvedExpected.Path
    }
    catch {
      return $false
    }
  }

  # For hard links
  if ($LinkType -eq 'Hard') {
    if ($Item.LinkType -ne 'HardLink') {
      return $false
    }

    # Compare file attributes for hard links
    try {
      $SourceItem = Get-Item $ExpectedSourcePath -Force
      return ($Item.CreationTime -eq $SourceItem.CreationTime) -and
      ($Item.LastWriteTime -eq $SourceItem.LastWriteTime) -and
      ($Item.Length -eq $SourceItem.Length)
    }
    catch {
      return $false
    }
  }

  return $false
}
