#Requires -RunAsAdministrator
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Microsoft.PowerShell.Utility'; ModuleVersion='3.1.0.0' }

<#
.SYNOPSIS
    Enterprise-grade bulk installer for Windows applications using winget package manager.

.DESCRIPTION
    Provides automated installation of curated application sets using winget.
    Features:
    - Categorized application management
    - Error handling and logging
    - Progress tracking
    - Post-installation system updates
    - Validation of prerequisites
    - Modular design for easy maintenance

.PARAMETER LogPath
    Optional path for installation logs. Defaults to "$env:TEMP\winget_install_log.txt"

.EXAMPLE
    .\install_apps.ps1
    Performs full installation of all configured applications

.EXAMPLE
    .\install_apps.ps1 -WhatIf -LogPath "C:\logs\install.log"
    Simulates installation and logs to specified path

.NOTES
    Version:        2.1
    Author:         [Your Name]
    Last Modified:  2025-01-03

    Requirements:
    - Windows 10/11
    - PowerShell 5.1+
    - winget package manager
    - Administrative privileges
    - Internet connectivity
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "$env:TEMP\winget_install_log.txt"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Functions

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Write to console with appropriate color
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor Gray }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
    }

    # Append to log file
    Add-Content -Path $LogPath -Value $logMessage
}

function Install-ApplicationPackage {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$PackageId,

        [Parameter(Mandatory = $false)]
        [int]$RetryCount = 3,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelaySeconds = 30
    )

    process {
        $attempt = 1
        $success = $false

        do {
            try {
                Write-Log "Installing package: $PackageId (Attempt $attempt of $RetryCount)"

                if ($PSCmdlet.ShouldProcess($PackageId, "Install application")) {
                    $installOutput = winget install --id $PackageId --silent --accept-package-agreements --accept-source-agreements

                    if ($LASTEXITCODE -eq 0) {
                        Write-Log "Successfully installed: $PackageId"
                        Write-Log "Installation output: $installOutput"
                        $success = $true
                        break
                    }
                    else {
                        Write-Log "Installation failed with exit code: $LASTEXITCODE" -Level Warning
                        Write-Log "Installation output: $installOutput" -Level Warning
                    }
                }
                else {
                    Write-Log "WhatIf: Would install $PackageId"
                    $success = $true
                    break
                }
            }
            catch {
                Write-Log "Error installing $PackageId`: $_" -Level Error
                if ($attempt -lt $RetryCount) {
                    Write-Log "Retrying in $RetryDelaySeconds seconds..." -Level Warning
                    Start-Sleep -Seconds $RetryDelaySeconds
                }
            }
            $attempt++
        } while ($attempt -le $RetryCount)

        if (-not $success) {
            Write-Log "Failed to install $PackageId after $RetryCount attempts" -Level Error
        }

        return $success
    }
}

function Test-Prerequisites {
    [CmdletBinding()]
    param()

    process {
        $prerequisites = @(
            @{
                Name    = "Winget"
                Test    = { Get-Command winget -ErrorAction SilentlyContinue }
                Message = "Winget is not installed. Install it from the Microsoft Store."
            },
            @{
                Name    = "Internet Connectivity"
                Test    = { Test-NetConnection -ComputerName "8.8.8.8" -Port 443 -WarningAction SilentlyContinue }
                Message = "No internet connectivity detected."
            },
            @{
                Name    = "Admin Rights"
                Test    = { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
                Message = "Script requires administrative privileges."
            }
        )

        $allPassed = $true
        foreach ($prereq in $prerequisites) {
            Write-Log "Checking prerequisite: $($prereq.Name)"
            if (-not (& $prereq.Test)) {
                Write-Log $prereq.Message -Level Error
                $allPassed = $false
            }
        }

        return $allPassed
    }
}

function Update-AllPackages {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    process {
        Write-Log "Starting system-wide updates..."

        if ($PSCmdlet.ShouldProcess("System", "Run updates")) {
            try {
                $updateOutput = topgrade --cleanup --no-retry --yes --disable microsoft_store
                Write-Log "Updates completed successfully"
                Write-Log "Update output: $updateOutput"
            }
            catch {
                Write-Log "Error during updates: $_" -Level Error
            }
        }
        else {
            Write-Log "WhatIf: Would run system updates"
        }
    }
}

#endregion

#region Application Categories
# [Previous application arrays remain unchanged]
#endregion

#region Main Execution
function Start-Installation {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    begin {
        Write-Log "Starting installation process..."

        if (-not (Test-Prerequisites)) {
            Write-Log "Prerequisites check failed. Exiting." -Level Error
            return
        }
    }

    process {
        $categories = @{
            "System Utilities"      = $systemUtils
            "Development Tools"     = $devTools
            "Media Applications"    = $mediaApps
            "Communication Tools"   = $communicationApps
            "Creative Applications" = $creativeApps
            "Internet Applications" = $internetApps
        }

        foreach ($category in $categories.GetEnumerator()) {
            Write-Log "Processing category: $($category.Key)"

            $category.Value | ForEach-Object {
                $_ | Install-ApplicationPackage
            }
        }

        if ($PSCmdlet.ShouldProcess("System", "Run updates")) {
            Update-AllPackages
        }
    }

    end {
        Write-Log "Installation process completed"
    }
}

# Execute the script
Start-Installation
#endregion
