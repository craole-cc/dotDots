<#
.SYNOPSIS
    Locates and initializes the DOTS environment for PowerShell.
.DESCRIPTION
    This script searches for a DOTS directory (where dotfiles are stored) by looking in specified parent directories,
    checking for target directory names, and validating with marker files. It sets global variables and environment variables
    for the DOTS path and loads the default profile if found.
.NOTES
    File Name      : Profile.ps1
    Author         : Craig 'Craole' Cole
    Prerequisite   : PowerShell 5.1 or later
    Copyright      : (c) Craig 'Craole' Cole, 2025
#>

#Requires -Version 5.1

#region Path Utilities

<#
.SYNOPSIS
    Normalizes a path by converting it to a full path and replacing backslashes with forward slashes.
.DESCRIPTION
    This function takes a path string, resolves it to its full path, and replaces all backslashes with forward slashes for consistency.
.PARAMETER path
    The path to normalize.
.EXAMPLE
    Format-PathPOSIX "C:\Users\Me\Documents"
    Returns: "C:/Users/Me/Documents"
#>
function Global:Format-PathPOSIX {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$path
    )

    try {
        $newPath = [System.IO.Path]::GetFullPath($path)
        #{ Replace backslashes with forward slashes for consistency
        $newPath = $newPath.Replace('\\', '/')
        $newPath = $newPath.Replace('\', '/')
        return $newPath
    }
    catch {
        Write-Error "Failed to normalize path: $_"
        return $null
    }
}

function Global:Resolve-PathPOSIX {
    <#
.SYNOPSIS
Resolves a given file system path and converts it to POSIX (forward slash) format.

.DESCRIPTION
The Resolve-PathPOSIX function takes a file or directory path (or multiple paths), resolves it to its absolute form (handling symlinks and relative paths), and converts the result to POSIX-style by replacing backslashes with forward slashes. It also collapses multiple consecutive slashes, while preserving UNC path prefixes.

This is useful for interoperability with tools or scripts that require POSIX-style paths, such as when working with WSL, cross-platform scripts, or certain development environments.

.PARAMETER Path
The path(s) to resolve and convert. Accepts pipeline input.

.EXAMPLE
Resolve-PathPOSIX -Path '.\Documents\MyFile.txt'

Resolves the relative path to an absolute path and outputs it in POSIX format, e.g.:
C:/Users/YourName/Documents/MyFile.txt

.EXAMPLE
'\\server\share\folder' | Resolve-PathPOSIX

Resolves a UNC path and outputs it in POSIX format, e.g.:
//server/share/folder

.INPUTS
System.String

.OUTPUTS
System.String
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Path
    )

    process {
        try {
            $resolved = Resolve-Path -Path $Path -ErrorAction Stop
            foreach ($item in $resolved) {
                #{ Replace backslashes with forward slashes
                $POSIXpath = $item.Path -replace '\\', '/'

                #{ Handle special UNC paths: preserve double slash at start
                if ($POSIXpath -match '^//') {
                    #{ Collapse slashes after the initial double slash
                    $POSIXpath = ($POSIXpath.Substring(0, 2)) + ($POSIXpath.Substring(2) -replace '/+', '/')
                }
                else {
                    #{ Collapse multiple consecutive slashes elsewhere
                    $POSIXpath = $POSIXpath -replace '([^:]/)/+', '$1'
                }

                return $posixPath
            }
        }
        catch {
            # Throw "Failed to resolve and normalize path: $_"
            Throw "$_"
            return $null
        }
    }
}

#endregion

#region DOTS Manager

<#
.SYNOPSIS
    Locates the DOTS directory by searching parent directories for target folders with marker files.
.DESCRIPTION
    Searches through specified parent directories for target folder names (like '.dots', 'dotfiles', etc.) and checks for the presence
    of marker files (like '.dotsrc', '.git', 'flake.nix') to identify the DOTS directory.
.PARAMETER Parents
    An array of parent directories to search. Defaults to common dotfiles locations.
.PARAMETER Targets
    An array of target directory names to look for within parent directories. Defaults to common dotfiles names.
.PARAMETER Markers
    An array of marker file names used to validate the DOTS directory. Defaults to common marker files.
.EXAMPLE
    Get-DOTS -Parents "D:/Projects/GitHub/CC", "D:/Dotfiles" -Targets ".dots", "dotfiles" -Markers ".dotsrc", ".git"
    Returns the path to the first valid DOTS directory found.
