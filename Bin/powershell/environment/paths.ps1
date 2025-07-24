# Method 1: Using quotes (simplest and most reliable)
function Global:Format-WindowsPathQuoted {
  param([string]$Path)
  # Escape internal quotes, then wrap in double quotes
  $escaped = $Path -replace '"', '`"'
  return "`"$escaped`""
}

# Method 2: Alternative escaping method
function Global:Format-WindowsPathEscaped {
  param([string]$Path)
  # Escape quotes and backticks, then wrap in quotes
  $escaped = $Path -replace '`', '``' -replace '"', '`"'
  return "`"$escaped`""
}

# Method 3: Manual escaping (if you need fine control)
function Global:Format-WindowsPathManual {
  param([string]$Path)
  # Escape double quotes and backticks, then wrap in quotes
  $escaped = $Path -replace '"', '`"' -replace '`', '``'
  return "`"$escaped`""
}

# Method 4: For use with external processes (cmd.exe style)
function Global:Format-WindowsPathForCmd {
  param([string]$Path)
  # For passing to cmd.exe or external executables
  if ($Path -match '[ &()^!"]') {
    # Contains special chars, wrap in quotes and escape internal quotes
    $escaped = $Path -replace '"', '""'
    return "`"$escaped`""
  }
  return $Path
}

# Improved cross-platform function
function Global:Format-PathSafe {
  param([string]$Path)

  if ($IsWindows -or ($PSVersionTable.PSVersion.Major -le 5)) {
    # Windows - escape quotes and wrap in quotes
    $escaped = $Path -replace '"', '`"'
    return "`"$escaped`""
  }
  else {
    # Unix-like - escape special characters
    if ($Path -match '[ !#^$%&*?()={}[\]`~|;<>"\\]') {
      # Contains special chars, use single quotes (safest on Unix)
      # To escape single quotes: close quote, add escaped quote, open quote
      $escaped = $Path -replace "'", "'`''"
      return "'$escaped'"
    }
    return $Path
  }
}

# Examples of usage:
function Global:Test-PathFormatting {
  $testPaths = @(
    'C:\Program Files\Test App\file.txt',
    'C:\Users\test user\Documents\file with spaces.txt',
    'C:\path\with"quotes\file.txt',
    'C:\normal\path\file.txt'
  )

  Write-Host "Testing path formatting methods:`n"

  foreach ($path in $testPaths) {
    Write-Host "Original: $path"
    Write-Host "Quoted:   $(Format-WindowsPathQuoted $path)"
    Write-Host "Escaped:  $(Format-WindowsPathEscaped $path)"
    Write-Host "Safe:     $(Format-PathSafe $path)"
    Write-Host ''
  }
}

