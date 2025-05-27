<#
.SYNOPSIS
    Main PowerShell profile configuration for DOTS environment.

.DESCRIPTION
    This is the main PowerShell profile that gets loaded from DOTS/Configuration/powershell/profile.ps1
    It handles:
    - Loading environment configurations (aliases, functions, variables)
    - Setting up shell customizations (Starship, Oh My Posh)
    - Configuring Git integration
    - Loading PowerShell modules
    - VSCode profile setup

.NOTES
    This file is loaded by the minimal $PROFILE after DOTS discovery is complete.
    Path: DOTS/Configuration/powershell/profile.ps1
#>

# Global configuration for this profile
$script:DotsProfile = @{
    ConfigPath = Join-Path $env:DOTS 'Configuration'
    Verbose = $false
}

#region Helper Functions

function Write-DotsMessage {
    param(
        [string]$Message,
        [string]$Color = 'Gray',
        [string]$Context = 'DOTS-Profile'
    )
    if ($script:DotsProfile.Verbose) {
        Write-Host "[$Context] $Message" -ForegroundColor $Color
    }
}

function Import-DotsConfiguration {
    <#
    .SYNOPSIS
        Imports configuration files from the DOTS Configuration directory.
    #>
    param(
        [string]$ConfigType,
        [string]$FileName,
        [switch]$Required = $false
    )

    $configPath = Join-Path $script:DotsProfile.ConfigPath $ConfigType $FileName

    if (Test-Path $configPath) {
        try {
            Write-DotsMessage "Loading $ConfigType configuration: $FileName" -Color Green
            . $configPath
            return $true
        }
        catch {
            Write-DotsMessage "Failed to load $ConfigType/$FileName`: $_" -Color Red
            if ($Required) { throw }
            return $false
        }
    }
    else {
        $message = "$ConfigType configuration not found: $FileName"
        if ($Required) {
            Write-DotsMessage $message -Color Red
            throw "Required configuration file not found: $configPath"
        }
        else {
            Write-DotsMessage $message -Color Yellow
            return $false
        }
    }
}

#endregion

#region Environment Configuration

Write-DotsMessage "Initializing DOTS PowerShell environment..." -Color Cyan

# Load environment configurations in order
$environmentConfigs = @(
    @{ Type = 'powershell\environment'; File = 'variables.ps1'; Required = $false }
    @{ Type = 'powershell\environment'; File = 'aliases.ps1'; Required = $false }
    @{ Type = 'powershell\environment'; File = 'functions.ps1'; Required = $false }
)

foreach ($config in $environmentConfigs) {
    Import-DotsConfiguration -ConfigType $config.Type -FileName $config.File -Required:$config.Required
}

#endregion

#region Git Configuration

Write-DotsMessage "Configuring Git integration..." -Color Cyan

function Update-GitConfig {
    $mainGitConfigPath = Join-Path $env:DOTS 'Configuration\git\main.gitconfig'

    if (-not (Test-Path $mainGitConfigPath)) {
        Write-DotsMessage "Main gitconfig not found at: $mainGitConfigPath" -Color Yellow
        return $false
    }

    $gitConfigPath = Join-Path $env:USERPROFILE '.gitconfig'

    try {
        # Create .gitconfig if it doesn't exist
        if (-not (Test-Path $gitConfigPath)) {
            New-Item -Path $gitConfigPath -ItemType File -Force | Out-Null
        }

        $gitConfigContent = Get-Content -Path $gitConfigPath -Raw -ErrorAction SilentlyContinue
        if (-not $gitConfigContent) { $gitConfigContent = "" }

        # Check if already included
        $normalizedMainPath = $mainGitConfigPath -replace '\\', '/'
        if ($gitConfigContent -match "path\s*=\s*.*main\.gitconfig") {
            Write-DotsMessage "Git config already includes main.gitconfig" -Color Green
            return $true
        }

        # Add include section
        $lines = $gitConfigContent -split "`r?`n"
        $hasIncludeSection = $lines -match '^\[include\]'

        if (-not $hasIncludeSection) {
            $lines += '[include]'
        }
        $lines += "`tpath = $mainGitConfigPath"

        $newContent = ($lines | Where-Object { $_ -ne $null }) -join "`n"
        Set-Content -Path $gitConfigPath -Value $newContent -NoNewline

        Write-DotsMessage "Updated Git configuration with DOTS main.gitconfig" -Color Green
        return $true
    }
    catch {
        Write-DotsMessage "Failed to update Git configuration: $_" -Color Red
        return $false
    }
}

# Update Git configuration
Update-GitConfig | Out-Null

#endregion

#region Shell Customization

Write-DotsMessage "Initializing shell customization..." -Color Cyan

