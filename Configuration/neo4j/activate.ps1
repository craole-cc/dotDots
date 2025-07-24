function Global:Install-SymbolicLink {

  param(
    [Parameter(Mandatory = $true)]
    [string]$Neo4jInstancePath,

    [Parameter(Mandatory = $true)]
    [string]$SourceDataPath
  )

  # Validate Neo4j instance path exists
  if (-not (Test-Path $Neo4jInstancePath)) {
    Write-Error "Neo4j instance path does not exist: $Neo4jInstancePath"
    exit 1
  }

  # Create import directory if it doesn't exist
  $ImportPath = Join-Path $Neo4jInstancePath 'import'
  if (-not (Test-Path $ImportPath)) {
    New-Item -ItemType Directory -Path $ImportPath -Force | Out-Null
    Write-Host "Created import directory: $ImportPath"
  }

  # Check if source path exists
  if (-not (Test-Path $SourceDataPath)) {
    Write-Error "Source data path does not exist: $SourceDataPath"
    exit 1
  }

  # Handle directory vs file
  if (Test-Path $SourceDataPath -PathType Container) {
    # Source is a directory - find CSV and TSV files
    $CsvTsvFiles = Get-ChildItem -Path $SourceDataPath -Filter '*.csv' -File
    $CsvTsvFiles += Get-ChildItem -Path $SourceDataPath -Filter '*.tsv' -File

    if ($CsvTsvFiles.Count -eq 0) {
      Write-Warning "No CSV or TSV files found in source directory: $SourceDataPath"
      exit 0
    }

    Write-Host "Found $($CsvTsvFiles.Count) CSV/TSV files to link"

    foreach ($File in $CsvTsvFiles) {
      $SourceFile = $File.FullName
      $TargetFile = Join-Path $ImportPath $File.Name

      # Remove existing link/file if it exists
      if (Test-Path $TargetFile) {
        Remove-Item $TargetFile -Force
      }

      try {
        # Create symbolic link using cmd /c mklink
        $Result = cmd /c "mklink `"$TargetFile`" `"$SourceFile`""
        if ($LASTEXITCODE -eq 0) {
          Write-Host "✓ Linked: $($File.Name)"
        }
        else {
          Write-Error "Failed to create symbolic link for: $($File.Name)"
        }
      }
      catch {
        Write-Error "Error creating symbolic link for $($File.Name): $($_.Exception.Message)"
      }
    }
  }
  else {
    # Source is a file
    $SourceFile = Get-Item $SourceDataPath

    # Check if it's a CSV or TSV file
    if ($SourceFile.Extension -notin @('.csv', '.tsv')) {
      Write-Warning "Source file is not a CSV or TSV file: $($SourceFile.Extension)"
    }

    $TargetFile = Join-Path $ImportPath $SourceFile.Name

    # Remove existing link/file if it exists
    if (Test-Path $TargetFile) {
      Remove-Item $TargetFile -Force
    }

    try {
      # Create symbolic link using cmd /c mklink
      $Result = cmd /c "mklink `"$TargetFile`" `"$SourceFile`""
      if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Linked: $($SourceFile.Name)"
      }
      else {
        Write-Error "Failed to create symbolic link for: $($SourceFile.Name)"
      }
    }
    catch {
      Write-Error "Error creating symbolic link: $($_.Exception.Message)"
    }
  }

  Write-Host "Operation completed. Files are now available in: $ImportPath"

}
