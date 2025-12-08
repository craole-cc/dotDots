#!/usr/bin/env pwsh

# Get current tinty theme
    $current = & tinty current 2>$null

# Determine theme variant
$config = if ($current -match 'light') {
    @{
        Variant = 'light'
        Helix = 'light'
        Zed = 'Catppuccin Latte'
        Ghostty = 'Catppuccin Latte'
    }
} else {
    @{
        Variant = 'dark'
        Helix = 'dark'
        Zed = 'Catppuccin Frappé'
        Ghostty = 'Catppuccin Frappe'
    }
}

# Update Helix theme if enabled
if ($env:HELIX_ENABLED -eq '1') {
    $helixConfigDir = Join-Path $env:HOME '.config/helix'
    New-Item -ItemType Directory -Force -Path $helixConfigDir | Out-Null

    $helixTheme = @"
theme = "$($config.Helix)"
"@
    Set-Content -Path (Join-Path $helixConfigDir 'theme-override.toml') -Value $helixTheme
}

# Update Zed theme if enabled
if ($env:ZED_ENABLED -eq '1') {
    $zedConfig = Join-Path $env:HOME '.config/zed/settings.json'

    if ((Get-Command zed -ErrorAction SilentlyContinue) -and (Test-Path $zedConfig)) {
        try {
            $settings = Get-Content $zedConfig | ConvertFrom-Json -AsHashtable
            $settings.theme.mode = 'system'
            $settings | ConvertTo-Json -Depth 10 | Set-Content $zedConfig
        } catch {
            Write-Warning "Failed to update Zed config: $_"
        }
    }
}

# Update GNOME/GTK theme
if (Get-Command gsettings -ErrorAction SilentlyContinue) {
    & gsettings set org.gnome.desktop.interface color-scheme "prefer-$($config.Variant)" 2>$null
}

# Send notification
if (Get-Command notify-send -ErrorAction SilentlyContinue) {
    & notify-send 'Theme Sync' "Applied $($config.Variant) theme"
    }
