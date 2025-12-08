#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Dump all text-based files from a project into dump.txt, optionally generate a tree.txt,
  and copy the dump to the clipboard (cross-platform).

.DESCRIPTION
  This script recursively scans a project directory and concatenates all non-ignored files into
  a single UTF-8 (no BOM) file with metadata headers. It automatically detects the project root,
  respects ignore directories, optionally respects .gitignore / .ignore patterns, and generates
  a full directory tree by default (skip with -NoTree).

  Clipboard behavior:
    - Windows: Set-Clipboard
    - macOS: pbcopy
    - Linux: wl-copy, xsel (if installed)

.PARAMETER SourceFolder
  Optional relative path under the project root to restrict scanning.

.PARAMETER OutputFolder
  Override for the output directory. If not given:
    1) PROJECT_CACHE (PowerShell variable)
    2) PROJECT_TMP (PowerShell variable)
    3) <HOSTNAME>_CACHE (PowerShell variable)
    4) <ProjectRoot>/tmp

.PARAMETER UserIgnoreDirs
  Additional directory names (not paths) to ignore.

.PARAMETER HonorIgnoreFiles
  Explicitly enable honoring .gitignore / .ignore files.

.PARAMETER NoHonorIgnoreFiles
  Explicitly disable honoring ignore files.

.PARAMETER NoTree
  If set, the tree output will be skipped.

.EXAMPLE
  ./dump.ps1

.EXAMPLE
  ./dump.ps1 -SourceFolder src -NoHonorIgnoreFiles -NoTree

#>

param(
  [string]$SourceFolder = $null,
  [string]$OutputFolder = $null,
  [string[]]$UserIgnoreDirs = @(),
  [switch]$HonorIgnoreFiles,
  [switch]$NoHonorIgnoreFiles,
  [switch]$NoTree
)