#>
function Global:Get-DOTS {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$Parents = @(
            'D:/Projects/GitHub/CC',
            'D:/Configuration',
            'D:/Dotfiles',
            $env:USERPROFILE
        ),
        [Parameter()]
        [string[]]$Targets = @(
            '.dots',
            'dotDots',
            'dots',
            'dotfiles',
            'global',
            'config',
            'common'
        ),
        [Parameter()]
        [string[]]$Markers = @(
            '.dotsrc',
            '.git',
            'flake.nix'
        )
    )

    #{ Ensure arrays for input parameters
    $Parents = $Parents | ForEach-Object { Format-PathPOSIX $_ }
    Write-Verbose "Possible DOTS Parents: $($Parents -join ', ')"

    $Targets = @($Targets)
    Write-Verbose "Possible DOTS Targets: $($Targets -join ', ')"

    $Markers = @($Markers)
    Write-Verbose "Possible DOTS Markers: $($Markers -join ', ')"

    foreach ($parent in $Parents) {
        if (-not (Test-Path -Path $parent -PathType Container)) { continue }

        foreach ($target in $Targets) {
            $potentialDOTS = Resolve-PathPOSIX (Join-Path -Path $parent -ChildPath $target)
            if (-not (Test-Path -Path $potentialDOTS -PathType Container)) { continue }

            #{ Check if any of the marker files exist
            foreach ($marker in $Markers) {
                Write-Verbose "Searching for '$marker' in '$potentialDOTS'"
                $markerPath = Resolve-PathPOSIX (Join-Path -Path $potentialDOTS -ChildPath $marker)
                if (Test-Path -Path $markerPath -PathType Leaf) {
                    #{ Ensure DOTS variable is defined globally
                    $Global:DOTS = $potentialDOTS
                    [Environment]::SetEnvironmentVariable('DOTS', $potentialDOTS, 'Process')
                    Set-Item -Path 'env:DOTS' -Value $potentialDOTS
                    Write-Debug "DOTS => $Global:DOTS"

                    #{ Ensure DOTS_RC variable is defined globally
                    $Global:DOTS_RC = $markerPath
                    [Environment]::SetEnvironmentVariable('DOTS_RC', $markerPath, 'Process')
                    Set-Item -Path 'env:DOTS_RC' -Value $markerPath
                    Write-Debug "DOTS_RC => $Global:DOTS_RC"

                    return
                }
            }
        }
    }

    Write-Error "Unable to determine the DOTS directory from the potential locations"
    return $null
}

<#
.SYNOPSIS
    Initializes the DOTS environment by locating the DOTS directory and loading its polyglot RC file.
.DESCRIPTION
    Uses Get-DOTS to find the DOTS directory, sets global and environment variables, and loads the polyglot RC file.
.EXAMPLE
    Invoke-DOTS
    Locates the DOTS directory and loads its polyglot RC file.
#>
function Global:Invoke-DOTS {
    [CmdletBinding()]
    param()

    #{ Ensure DOTS and DOTS_RC variables are defined
    Get-DOTS
    if (-not $Global:DOTS -or -not $Global:DOTS_RC) {
        Write-Error "Invoke-DOTS: DOTS and DOTS_RC variables must be set to proceed."
        return $null
    }
    else {
        try {
            Write-Verbose "Attempting to invoke polyglot RC: ${Global:DOTS_RC}"
            Invoke-PolyglotRC -RcPath $Global:DOTS_RC
        }
        catch {
            Write-Error "Failed to load DOTS_RC: $_"
            return $null
        }
    }
}

#endregion

#region Polyglot RC Handler

<#
.SYNOPSIS
    Executes PowerShell commands from a polyglot RC file using improved parsing.
.DESCRIPTION
    Parses the polyglot RC file and extracts the PowerShell section for execution as a complete block.
.PARAMETER RcPath
    Path to the polyglot RC file.
#>
function Global:Invoke-PolyglotRC {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RcPath
    )

    if (-not (Test-Path -Path $RcPath -PathType Leaf)) {
        Write-Error "RC file not found: $RcPath"
        return
    }

    try {
        $content = Get-Content -Path $RcPath -Raw

        #{ Extract the PowerShell section using regex
        $powershellPattern = '(?s)# === POWERSHELL ===.*?(?=# === \w+ ===|\z)'

        if ($content -match $powershellPattern) {
            $powershellSection = $matches[0]
            Write-Verbose "Found PowerShell section in polyglot RC"

            #{ Clean up the section - remove the header comment and any trailing comments
            $lines = $powershellSection -split "`n"
            $cleanLines = @()
            $inCommentBlock = $false
            $foundFirstCode = $false

            foreach ($line in $lines) {
                #{ Skip the section header
                if ($line -match '# === POWERSHELL ===') {
                    continue
                }

                #{ Handle PowerShell comment blocks
                if ($line -match '^\s*<#') {
                    $inCommentBlock = $true
                    continue
                }
                if ($line -match '^\s*#>') {
                    $inCommentBlock = $false
                    continue
                }
                if ($inCommentBlock) {
                    continue
                }

                #{ Skip single-line comments and PowerShell help syntax at the beginning
                if (-not $foundFirstCode -and ($line -match '^\s*#' -or
                    $line -match '^\s*\.' -or  # PowerShell help syntax like .SYNOPSIS
                    $line.Trim() -eq '')) {
                    continue
                }

                #{ If we find actual code, start collecting everything
                if ($line.Trim() -ne '' -and $line -notmatch '^\s*#' -and $line -notmatch '^\s*\.') {
                    $foundFirstCode = $true
                }

                if ($foundFirstCode) {
                    $cleanLines += $line
                }
            }

            if ($cleanLines.Count -gt 0) {
                $powershellCode = $cleanLines -join "`n"
                Write-Verbose "Executing PowerShell section from polyglot RC"
                Write-Verbose "PowerShell code:`n$powershellCode"

                try {
                    #{ Create and execute the script block
                    $scriptBlock = [ScriptBlock]::Create($powershellCode)
                    & $scriptBlock
                }
                catch {
                    Write-Error "Failed to execute PowerShell section |> $_"
                }
            }
            else {
                Write-Error "No executable PowerShell code found in polyglot RC file"
            }
        }
        else {
            Write-Error "No PowerShell section found in polyglot RC file"
        }
    }
    catch {
        Write-Error "Failed to process polyglot RC file |> $_"
    }
}

#endregion

#region Main

<#
.SYNOPSIS
    Main execution block for the DOTS initialization script.
.DESCRIPTION
    Sets output preferences and initializes the DOTS environment.
#>

# $Global:VerbosePreference = 'Continue'
# $Global:DebugPreference = 'Continue'
# $Global:InformationPreference = 'Continue'
# $Global:WarningPreference = 'Continue'
# $Global:ErrorActionPreference = 'Continue'
Invoke-DOTS

#endregion
