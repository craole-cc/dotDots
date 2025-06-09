

function Global:ImportEditorServices {
    # === Ensure the user module path is in PSModulePath ===
    $expectedPath = Join-Path $DOTS_MOD_PS 'EditorServices'
    if (-not ($env:PSModulePath -split ';' | Where-Object { $_ -eq $expectedPath })) {
        $env:PSModulePath += ";$expectedPath"
    }

    # === Define PSES Module Path ===
    $modulePath = Join-Path $expectedPath 'PowerShellEditorServices\PowerShellEditorServices.psd1'

    # === Auto-install if missing ===
    if (-not (Test-Path $modulePath)) {
        try {
            Install-Module -Name PowerShellEditorServices -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        }
        catch {
            Write-Warning "Auto-install of PowerShellEditorServices failed: $_"
        }
    }

    # === Try Importing ===
    if (Test-Path $modulePath) {
        try {
            Import-Module $modulePath -Force -ErrorAction Stop

            function Start-PSES {
                $logPath = Join-Path $HOME 'pses.log'
                $sessionDetailsPath = Join-Path $HOME 'pses.session.json'
                $bundledModulesPath = Split-Path $modulePath

                Start-EditorServices -HostName 'Host' `
                    -HostProfileId 'PSES' `
                    -HostVersion '1.0.0' `
                    -BundledModulesPath $bundledModulesPath `
                    -LogPath $logPath `
                    -SessionDetailsPath $sessionDetailsPath `
                    -FeatureFlags @()
            }

            Write-Verbose "PowerShellEditorServices loaded successfully." -Verbose
        }
        catch {
            Write-Warning "Failed to import PowerShellEditorServices: $_"
        }
    }
    else {
        Write-Warning "PowerShellEditorServices.psd1 not found at expected path: $modulePath"
    }
}

function Global:ImportScriptAnalyzer {
    $modulePath = Join-Path $DOTS_MOD_PS 'ScriptAnalyzer'
    if (Test-Path $modulePath) {
        Import-Module $modulePath
        Write-Verbose "PSScriptAnalyzer loaded successfully." -Verbose
    }
    else {
        Write-Warning "PSScriptAnalyzer.psd1 not found at expected path: $modulePath"
    }
}
ImportEditorServices
ImportScriptAnalyzer