# -----------------------------
# Determine project root
# -----------------------------
$ProjectRoot = $env:ZED_PROJECT_ROOT
if (-not $ProjectRoot) { $ProjectRoot = (Get-Location).Path }
$ProjectRoot = $ProjectRoot.TrimEnd('\','/')

# -----------------------------
# Determine folder to scan
# -----------------------------
if ($SourceFolder) {
  $ScanRoot = Join-Path $ProjectRoot $SourceFolder
  if (-not (Test-Path $ScanRoot)) {
    Write-Error "Specified folder '$SourceFolder' does not exist under project root '$ProjectRoot'"
    exit 1
  }
} else {
  $ScanRoot = $ProjectRoot
}
$ScanRoot = $ScanRoot.TrimEnd('\','/')

# -----------------------------
# Determine output folder
# -----------------------------
$Hostname        = (hostname).ToUpper()
$HostCacheVar    = "${Hostname}_CACHE"
$ProjectCacheVar = "PROJECT_CACHE"
$ProjectTmpVar   = "PROJECT_TMP"

function Get-IfVariableExists {
  param([string]$VarName)
  $var = Get-Variable -Name $VarName -ErrorAction SilentlyContinue
  if ($var) { return $var.Value }
  return $null
}

$OutputDir =
  if ($OutputFolder) { $OutputFolder }
  elseif ($val = Get-IfVariableExists $ProjectCacheVar) { $val }
  elseif ($val = Get-IfVariableExists $ProjectTmpVar)   { $val }
  elseif ($val = Get-IfVariableExists $HostCacheVar)    { $val }
  else { Join-Path $ProjectRoot "tmp" }

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
$OutFile = Join-Path $OutputDir 'dump.txt'

# -----------------------------
# Ignore configuration
# -----------------------------
$DefaultIgnoreDirs = @('.git','node_modules','target','.zed','review','archive')
$AllIgnoreDirs     = $DefaultIgnoreDirs + $UserIgnoreDirs
$IgnorePaths       = $AllIgnoreDirs | ForEach-Object { Join-Path $ScanRoot $_ }

$UseIgnoreFiles =
  if ($NoHonorIgnoreFiles) { $false }
  elseif ($HonorIgnoreFiles) { $true }
  else { $true }  # Default ON

$IgnoreFilePatterns = @()
if ($UseIgnoreFiles) {
  $ignoreFiles = @(".gitignore", ".ignore") |
    ForEach-Object { Join-Path $ScanRoot $_ } |
    Where-Object { Test-Path $_ }

  foreach ($file in $ignoreFiles) {
    $lines = Get-Content $file | Where-Object { $_ -and -not $_.StartsWith("#") }
    $IgnoreFilePatterns += $lines
  }
}

# Convert ignore patterns to regex
function Pattern-ToRegex {
  param([string]$Pattern)
  $escaped = [Regex]::Escape($Pattern).Replace("\*", ".*").Replace("\?", ".")
  if ($Pattern.StartsWith("/")) { return "^" + $escaped.TrimStart("\/") + "$" }
  else { return ".*" + $escaped + "$" }
}
$IgnoreRegexes = $IgnoreFilePatterns | ForEach-Object { Pattern-ToRegex $_ }

function IsIgnoredByPattern {
  param([string]$RelativePath)
  foreach ($regex in $IgnoreRegexes) { if ($RelativePath -match $regex) { return $true } }
  return $false
}

function IsIgnored {
    param([string]$Path)

    $full = [IO.Path]::GetFullPath($Path)

    foreach ($ignoreDir in $IgnorePaths) {
        $ignoreFull = [IO.Path]::GetFullPath($ignoreDir)
        if ($full -eq $ignoreFull -or $full.StartsWith($ignoreFull + [IO.Path]::DirectorySeparatorChar)) {
            return $true
        }
    }

    if ($UseIgnoreFiles) {
        $rel = [System.IO.Path]::GetRelativePath($ScanRoot, $Path)
        if (IsIgnoredByPattern $rel) { return $true }
    }

    return $false
}

# -----------------------------
# Collect valid files
# -----------------------------
$Files = Get-ChildItem -Path $ScanRoot -Recurse -File |
  Where-Object { -not (IsIgnored $_.FullName) } |
  Sort-Object FullName

# -----------------------------
# Write dump (UTF-8 no BOM)
# -----------------------------
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$writer    = [IO.StreamWriter]::new($OutFile, $false, $Utf8NoBom)
try {
  $writer.WriteLine("|=== BASE: ${ScanRoot}")
  foreach ($f in $Files) {
    $rel      = [System.IO.Path]::GetRelativePath($ScanRoot, $f.FullName)
    $size     = $f.Length
    $modified = $f.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    try { $content = [IO.File]::ReadAllText($f.FullName) }
    catch { $content = "<unable to read file: $($_.Exception.Message)>" }

    $writer.WriteLine("|===")
    $writer.WriteLine("| PATH: ${rel}")
    $writer.WriteLine("| SIZE: $size bytes")
    $writer.WriteLine("| DATE: $modified")
    $writer.WriteLine("|===")
    $writer.WriteLine($content)
    $writer.WriteLine("|=== EOF")
    $writer.WriteLine()
  }
} finally { $writer.Dispose() }

# -----------------------------
# Clipboard copy
# -----------------------------
if (Test-Path $OutFile) {
  $clipboardCopied = $false
  try {
    if ($IsWindows) { Get-Content -Path $OutFile -Raw | Set-Clipboard; $clipboardCopied=$true }
    elseif ($PSVersionTable.OS -match 'Darwin') { Get-Content -Path $OutFile -Raw | pbcopy; $clipboardCopied=$true }
    else {
      if (Get-Command wl-copy -ErrorAction SilentlyContinue) { Get-Content -Path $OutFile -Raw | wl-copy; $clipboardCopied=$true }
      elseif (Get-Command xsel -ErrorAction SilentlyContinue) { Get-Content -Path $OutFile -Raw | xsel --clipboard --input; $clipboardCopied=$true }
      else { Write-Warning "No clipboard utility found. Install wl-copy (Wayland) or xsel (X11)." }
    }
    if ($clipboardCopied) { Write-Host "Copied the content dump of $($Files.Count) file(s) to clipboard!" }
  } catch { Write-Warning "Clipboard copy failed: $($_.Exception.Message)" }
  Write-Host "|=== BASE: ${ScanRoot}"
  Write-Host "|=== DUMP: ${OutFile}"
} else { Write-Warning "Dump file not found; cannot copy to clipboard." }

# -----------------------------
# Tree output (default on)
# -----------------------------
if (-not $NoTree) {

  function Build-Tree {
      param(
          [string]$BasePath,
          [string]$Prefix = "",
          [ref]$FileCount,
          [ref]$FolderCount,
          [int]$Depth = 0,
          [ref]$MaxDepth
      )

      if ($Depth -gt $MaxDepth.Value) { $MaxDepth.Value = $Depth }

      $BasePathFull = [IO.Path]::GetFullPath($BasePath)

      # Only include entries that are NOT ignored
      $entries = Get-ChildItem -Path $BasePath -Force |
                 Where-Object { -not (IsIgnored $_.FullName) } |
                 Sort-Object Name

      $lines = @()
      $count = $entries.Count
      $i = 0

      foreach ($e in $entries) {
          $i++
          $isLast = ($i -eq $count)
          $connector  = if ($isLast) { "└── " } else { "├── " }
          $nextPrefix = if ($isLast) { "$Prefix    " } else { "$Prefix│   " }

          if ($e.PSIsContainer) {
              $lines += "$Prefix$connector$($e.Name)/"
              $FolderCount.Value++
              $lines += Build-Tree -BasePath $e.FullName `
                                    -Prefix $nextPrefix `
                                    -FileCount $FileCount `
                                    -FolderCount $FolderCount `
                                    -Depth ($Depth + 1) `
                                    -MaxDepth $MaxDepth
          }
          else {
              $lines += "$Prefix$connector$($e.Name)"
              $FileCount.Value++
          }
      }

      return $lines
  }


  $TreeFile   = Join-Path $OutputDir "tree.txt"
  $treeWriter = [IO.StreamWriter]::new($TreeFile, $false, $Utf8NoBom)
  try {
    $fileCount   = [ref]0
    $folderCount = [ref]0
    $maxDepth    = [ref]0

    $treeData = Build-Tree -BasePath $ScanRoot -FileCount $fileCount -FolderCount $folderCount -MaxDepth $maxDepth

    # Write metadata
    $treeWriter.WriteLine("TREE: $ScanRoot")
    $treeWriter.WriteLine("Files: $($fileCount.Value), Folders: $($folderCount.Value), Max Depth: $($maxDepth.Value)")
    $treeWriter.WriteLine("")
    foreach ($line in $treeData) { $treeWriter.WriteLine($line) }
  } finally { $treeWriter.Dispose() }

  Write-Host "|=== TREE: $TreeFile"
}