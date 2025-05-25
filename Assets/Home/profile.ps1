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

#region Utilities

<#
.SYNOPSIS
    Normalizes a path by converting it to a full path and replacing backslashes with forward slashes.
.DESCRIPTION
    This function takes a path string, resolves it to its full path, and replaces all backslashes with forward slashes for consistency.
.PARAMETER path
    The path to normalize.
.EXAMPLE
    NormalizePath "C:\Users\Me\Documents"
    Returns: "C:/Users/Me/Documents"
#>
function Global:NormalizePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$path
    )

    try {
        $newPath = [System.IO.Path]::GetFullPath($path)
        # Replace backslashes with forward slashes for consistency
        $newPath = $newPath.Replace('\', '/')
        return $newPath
    }
    catch {
        Write-Error "Failed to normalize path: $_"
        return $null
    }
}

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
    LocateDOTS -Parents "D:/Projects/GitHub/CC", "D:/Dotfiles" -Targets ".dots", "dotfiles" -Markers ".dotsrc", ".git"
    Returns the path to the first valid DOTS directory found.
#>
function Global:LocateDOTS {
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

    #@ Ensure arrays for input parameters
    $Parents = $Parents | ForEach-Object { NormalizePath $_ }
    Write-Verbose "Possible DOTS Parents: $($Parents -join ', ')"

    $Targets = @($Targets)
    Write-Verbose "Possible DOTS Targets: $($Targets -join ', ')"

    $Markers = @($Markers)
    Write-Verbose "Possible DOTS Markers: $($Markers -join ', ')"

    foreach ($parent in $Parents) {
        if (-not (Test-Path -Path $parent -PathType Container)) { continue }

        foreach ($target in $Targets) {
            $potentialDOTS = NormalizePath (Join-Path -Path $parent -ChildPath $target)
            if (-not (Test-Path -Path $potentialDOTS -PathType Container)) { continue }

            #@ Check if any of the marker files exist
            foreach ($marker in $Markers) {
                Write-Verbose "Searching for '$marker' in '$potentialDOTS'"
                $markerPath = NormalizePath (Join-Path -Path $potentialDOTS -ChildPath $marker)
                if (Test-Path -Path $markerPath -PathType Leaf) {
                    #@ Ensure DOTS variable is defined globally
                    $Global:DOTS = $potentialDOTS
                    [Environment]::SetEnvironmentVariable('DOTS', $potentialDOTS, 'Process')
                    Set-Item -Path 'env:DOTS' -Value $potentialDOTS
                    Write-Debug "DOTS: $Global:DOTS"
                    return $Global:DOTS
                }
            }
        }
    }

    Write-Warning "Unable to determine the DOTS directory from the potential locations"
    return $null
}

<#
.SYNOPSIS
    Initializes the DOTS environment by locating the DOTS directory and loading its default profile.
.DESCRIPTION
    Uses LocateDOTS to find the DOTS directory, sets global and environment variables, and loads the default profile if found.
.EXAMPLE
    InitializeDOTS
    Locates the DOTS directory and loads its default profile.
#>
function Global:InitializeDOTS {
    [CmdletBinding()]
    param()

    #@ Ensure DOTS variable is defined globally
    $Global:DOTS = LocateDOTS
    if (-not $Global:DOTS) {
        Write-Warning "DOTS environment variable is not set"
        return $null
    }

    #@ Ensure the default profile is defined globally
    $dotsProfile = NormalizePath (Join-Path -Path $Global:DOTS -ChildPath 'default.ps1')
    if ($dotsProfile -and (Test-Path -Path $dotsProfile -PathType Leaf)) {
        $Global:DOTS_PROFILE_POWERSHELL = $dotsProfile
        [Environment]::SetEnvironmentVariable('DOTS_PROFILE_POWERSHELL', $dotsProfile, 'Process')
        Set-Item -Path 'env:DOTS_PROFILE_POWERSHELL' -Value $dotsProfile
        Write-Debug "DOTS_PROFILE_POWERSHELL: $Global:DOTS_PROFILE_POWERSHELL"
        Write-Verbose "Loading DOTS profile from '$dotsProfile'"
        try {
            . $dotsProfile
        }
        catch {
            Write-Error "Failed to load DOTS profile: $_"
            return $null
        }
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

#@ Set output preferences (optional, can be set by caller instead)
$VerbosePreference = 'Continue'
$DebugPreference = 'Continue'
$InformationPreference = 'Continue'
$WarningPreference = 'Continue'
$ErrorActionPreference = 'Continue'

InitializeDOTS

#endregion
