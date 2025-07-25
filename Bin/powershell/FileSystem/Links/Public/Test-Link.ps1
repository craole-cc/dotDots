function Test-Link {
  <#
    .SYNOPSIS
    Tests if a path is a symbolic or hard link and returns link information.

    .DESCRIPTION
    This function checks if the specified path is a symbolic link, hard link, or regular file/directory.
    Returns detailed information about the link type, target, and validity.

    .PARAMETER Path
    The path to test. Can be a file or directory path.

    .PARAMETER Quiet
    When specified, suppresses all output and only returns the result object.

    .OUTPUTS
    Returns a PSCustomObject with the following properties:
    - IsLink: Boolean indicating if the path is any type of link
    - LinkType: 'SymbolicLink', 'HardLink', 'Junction', or 'None'
    - Path: The original path that was tested
    - Target: The target path(s) the link points to
    - TargetExists: Boolean indicating if the target exists
    - IsValid: Boolean indicating if the link is valid (target exists)
    - Item: The original file system item object

    .EXAMPLE
    Test-Link -Path "C:\data\mylink.csv"
    Tests if the specified file is a link and displays the results with colored output.

    .EXAMPLE
    $linkInfo = Test-Link -Path "C:\data\mylink.csv" -Quiet
    if ($linkInfo.IsLink) { Write-Host "This is a $($linkInfo.LinkType)" }
    Tests a path quietly and uses the returned information object for conditional logic.
    #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias('FullName', 'FilePath')]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
  )

  process {
    # Initialize result object
    $result = [PSCustomObject]@{
      IsLink       = $false
      LinkType     = 'None'
      Path         = $Path
      Target       = $null
      TargetExists = $false
      IsValid      = $false
      Item         = $null
    }

    # Check if path exists
    if (-not (Test-Path $Path)) {
      if (-not $Quiet) {
        Write-Warning "Path does not exist: $Path"
      }
      return $result
    }

    try {
      # Get the item with -Force to ensure we get hidden/system files
      $item = Get-Item $Path -Force -ErrorAction Stop
      $result.Item = $item

      # Check the LinkType property
      switch ($item.LinkType) {
        'SymbolicLink' {
          $result.IsLink = $true
          $result.LinkType = 'SymbolicLink'
          $result.Target = $item.Target

          # Handle array of targets (though usually just one for files)
          $targetPath = if ($item.Target -is [array]) { $item.Target[0] } else { $item.Target }

          # Check if target exists
          if ($targetPath) {
            $result.TargetExists = Test-Path $targetPath
            $result.IsValid = $result.TargetExists
          }

          if (-not $Quiet) {
            $status = if ($result.IsValid) { '✓' } else { '✗' }
            $existsText = if ($result.TargetExists) { 'exists' } else { 'missing' }
            Write-Host "$status Symbolic Link: $Path -> $targetPath ($existsText)" -ForegroundColor $(if ($result.IsValid) { 'Green' } else { 'Red' })
          }
        }

        'HardLink' {
          $result.IsLink = $true
          $result.LinkType = 'HardLink'

          # For hard links, the target is more complex to determine
          # We'll use the same path as it's essentially the same file
          $result.Target = $Path
          $result.TargetExists = $true  # Hard links always "exist" if the link exists
          $result.IsValid = $true

          if (-not $Quiet) {
            # Try to get additional hard link information
            try {
              $hardLinkCount = (Get-Item $Path -Force).LinkCount
              Write-Host "✓ Hard Link: $Path (Link count: $hardLinkCount)" -ForegroundColor Green
            }
            catch {
              Write-Host "✓ Hard Link: $Path" -ForegroundColor Green
            }
          }
        }

        'Junction' {
          $result.IsLink = $true
          $result.LinkType = 'Junction'
          $result.Target = $item.Target

          $targetPath = if ($item.Target -is [array]) { $item.Target[0] } else { $item.Target }

          if ($targetPath) {
            $result.TargetExists = Test-Path $targetPath
            $result.IsValid = $result.TargetExists
          }

          if (-not $Quiet) {
            $status = if ($result.IsValid) { '✓' } else { '✗' }
            $existsText = if ($result.TargetExists) { 'exists' } else { 'missing' }
            Write-Host "$status Junction: $Path -> $targetPath ($existsText)" -ForegroundColor $(if ($result.IsValid) { 'Green' } else { 'Red' })
          }
        }

        default {
          # Regular file or directory
          $result.IsLink = $false
          $result.LinkType = 'None'
          $result.Target = $null
          $result.TargetExists = $true  # The item itself exists
          $result.IsValid = $true

          if (-not $Quiet) {
            $itemType = if ($item.PSIsContainer) { 'Directory' } else { 'File' }
            Write-Host "○ Regular $itemType`: $Path" -ForegroundColor Gray
          }
        }
      }
    }
    catch {
      if (-not $Quiet) {
        Write-Error "Error examining path: $Path. Error: $($_.Exception.Message)"
      }
    }

    return $result
  }
}
