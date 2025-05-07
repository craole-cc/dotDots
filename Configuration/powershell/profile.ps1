<#
.SYNOPSIS
    PowerShell profile configuration for DOTS environment setup.

.DESCRIPTION
    This profile script handles the configuration of the DOTS environment variable by:
    1. Looking for existing DOTS configuration in .profile
    2. Searching for .dotsrc files in common locations if not found
    3. Offering a full filesystem search as fallback
    4. Updating .profile with the found configuration

.NOTES
    Author: Craole
    Last Updated: 2025-01-04
#>

# Configuration
$script:Config = @{
    ProfilePath     = "$env:USERPROFILE/.profile"
    CommonLocations = @(
        "$env:USERPROFILE\.dots"
        "$env:USERPROFILE\dots"
        "$env:USERPROFILE\OneDrive\.dots"
        "$env:USERPROFILE\OneDrive\dots"
        "$env:USERPROFILE\.config\dots"
        "$env:USERPROFILE\Documents\dotfiles"
        "$env:USERPROFILE\dots"
    )
    Verbose         = $false
}

function Write-VerboseMessage {
    <#
    .SYNOPSIS
        Writes a message if verbose mode is enabled.
    #>
    param([string]$Message)
    if ($script:Config.Verbose) {
        Write-Host $Message
    }
}

function Convert-ToLinuxPath {
    [CmdletBinding()]
    param([string]$WindowsPath)
    Write-VerboseMessage "Converting Windows path to Linux format: $WindowsPath"
    return $WindowsPath -replace '\\', '/' -replace '^(\w):', '/$1'
}

function Convert-ToWindowsPath {
    [CmdletBinding()]
    param([string]$LinuxPath)
    Write-VerboseMessage "Converting Linux path to Windows format: $LinuxPath"
    return ($LinuxPath -replace '^\/(\w)', '$1:') -replace '\/', '\'
}

function Find-DotsRC {
    [CmdletBinding()]
    param([string[]]$SearchPaths)

    Write-VerboseMessage "Searching for .dotsrc in common locations..."
    $foundPaths = @()
    foreach ($location in $SearchPaths) {
        Write-VerboseMessage "Checking location: $location"
        if (Test-Path -Path "$location\.dotsrc" -PathType Leaf) {
            Write-VerboseMessage "Found .dotsrc at: $location"
            $foundPaths += (Split-Path -Parent "$location\.dotsrc")
        }
    }
    return $foundPaths
}

function Search-FileSystem {
    [CmdletBinding()]
    param()

    Write-VerboseMessage "Starting full filesystem search for .dotsrc..."
    $foundPaths = @()
    Write-Host "Searching for .dotsrc in all drives... (Press Ctrl+C to cancel)" # Keep this visible as it's important user feedback
    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        Write-VerboseMessage "Searching drive: $($_.Root)"
        Get-ChildItem -Path "$($_.Root)" -Filter ".dotsrc" -File -Recurse -ErrorAction SilentlyContinue |
        ForEach-Object {
            Write-VerboseMessage "Found .dotsrc at: $($_.FullName)"
            $foundPaths += (Split-Path -Parent $_.FullName)
        }
    }
    return $foundPaths
}

function Update-ProfileFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfilePath,
        [Parameter(Mandatory)]
        [string]$DotsPath
    )

    Write-VerboseMessage "Updating profile file at: $ProfilePath"
    if (-not (Test-Path -Path $ProfilePath)) {
        Write-VerboseMessage "Creating new profile file"
        New-Item -Path $ProfilePath -ItemType File -Force | Out-Null
    }

    $profileContent = Get-Content -Path $ProfilePath -ErrorAction SilentlyContinue
    if (-not $profileContent) {
        Write-VerboseMessage "Profile file is empty"
        $profileContent = @()
    }

    $linuxPath = Convert-ToLinuxPath -WindowsPath $DotsPath
    $dotsLine = $profileContent | Where-Object { $_ -match '^DOTS=' }

    $newContent = if ($dotsLine) {
        Write-VerboseMessage "Updating existing DOTS definition"
        $profileContent -replace '^DOTS=.*', "DOTS=`"$linuxPath`""
    }
    else {
        Write-VerboseMessage "Adding new DOTS definition"
        @("DOTS=`"$linuxPath`"") + $profileContent
    }

    Set-Content -Path $ProfilePath -Value $newContent -ErrorAction Stop
    Write-VerboseMessage "Successfully updated .profile with DOTS path: $linuxPath"
}

