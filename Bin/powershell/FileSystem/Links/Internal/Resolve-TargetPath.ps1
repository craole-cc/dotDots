function Resolve-TargetPath {
  <#
    .SYNOPSIS
    Helper function to resolve target path intelligently based on type.

    .DESCRIPTION
    Resolves target paths for different target types (Home, Path, Directory)
    and handles relative/absolute path resolution.

    .PARAMETER Path
    The path to resolve.

    .PARAMETER Type
    The type of target path resolution to perform.
    #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Home', 'Directory', 'Path')]
    [string]$Type
  )

  switch ($Type) {
    'Home' {
      return $env:USERPROFILE
    }
    'Path' {
      $ParentDir = Split-Path $Path -Parent
      if ([string]::IsNullOrWhiteSpace($ParentDir) -or $ParentDir -eq '.') {
        # Target is just a filename or relative path, use current directory
        return (Get-Location).Path
      }
      elseif (-not [System.IO.Path]::IsPathRooted($ParentDir)) {
        # Relative path, resolve against current directory
        return (Resolve-Path $ParentDir -ErrorAction SilentlyContinue).Path ?? (Join-Path (Get-Location).Path $ParentDir)
      }
      else {
        # Absolute path
        return $ParentDir
      }
    }
    default {
      # Directory type - resolve relative paths
      if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
      }
      else {
        # Relative path, resolve against current directory
        return (Resolve-Path $Path -ErrorAction SilentlyContinue).Path ?? (Join-Path (Get-Location).Path $Path)
      }
    }
  }
}
