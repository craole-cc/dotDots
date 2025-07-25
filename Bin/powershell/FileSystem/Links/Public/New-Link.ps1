function New-Link {
  <#
    .SYNOPSIS
    Creates links from source files to a target directory.

    .DESCRIPTION
    This function creates symbolic or hard links for specified file types from source paths (files or directories)
    to a target directory. It supports filtering by file extensions and handles existing files with
    optional prompting for overwrites.

    .PARAMETER Target
    The target directory where links will be created. Directory will be created if it doesn't exist.
    When TargetType is 'Path', this should be the full path including filename for the link.

    .PARAMETER Source
    One or more source paths. Can be individual files or directories. When directories are specified,
    files matching the FileTypes parameter will be linked.

    .PARAMETER TargetType
    Specifies how to interpret the Target parameter:
    - 'Directory': Target is a directory path (default)
    - 'Home': Use the user's home directory as target
    - 'Path': Target includes the filename for single file operations

    .PARAMETER FileTypes
    Array of file extensions to process when Source contains directories. Default is @('.csv', '.tsv').
    Include the dot in the extension (e.g., '.csv', '.txt').

    .PARAMETER Type
    Type of link to create: 'Symbolic' (default) or 'Hard'.

    .PARAMETER Force
    When specified, overwrites existing files and links without prompting.

    .PARAMETER Warn
    Warn if the source of a link does not currently exist.

    .PARAMETER Recurse
    When processing directories, include subdirectories recursively.

    .EXAMPLE
    New-Link -Target "C:\neo4j\import" -Source "C:\data\users.csv"
    Creates a symbolic link for a single file.

    .EXAMPLE
    New-Link -Target "C:\config\mise.toml" -Source "C:\path\to\config.toml" -TargetType Path
    Creates a symbolic link with a custom name: mise.toml -> C:\path\to\config.toml

    .EXAMPLE
    New-Link -Target "C:\neo4j\import" -Source "C:\data\csv-files" -Force
    Creates symbolic links for all CSV and TSV files in the directory.
    #>

  [CmdletBinding(DefaultParameterSetName = 'Standard')]
  param(
    [Parameter(Mandatory = $true)]
    [Alias('Link', 'L', 'Destination')]
    [string]$Target,

    [Parameter(Mandatory = $true)]
    [Alias('S')]
    [string[]]$Source,

    [Parameter(Mandatory = $false)]
    [Alias('TargetDir', 'TD')]
    [ValidateSet('Home', 'Directory', 'Path')]
    [string]$TargetType = 'Directory',

    [Parameter(Mandatory = $false)]
    [string[]]$FileTypes = @(
      '.bash',
      '.bat',
      '.cfg',
      '.cmd',
      '.conf',
      '.csv',
      '.exe',
      '.ini',
      '.jar',
      '.js',
      '.json',
      '.md',
      '.properties',
      '.ps1',
      '.ps1xml',
      '.psm1',
      '.psm1xml',
      '.py',
      '.sh',
      '.sql',
      '.toml',
      '.tsv',
      '.txt',
      '.xml',
      '.yaml',
      '.yml'
    ),

    [Parameter(Mandatory = $false)]
    [ValidateSet('Hard', 'Symbolic')]
    [string]$Type = 'Symbolic',

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$Warn,

    [Parameter(Mandatory = $false)]
    [switch]$Recurse,

    # Legacy parameter support for backward compatibility
    [Parameter(Mandatory = $false, ParameterSetName = 'Legacy')]
    [Alias('n')]
    [switch]$Name,

    [Parameter(Mandatory = $false, ParameterSetName = 'Legacy')]
    [Alias('d')]
    [switch]$Directory,

    [Parameter(Mandatory = $false, ParameterSetName = 'Legacy')]
    [Alias('h')]
    [switch]$Home,

    [Parameter(Mandatory = $false, ParameterSetName = 'Legacy')]
    [switch]$Symbolic,

    [Parameter(Mandatory = $false, ParameterSetName = 'Legacy')]
    [switch]$Hard
  )

  # Handle legacy parameters for backward compatibility
  if ($PSCmdlet.ParameterSetName -eq 'Legacy') {
    if ($Hard) { $Type = 'Hard' }
    elseif ($Symbolic) { $Type = 'Symbolic' }

    if ($Home) { $TargetType = 'Home' }
    elseif ($Directory) { $TargetType = 'Directory' }
  }

  # Validate source count for Path target type
  if ($TargetType -eq 'Path' -and $Source.Count -gt 1) {
    Write-Error "When TargetType is 'Path', only one source file can be specified."
    return
  }

  # Resolve and validate target directory
  $TargetDir = Resolve-TargetPath -Path $Target -Type $TargetType

  # Create target directory if it doesn't exist
  if (-not (Test-Path $TargetDir)) {
    try {
      New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
      Write-Host "Created target directory: $TargetDir" -ForegroundColor Green
    }
    catch {
      Write-Error "Failed to create target directory: $TargetDir. Error: $($_.Exception.Message)"
      return
    }
  }
  elseif (-not (Test-Path $TargetDir -PathType Container)) {
    Write-Error "Target path exists but is not a directory: $TargetDir"
    return
  }

  # Collect all files to process
  $AllFiles = @()
  $ProcessedSourceCount = 0

  foreach ($SourcePath in $Source) {
    # Resolve relative paths
    try {
      $ResolvedSourcePath = Resolve-Path $SourcePath -ErrorAction Stop
      $SourcePath = $ResolvedSourcePath.Path
    }
    catch {
      Write-Warning "Source path does not exist: $SourcePath"
      continue
    }

    if (Test-Path $SourcePath -PathType Container) {
      # Source is a directory - find files matching FileTypes
      $FoundFiles = @()
      foreach ($FileType in $FileTypes) {
        $SearchPath = if ($Recurse) {
          Get-ChildItem -Path $SourcePath -Filter "*$FileType" -File -Recurse
        }
        else {
          Get-ChildItem -Path $SourcePath -Filter "*$FileType" -File
        }
        $FoundFiles += $SearchPath
      }

      if ($FoundFiles.Count -eq 0) {
        $RecurseText = if ($Recurse) { ' (including subdirectories)' } else { '' }
        Write-Warning "No files matching types [$($FileTypes -join ', ')] found in directory: $SourcePath$RecurseText"
        continue
      }

      $RecurseText = if ($Recurse) { ' (including subdirectories)' } else { '' }
      Write-Host "Found $($FoundFiles.Count) files in directory: $SourcePath$RecurseText" -ForegroundColor Cyan
      $AllFiles += $FoundFiles
      $ProcessedSourceCount++
    }
    else {
      # Source is a file
      $SourceFile = Get-Item $SourcePath

      # Check if it matches the specified file types (only warn, don't skip)
      if ($SourceFile.Extension -notin $FileTypes) {
        Write-Warning "File does not match specified types [$($FileTypes -join ', ')]: $($SourceFile.Name) (Extension: $($SourceFile.Extension))"
      }

      $AllFiles += $SourceFile
      $ProcessedSourceCount++
    }
  }

  if ($AllFiles.Count -eq 0) {
    Write-Warning "No files to process from $($Source.Count) source path(s)"
    return
  }

  Write-Host "Processing $($AllFiles.Count) files from $ProcessedSourceCount source path(s)..." -ForegroundColor Yellow

  # Create links for all collected files
  $SuccessCount = 0
  $FailureCount = 0
  $SkippedCount = 0

  foreach ($File in $AllFiles) {
    $SourceFilePath = $File.FullName

    # Determine target file path
    $TargetFilePath = if ($TargetType -eq 'Path') {
      # When TargetType is 'Path', Target contains the full path including the desired filename
      $Target
    }
    else {
      # For Directory and Home types, use the original filename
      Join-Path $TargetDir $File.Name
    }

    # Warn if source doesn't exist (for symbolic links)
    if ($Warn -and $Type -eq 'Symbolic' -and -not (Test-Path $SourceFilePath)) {
      Write-Warning "Source file does not exist: $SourceFilePath"
    }

    # Check if target already exists
    if (Test-Path $TargetFilePath) {
      $ExistingItem = Get-Item $TargetFilePath -Force

      # Check if it's already correctly linked
      if (Test-CorrectLink -TargetPath $TargetFilePath -ExpectedSourcePath $SourceFilePath -LinkType $Type) {
        Write-Host "○ Already linked correctly: $($File.Name)" -ForegroundColor Gray
        $SkippedCount++
        continue
      }

      # Need to handle existing file/link
      if (-not $Force) {
        $ItemType = switch ($ExistingItem.LinkType) {
          'SymbolicLink' { 'symbolic link' }
          'HardLink' { 'hard link' }
          default { 'file' }
        }

        $CurrentTarget = if ($ExistingItem.LinkType -in @('SymbolicLink', 'HardLink')) {
          " -> $($ExistingItem.Target)"
        }
        else {
          ''
        }

        $Choice = Read-Host "Target $ItemType already exists: $($File.Name)$CurrentTarget`nOverwrite? (y/N)"
        if ($Choice -notmatch '^[Yy]') {
          Write-Host "- Skipped: $($File.Name)" -ForegroundColor Yellow
          $SkippedCount++
          continue
        }
      }

      # Remove existing item
      try {
        Remove-Item $TargetFilePath -Force
        $ItemType = switch ($ExistingItem.LinkType) {
          'SymbolicLink' { 'symbolic link' }
          'HardLink' { 'hard link' }
          default { 'file' }
        }
        Write-Verbose "Removed existing $ItemType`: $($File.Name)"
      }
      catch {
        Write-Error "Failed to remove existing item: $($File.Name). Error: $($_.Exception.Message)"
        $FailureCount++
        continue
      }
    }

    # Create link
    try {
      if ($Type -eq 'Symbolic') {
        # Create symbolic link using New-Item (PowerShell 5.0+) with fallback to mklink
        try {
          New-Item -ItemType SymbolicLink -Path $TargetFilePath -Target $SourceFilePath -Force | Out-Null
          Write-Host "✓ Symbolic link created: $($File.Name)" -ForegroundColor Green
          $SuccessCount++
        }
        catch {
          # Fallback to cmd mklink for older PowerShell versions
          $MklinkResult = cmd /c "mklink `"$TargetFilePath`" `"$SourceFilePath`" 2>&1"
          if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Symbolic link created: $($File.Name)" -ForegroundColor Green
            $SuccessCount++
          }
          else {
            throw "mklink failed: $MklinkResult"
          }
        }
      }
      else {
        # Create hard link
        try {
          New-Item -ItemType HardLink -Path $TargetFilePath -Target $SourceFilePath -Force | Out-Null
          Write-Host "✓ Hard link created: $($File.Name)" -ForegroundColor Green
          $SuccessCount++
        }
        catch {
          # Fallback to fsutil for hard links
          $FsutilResult = cmd /c "fsutil hardlink create `"$TargetFilePath`" `"$SourceFilePath`" 2>&1"
          if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Hard link created: $($File.Name)" -ForegroundColor Green
            $SuccessCount++
          }
          else {
            throw "fsutil hardlink failed: $FsutilResult"
          }
        }
      }
    }
    catch {
      Write-Error "Error creating $($Type.ToLower()) link for $($File.Name): $($_.Exception.Message)"
      $FailureCount++
    }
  }

  # Summary
  Write-Host "`nOperation completed:" -ForegroundColor Yellow
  Write-Host "  Successfully linked: $SuccessCount files" -ForegroundColor Green
  if ($SkippedCount -gt 0) {
    Write-Host "  Already correct/Skipped: $SkippedCount files" -ForegroundColor Gray
  }
  if ($FailureCount -gt 0) {
    Write-Host "  Failed to link: $FailureCount files" -ForegroundColor Red
  }
  Write-Host "  Target directory: $TargetDir" -ForegroundColor Cyan
  Write-Host "  Link type: $Type" -ForegroundColor Cyan

  # Return summary object for potential scripting use
  return [PSCustomObject]@{
    SuccessCount    = $SuccessCount
    FailureCount    = $FailureCount
    SkippedCount    = $SkippedCount
    TotalProcessed  = $AllFiles.Count
    TargetDirectory = $TargetDir
    LinkType        = $Type
  }
}
