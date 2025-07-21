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
function Test-PathFormatting {
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
        Write-Host ""
    }
}

# Advanced path resolution with optional creation
function Global:Get-SafeResolvedPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [string]$Target,

        [switch]$CreateIfMissing,

        [switch]$Force,

        [switch]$Yes,

        [ValidateSet('File', 'Directory', 'Symlink', 'Auto')]
        [string]$ItemType = 'Auto'
    )

    try {
        # First try to resolve the path if it exists
        if (Test-Path -Path $Path) {
            $resolved = Resolve-Path -Path $Path -ErrorAction Stop
            return Format-PathSafe -Path $resolved.Path
        }

        # Path doesn't exist, get the absolute path anyway
        $absolute = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

        # If not asked to create, just return the formatted absolute path
        if (-not $CreateIfMissing) {
            return Format-PathSafe -Path $absolute
        }

        # Determine what type of item to create
        $createType = $ItemType
        if ($createType -eq 'Auto') {
            # Auto-detect based on whether path has an extension
            $createType = if ([System.IO.Path]::HasExtension($absolute)) { 'File' } else { 'Directory' }
        }

        # For symlinks, we need a target
        if ($createType -eq 'Symlink' -and -not $Target) {
            Write-Error "Target parameter is required when ItemType is 'Symlink'"
            return $null
        }

        # Check if we should prompt or auto-create
        $shouldCreate = $Force -or $Yes

        if (-not $shouldCreate) {
            $promptText = if ($createType -eq 'File') {
                "Path '$absolute' does not exist. Create file? (y/N)"
            } elseif ($createType -eq 'Directory') {
                "Path '$absolute' does not exist. Create directory? (y/N)"
            } else {
                "Path '$absolute' does not exist. Create symlink to '$Target'? (y/N)"
            }
            $response = Read-Host $promptText
            $shouldCreate = $response -match '^[Yy]'
        }

        if ($shouldCreate) {
            if ($createType -eq 'File') {
                # Create the directory first if it doesn't exist
                $parentDir = Split-Path -Path $absolute -Parent
                if (-not (Test-Path -Path $parentDir)) {
                    Write-Verbose "Creating parent directory: $parentDir"
                    New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
                }

                # Create empty file
                Write-Verbose "Creating file: $absolute"
                New-Item -Path $absolute -ItemType File -Force | Out-Null
            }
            elseif ($createType -eq 'Directory') {
                # Create directory
                Write-Verbose "Creating directory: $absolute"
                New-Item -Path $absolute -ItemType Directory -Force | Out-Null
            }
            elseif ($createType -eq 'Symlink') {
                # Create symlink using OS-specific commands for reliability
                Write-Verbose "Creating symlink: $absolute -> $Target"

                $parentDir = Split-Path -Path $absolute -Parent
                if (-not (Test-Path -Path $parentDir)) {
                    Write-Verbose "Creating parent directory: $parentDir"
                    New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
                }

                if ($IsWindows -or ($PSVersionTable.PSVersion.Major -le 5)) {
                    # Windows - use mklink via cmd
                    $linkName = Split-Path -Path $absolute -Leaf
                    $parentPath = Split-Path -Path $absolute -Parent

                    # Determine if target is directory or file for mklink flags
                    $isTargetDir = if (Test-Path -Path $Target) {
                        (Get-Item -Path $Target).PSIsContainer
                    } else {
                        # If target doesn't exist, guess based on extension
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
                    $result = & ln -sf $Target $absolute 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "ln failed: $result"
                    }
                }
            }

            # Now resolve the newly created path
            $resolved = Resolve-Path -Path $absolute -ErrorAction Stop
            return Format-PathSafe -Path $resolved.Path
        }
        else {
            # User chose not to create, return the unresolved but formatted path
            return Format-PathSafe -Path $absolute
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
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [ValidateSet('File', 'Directory', 'Symlink', 'Auto')]
        [string]$ItemType = 'Auto',

        [switch]$Force,
        [switch]$Yes
    )
    # Auto-detect if it's a config file or directory based on extension, unless overridden
    Get-SafeResolvedPath -Path $Path -CreateIfMissing -ItemType $ItemType -Force:$Force -Yes:$Yes
}

function Global:Get-SafeFilePath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [switch]$Force,
        [switch]$Yes
    )
    Get-SafeResolvedPath -Path $Path -CreateIfMissing -ItemType File -Force:$Force -Yes:$Yes
}

function Global:Get-SafeDirectoryPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [switch]$Force,
        [switch]$Yes
    )
    Get-SafeResolvedPath -Path $Path -CreateIfMissing -ItemType Directory -Force:$Force -Yes:$Yes
}

function Global:New-SafeSymlink {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$Target,

        [switch]$Force,
        [switch]$Yes
    )
    Get-SafeResolvedPath -Path $Path -Target $Target -CreateIfMissing -ItemType Symlink -Force:$Force -Yes:$Yes
}

# Example usage function
function Test-PathResolution {
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
        $result1 = Get-SafeResolvedPath -Path $path
        Write-Host "  No create: $result1"

        # Test what auto-detection would choose
        $absolute = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
        $hasExtension = [System.IO.Path]::HasExtension($absolute)
        $autoType = if ($hasExtension) { 'File' } else { 'Directory' }
        Write-Host "  Auto-detect: $autoType"
        Write-Host ""
    }
}