function Initialize-Shell {
    [CmdletBinding()]
    param()

    Write-VerboseMessage "Checking for shell prompt customization tools..."

    # Check for Starship
    $starshipExe = Get-Command starship -ErrorAction SilentlyContinue
    if ($starshipExe) {
        Write-VerboseMessage "Starship found, initializing..."
        try {
            Invoke-Expression (&starship init powershell)
            Write-VerboseMessage "Starship initialized successfully"
            return
        }
        catch {
            Write-VerboseMessage "Failed to initialize Starship: $_"
        }
    }

    # Check for Oh My Posh if Starship isn't available
    try {
        $ohMyPosh = Get-Command oh-my-posh -ErrorAction SilentlyContinue
        if ($ohMyPosh) {
            Write-VerboseMessage "Oh My Posh found, initializing..."
            # Try to find a theme, preferring custom over default
            $themePaths = @(
                "$env:USERPROFILE\.dots\config\oh-my-posh\theme.omp.json",
                "$env:USERPROFILE\.config\oh-my-posh\theme.omp.json",
                "$env:POSH_THEMES_PATH\paradox.omp.json" # Default theme if nothing else found
            )

            $themeFile = $themePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
            if ($themeFile) {
                Write-VerboseMessage "Using Oh My Posh theme: $themeFile"
                oh-my-posh init powershell --config $themeFile | Invoke-Expression
            }
            else {
                Write-VerboseMessage "No custom theme found, using default initialization"
                oh-my-posh init powershell | Invoke-Expression
            }
            Write-VerboseMessage "Oh My Posh initialized successfully"
            return
        }
    }
    catch {
        Write-VerboseMessage "Failed to initialize Oh My Posh: $_"
    }

    Write-VerboseMessage "No shell customization tool found"
}

function Initialize-VSCodeProfile {
    [CmdletBinding()]
    param()

    Write-VerboseMessage "Checking VSCode PowerShell profile..."
    $vscodePath = "$env:USERPROFILE\OneDrive\Documents\PowerShell\Microsoft.VSCode_profile.ps1"

    if (-not (Test-Path -Path $vscodePath)) {
        Write-VerboseMessage "VSCode profile not found, creating..."
        try {
            $profileContent = @'
# Load user PowerShell profile
$userProfile = "$env:USERPROFILE\OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
if (Test-Path $userProfile) {
    . $userProfile
}
'@
            New-Item -Path $vscodePath -ItemType File -Force | Out-Null
            Set-Content -Path $vscodePath -Value $profileContent -ErrorAction Stop
            Write-VerboseMessage "VSCode profile created successfully"
        }
        catch {
            Write-Error "Failed to create VSCode profile: $_"
        }
    }
    else {
        Write-VerboseMessage "VSCode profile already exists"
    }
}

# ===================================================================
# === MAIN EXECUTION
# ===================================================================
# Main execution
try {
    Write-VerboseMessage "Starting DOTS configuration..."
    $ProfileContent = Get-Content -Path $Config.ProfilePath -ErrorAction SilentlyContinue
    $DOTSLine = $ProfileContent | Where-Object { $_ -match 'DOTS="(.+)"' }

    if ($DOTSLine) {
        $LinuxPath = $matches[1]
        $WindowsPath = Convert-ToWindowsPath -LinuxPath $LinuxPath
        Write-VerboseMessage "Found DOTS in .profile: $WindowsPath"
    }
    elseif ($env:DOTS) {
        $WindowsPath = $env:DOTS
        Write-VerboseMessage "Found DOTS in environment: $WindowsPath"
    }
    else {
        $foundPaths = Find-DotsRC -SearchPaths $Config.CommonLocations

        if ($foundPaths.Count -eq 0) {
            Write-VerboseMessage "No .dotsrc found in common locations"
            $response = Read-Host "No .dotsrc found in common locations. Would you like to search the entire filesystem? (y/N)"
            if ($response -eq 'y' -or $response -eq 'Y') {
                $foundPaths = Search-FileSystem
            }
        }

        if ($foundPaths.Count -gt 0) {
            if ($foundPaths.Count -eq 1) {
                $WindowsPath = $foundPaths[0]
                Write-VerboseMessage "Using single found .dotsrc path: $WindowsPath"
            }
            else {
                Write-Host "`nMultiple .dotsrc files found. Please select one:" # Keep this visible for user interaction
                for ($i = 0; $i -lt $foundPaths.Count; $i++) {
                    Write-Host "[$i] $($foundPaths[$i])"
                }
                do {
                    $selection = Read-Host "`nEnter selection number"
                    $valid = $selection -match '^\d+$' -and [int]$selection -lt $foundPaths.Count
                } while (-not $valid)

                $WindowsPath = $foundPaths[[int]$selection]
                Write-VerboseMessage "User selected path: $WindowsPath"
            }

            Update-ProfileFile -ProfilePath $Config.ProfilePath -DotsPath $WindowsPath
            $env:DOTS = $WindowsPath
            Write-VerboseMessage "DOTS environment variable set"
        }
        else {
            $WindowsPath = $env:USERPROFILE
            Write-VerboseMessage "Using default USERPROFILE path: $WindowsPath"
        }
    }
}
catch {
    Write-Error "Error configuring DOTS: $_"
    throw
}

# Initialize shell customization after DOTS configuration
Initialize-Shell

# Setup VSCode profile
Initialize-VSCodeProfile


Import-Module posh-git
oh-my-posh init pwsh --config "$env:DOTS/Configuration/oh-my-posh/profile.ps1/config.toml" | Invoke-Expression
Import-Module PSScriptAnalyzer
Import-Module Terminal-Icons