function Initialize-ShellPrompt {
    # Check for Starship first
    $starshipExe = Get-Command starship -ErrorAction SilentlyContinue
    if ($starshipExe) {
        Write-DotsMessage "Initializing Starship prompt..." -Color Green
        try {
            # Check for custom Starship config
            $starshipConfig = Join-Path $env:DOTS 'Configuration\starship\starship.toml'
            if (Test-Path $starshipConfig) {
                $env:STARSHIP_CONFIG = $starshipConfig
                Write-DotsMessage "Using custom Starship config: $starshipConfig" -Color Green
            }

            Invoke-Expression (&starship init powershell)
            Write-DotsMessage "Starship initialized successfully" -Color Green
            return $true
        }
        catch {
            Write-DotsMessage "Failed to initialize Starship: $_" -Color Red
        }
    }

    # Fallback to Oh My Posh
    $ohMyPoshExe = Get-Command oh-my-posh -ErrorAction SilentlyContinue
    if ($ohMyPoshExe) {
        Write-DotsMessage "Initializing Oh My Posh prompt..." -Color Green
        try {
            # Look for custom Oh My Posh theme
            $themePaths = @(
                Join-Path $env:DOTS 'Configuration\oh-my-posh\config.toml'
                Join-Path $env:DOTS 'Configuration\oh-my-posh\theme.omp.json'
                Join-Path $env:DOTS 'Configuration\oh-my-posh\profile.ps1\config.toml'
            )

            $themeFile = $themePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

            if ($themeFile) {
                Write-DotsMessage "Using Oh My Posh theme: $themeFile" -Color Green
                oh-my-posh init pwsh --config $themeFile | Invoke-Expression
            } else {
                Write-DotsMessage "Using default Oh My Posh theme" -Color Yellow
                oh-my-posh init pwsh | Invoke-Expression
            }

            Write-DotsMessage "Oh My Posh initialized successfully" -Color Green
            return $true
        }
        catch {
            Write-DotsMessage "Failed to initialize Oh My Posh: $_" -Color Red
        }
    }

    Write-DotsMessage "No shell prompt customization tool found" -Color Yellow
    return $false
}

# Initialize shell prompt
Initialize-ShellPrompt | Out-Null

#endregion

#region PowerShell Modules

Write-DotsMessage "Loading PowerShell modules..." -Color Cyan

$modules = @(
    'PSScriptAnalyzer'
    'Terminal-Icons'
    'posh-git'
)

foreach ($module in $modules) {
    try {
        if (Get-Module -ListAvailable -Name $module -ErrorAction SilentlyContinue) {
            Import-Module $module -ErrorAction SilentlyContinue
            Write-DotsMessage "Loaded module: $module" -Color Green
        } else {
            Write-DotsMessage "Module not available: $module" -Color Yellow
        }
    }
    catch {
        Write-DotsMessage "Failed to load module $module`: $_" -Color Red
    }
}

#endregion

#region VSCode Integration

# function Initialize-VSCodeProfile {
#     Write-DotsMessage "Setting up VSCode PowerShell profile..." -Color Cyan

#     $vscodeProfilePath = "$env:USERPROFILE\OneDrive\Documents\PowerShell\Microsoft.VSCode_profile.ps1"

#     if (-not (Test-Path $vscodeProfilePath)) {
#         try {
#             $profileContent = @"
# # VSCode PowerShell Profile
# # This profile loads the main user profile to ensure consistency

# `$userProfile = "`$env:USERPROFILE\OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
# if (Test-Path `$userProfile) {
#     . `$userProfile
# } else {
#     # Fallback to standard profile location
#     `$fallbackProfile = "`$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
#     if (Test-Path `$fallbackProfile) {
#         . `$fallbackProfile
#     }
# }
# "@
#             $vscodeProfileDir = Split-Path $vscodeProfilePath -Parent
#             if (-not (Test-Path $vscodeProfileDir)) {
#                 New-Item -Path $vscodeProfileDir -ItemType Directory -Force | Out-Null
#             }

#             Set-Content -Path $vscodeProfilePath -Value $profileContent
#             Write-DotsMessage "Created VSCode PowerShell profile" -Color Green
#         }
#         catch {
#             Write-DotsMessage "Failed to create VSCode profile: $_" -Color Red
#         }
#     } else {
#         Write-DotsMessage "VSCode PowerShell profile already exists" -Color Green
#     }
# }

# # Setup VSCode profile
# Initialize-VSCodeProfile

#endregion

#region Custom DOTS Scripts

Write-DotsMessage "Loading custom DOTS scripts..." -Color Cyan

#@ Load any custom scripts from $DOTS/Configuration/powershell/modules/
$modulesPath = Join-Path $script:DotsProfile.ConfigPath 'powershell\modules'
if (Test-Path $modulesPath) {
    Get-ChildItem -Path $modulesPath -Filter '*.ps1' | ForEach-Object {
        try {
            Write-DotsMessage "Loading script: $($_.Name)" -Color Green
            . $_.FullName
        }
        catch {
            Write-DotsMessage "Failed to load script $($_.Name): $_" -Color Red
        }
    }
}

#@ Load any custom scripts from $DOTS/Configuration/powershell/scripts/
$scriptsPath = Join-Path $script:DotsProfile.ConfigPath 'powershell\scripts'
if (Test-Path $scriptsPath) {
    Get-ChildItem -Path $scriptsPath -Filter '*.ps1' | ForEach-Object {
        try {
            Write-DotsMessage "Loading script: $($_.Name)" -Color Green
            . $_.FullName
        }
        catch {
            Write-DotsMessage "Failed to load script $($_.Name): $_" -Color Red
        }
    }
}

#endregion
$env:DOTS