# Advanced path resolution with optional creation
function Global:Resolve-PathSafely {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [string]$Target,


    [Alias ('SkipMissing', 'DontCreateIfMissing' , 'No')]
    [switch]$NoClobber,

    [Alias ('Create', 'CreateIfMissing' , 'Yes')]
    [switch]$Force,

    [ValidateSet('File', 'Directory', 'Symlink', 'Auto')]
    [string]$ItemType = 'Auto'
  )

  try {
    #~@ First try to resolve the path if it exists
    if (Test-Path -Path $Path) {
      if (Resolve-Path -Path $Path -ErrorAction SilentlyContinue) {
        $resolvedPath = $(Resolve-Path $Path).Path
        if ($resolvedPath -ne $Path) {
          Write-Pretty -Tag 'Trace' -ContextScope Name `
            "Provided: $Path" "Resolved: $resolvedPath"
        }
        return Format-PathSafe -Path $resolvedPath
      }
    }
    else {
      #~@ Get the absolute path despite it being missing
      $unresolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
      if ($unresolvedPath -ne $Path) {
        Write-Pretty -Tag 'Trace' -ContextScope Name `
          "Provided: $Path" "Resolved: $unresolvedPath"
      }
    }
    #~@ If explicitly asked not to create, just return the formatted absolute path
    if ($NoClobber) { return $unresolvedPath }

    #~@ Determine what type of item to create
    $pathType = $ItemType
    if ($pathType -eq 'Auto') {
      #~@ Auto-detect based on whether path has an extension
      $pathType = if (
        [System.IO.Path]::HasExtension($unresolvedPath)
      ) { 'file' } else { 'directory' }

      Write-Pretty -Tag 'Trace' -ContextScope Name -NoNewLine `
        "The provided path string may be for a $pathType"
    }

    #~@ For symlinks, we need a target
    if ($pathType -eq 'Symlink' -and -not $Target) {
      Write-Pretty -Tag 'Error' -ContextScope Name -NoNewLine`
      "Target parameter is required for 'Symlink'"
      return $null
    }

    #~@ Check if we should prompt or auto-create
    $shouldCreate = $Force

    if (-not $shouldCreate) {
      $promptText = @("Missing path: $unresolvedPath`nWould you like to create it as a")
      if ($pathType -eq 'File') {
        $promptText += 'file?'
      }
      elseif ($pathType -eq 'Directory') {
        $promptText += 'directory?'
      }
      else {
        $promptText += "symlink to '$Target'?"
      }
      $promptText += '[y|N]'

      $response = Read-Host $promptText
      $shouldCreate = $response -match '^[Yy]'
    }

    if ($shouldCreate) {
      if ($pathType -eq 'File') {
        #~@ Create the directory first if it doesn't exist
        $parentDir = Split-Path -Path $unresolvedPath -Parent
        if (-not (Test-Path -Path $parentDir)) {
          Write-Verbose "Creating parent directory: $parentDir"
          New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
        }

        #~@ Create empty file
        Write-Verbose "Creating file: $unresolvedPath"
        New-Item -Path $unresolvedPath -ItemType File -Force | Out-Null
      }
      elseif ($pathType -eq 'Directory') {
        #~@ Create directory
        Write-Verbose "Creating directory: $unresolvedPath"
        New-Item -Path $unresolvedPath -ItemType Directory -Force | Out-Null
      }
      elseif ($pathType -eq 'Symlink') {
        #TODO: Check the symlink functionality
        #~@ Create symlink using OS-specific commands for reliability
        Write-Verbose "Creating symlink: $unresolvedPath -> $Target"

        $parentDir = Split-Path -Path $unresolvedPath -Parent
        if (-not (Test-Path -Path $parentDir)) {
          Write-Verbose "Creating parent directory: $parentDir"
          New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
        }

        if (Test-IsWindows -or -not Test-IsPowerShellCore) {
          #~@ Windows - use mklink via cmd
          $linkName = Split-Path -Path $unresolvedPath -Leaf
          $parentPath = Split-Path -Path $unresolvedPath -Parent

          #~@ Determine if target is directory or file for mklink flags
          $isTargetDir = if (Test-Path -Path $Target) {
            (Get-Item -Path $Target).PSIsContainer
          }
          else {
            #~@ If target doesn't exist, guess based on extension
            -not [System.IO.Path]::HasExtension($Target)
          }

          $mklinkArgs = if ($isTargetDir) { "/D `"$linkName`" `"$Target`"" } else { "`"$linkName`" `"$Target`"" }

          Push-Location $parentPath
          try {
            $result = cmd /c "mklink $mklinkArgs" 2>&1
            if ($LASTEXITCODE -ne 0) {
              throw "mklink failed: $result"
            }
          }
          finally {
            Pop-Location
          }
        }
        else {
          # Unix-like - use ln -s
          $result = & ln -sf $Target $unresolvedPath 2>&1
          if ($LASTEXITCODE -ne 0) {
            throw "ln failed: $result"
          }
        }
      }

      # Now resolve the newly created path
      $resolved = Resolve-Path -Path $unresolvedPath -ErrorAction Stop
      return Format-PathSafe -Path $resolved.Path
    }
    else {
      # User chose not to create, return the unresolved but formatted path
      return Format-PathSafe -Path $unresolvedPath
    }
  }
  catch {
    Write-Error "Failed to process path '$Path': $($_.Exception.Message)"
    return $null
  }
}

# Convenience aliases for common scenarios
function Global:Get-SafeConfigPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [ValidateSet('File', 'Directory', 'Symlink', 'Auto')]
    [string]$ItemType = 'Auto',

    [switch]$Force,
    [switch]$Yes
  )
  # Auto-detect if it's a config file or directory based on extension, unless overridden
  Resolve-PathSafely -Path $Path -CreateIfMissing -ItemType $ItemType -Force:$Force -Yes:$Yes
}

function Global:Get-SafeFilePath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [switch]$Force,
    [switch]$Yes
  )
  Resolve-PathSafely -Path $Path -CreateIfMissing -ItemType File -Force:$Force -Yes:$Yes
}

function Global:Get-SafeDirectoryPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [switch]$Force,
    [switch]$Yes
  )
  Resolve-PathSafely -Path $Path -CreateIfMissing -ItemType Directory -Force:$Force -Yes:$Yes
}

function Global:New-Symlink {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string]$Target,

    [switch]$Force,
    [switch]$Yes
  )
  Resolve-PathSafely -Path $Path -Target $Target -CreateIfMissing -ItemType Symlink -Force:$Force -Yes:$Yes
}

# Example usage function
function Global:Test-PathResolution {
  Write-Host "Testing path resolution with creation options:`n"

  $testPaths = @(
    'C:\temp\test-config',
    'C:\temp\test-config\settings.json',
    '.\relative\path\file.txt',
    '~\Documents\MyApp\config'
  )

  foreach ($path in $testPaths) {
    Write-Host "Testing: $path"

    # Test without creation
    $result1 = Resolve-PathSafely -Path $path
    Write-Host "  No create: $result1"

    # Test what auto-detection would choose
    $absolute = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
    $hasExtension = [System.IO.Path]::HasExtension($absolute)
    $autoType = if ($hasExtension) { 'File' } else { 'Directory' }
    Write-Host "  Auto-detect: $autoType"
    Write-Host ''
  }
}
