
function Initialize-VSCodeProfile {
    Write-Host "Setting up VSCode PowerShell profile..." -Color Cyan

    $vscodeProfilePath = "$env:USERPROFILE\OneDrive\Documents\PowerShell\Microsoft.VSCode_profile.ps1"

    if (-not (Test-Path $vscodeProfilePath)) {
        try {
            $profileContent = @"
# VSCode PowerShell Profile
# This profile loads the main user profile to ensure consistency

`$userProfile = "`$env:USERPROFILE\OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
if (Test-Path `$userProfile) {
    . `$userProfile
} else {
    # Fallback to standard profile location
    `$fallbackProfile = "`$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    if (Test-Path `$fallbackProfile) {
        . `$fallbackProfile
    }
}
"@
            $vscodeProfileDir = Split-Path $vscodeProfilePath -Parent
            if (-not (Test-Path $vscodeProfileDir)) {
                New-Item -Path $vscodeProfileDir -ItemType Directory -Force | Out-Null
            }

            Set-Content -Path $vscodeProfilePath -Value $profileContent
            Pout -Level "Info" -Message "Created VSCode profile: $vscodeProfilePath"
        }
        catch {
            Pout -Level "Warn" -Message "Failed to create VSCode profile: $($_.Exception.Message)"
        }
    }
    else {
        Pout -Level "Trace" -Message "Skipping existing VSCode profile: $vscodeProfilePath"
    }
}

# Setup VSCode profile
Initialize-VSCodeProfile
