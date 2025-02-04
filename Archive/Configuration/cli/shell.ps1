<#
.SYNOPSIS
    Cross-platform shell initialization and configuration

.DESCRIPTION
    Provides a unified shell initialization system that:
    1. Detects the current shell environment
    2. Sets up appropriate paths and environment variables
    3. Initializes shell prompts (Starship/Oh-My-Posh/etc.)
    4. Loads shell-specific configurations
    5. Sets up common aliases and functions

.NOTES
    Author: Craole
    Last Updated: 2025-01-04
#>

# Configuration
$script:ShellConfig = @{
    Verbose = $false
    Paths   = @{
        Base     = $env:DOTS
        Bin      = "$env:DOTS\Bin"
        Config   = "$env:DOTS\Configuration"
        Cache    = "$env:DOTS\Cache"
        Data     = "$env:DOTS\Data"
    }
    Shells  = @{
        PowerShell = @{
            Name = 'pwsh'
            ConfigDir = 'cli\pwsh'
            ConfigFile = 'profile.ps1'
            Paths = @(
                'Bin\packages\manager\windows'
                'Bin\packages\manager\universal'
                'Bin\tasks'
            )
        }
        Bash = @{
            Name = 'bash'
            ConfigDir = 'cli\bash'
            ConfigFile = '.bashrc'
            Paths = @(
                'Bin/packages/manager/unix'
                'Bin/packages/manager/universal'
                'Bin/tasks'
            )
        }
        Zsh = @{
            Name = 'zsh'
            ConfigDir = 'cli\zsh'
            ConfigFile = '.zshrc'
            Paths = @(
                'Bin/packages/manager/unix'
                'Bin/packages/manager/universal'
                'Bin/tasks'
            )
        }
    }
}

function Write-VerboseMessage {
    param([string]$Message)
    if ($script:ShellConfig.Verbose) {
        Write-Host $Message
    }
}

function Get-CurrentShell {
    [CmdletBinding()]
    param()
    
    Write-VerboseMessage "Detecting current shell environment..."
    
    # Check for PowerShell
    if ($PSVersionTable) {
        if ($PSVersionTable.PSEdition -eq 'Core') {
            return 'PowerShell'
        }
        return 'WindowsPowerShell'
    }
    
    # Check for other shells via environment variables
    if ($env:SHELL) {
        switch -Regex ($env:SHELL) {
            'bash$' { return 'Bash' }
            'zsh$'  { return 'Zsh' }
            default { return $null }
        }
    }
    
    return $null
}

function Initialize-ShellPrompt {
    [CmdletBinding()]
    param(
        [string]$ShellType
    )
    
    Write-VerboseMessage "Initializing prompt for $ShellType..."
    
    # Check for Starship first
    $starship = Get-Command starship -ErrorAction SilentlyContinue
    if ($starship) {
        Write-VerboseMessage "Initializing Starship..."
        switch ($ShellType) {
            'PowerShell' { 
                Invoke-Expression (&starship init powershell)
            }
            'Bash' { 
                Write-VerboseMessage "Use 'eval `"$(starship init bash)`"' in your .bashrc"
            }
            'Zsh' { 
                Write-VerboseMessage "Use 'eval `"$(starship init zsh)`"' in your .zshrc"
            }
        }
        return $true
    }
    
    # Fall back to Oh My Posh for PowerShell
    if ($ShellType -like '*PowerShell*') {
        $ohMyPosh = Get-Command oh-my-posh -ErrorAction SilentlyContinue
        if ($ohMyPosh) {
            $themePaths = @(
                "$($ShellConfig.Paths.Config)\oh-my-posh\theme.omp.json"
                "$env:POSH_THEMES_PATH\paradox.omp.json"
            )
            $theme = $themePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
            if ($theme) {
                oh-my-posh init powershell --config $theme | Invoke-Expression
                return $true
            }
        }
    }
    
    return $false
}

function Add-PathToEnvironment {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$ShellType
    )
    
    Write-VerboseMessage "Adding path to environment: $Path"
    
    if ($ShellType -like '*PowerShell*') {
        $envPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($envPath -notlike "*$Path*") {
            [Environment]::SetEnvironmentVariable('Path', "$envPath;$Path", 'User')
            $env:Path = "$env:Path;$Path"
        }
    }
    else {
        # For Unix-like shells, we'll return the path to be added to PATH in the rc file
        return "export PATH=`"$Path:`$PATH`""
    }
}

function Initialize-ShellEnvironment {
    [CmdletBinding()]
    param(
        [string]$ShellType
    )
    
    Write-VerboseMessage "Initializing environment for $ShellType..."
    
    $shellConfig = $script:ShellConfig.Shells[$ShellType]
    if (-not $shellConfig) {
        Write-Error "No configuration found for shell type: $ShellType"
        return
    }
    
    # Add paths to environment
    foreach ($path in $shellConfig.Paths) {
        $fullPath = Join-Path $script:ShellConfig.Paths.Base $path
        if (Test-Path $fullPath) {
            Add-PathToEnvironment -Path $fullPath -ShellType $ShellType
        }
    }
    
    # Load shell-specific configuration
    $configPath = Join-Path $script:ShellConfig.Paths.Config $shellConfig.ConfigDir $shellConfig.ConfigFile
    if (Test-Path $configPath) {
        Write-VerboseMessage "Loading shell-specific configuration from: $configPath"
        switch ($ShellType) {
            'PowerShell' { 
                . $configPath 
            }
            default {
                Write-VerboseMessage "Source $configPath in your shell's rc file"
            }
        }
    }
}

# Main execution
try {
    $currentShell = Get-CurrentShell
    if (-not $currentShell) {
        throw "Unable to determine current shell environment"
    }
    
    Write-VerboseMessage "Detected shell: $currentShell"
    
    Initialize-ShellEnvironment -ShellType $currentShell
    Initialize-ShellPrompt -ShellType $currentShell
}
catch {
    Write-Error "Error during shell initialization: $_"
    throw
}
