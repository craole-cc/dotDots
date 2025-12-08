#!/usr/bin/env nu

# Get current tinty theme
let current = (tinty current | complete | get stdout | str trim)

# Determine theme variant
let config = if ($current | str contains 'light') {
    {
        variant: 'light'
        helix: 'light'
        zed: 'Catppuccin Latte'
        ghostty: 'Catppuccin Latte'
    }
} else {
    {
        variant: 'dark'
        helix: 'dark'
        zed: 'Catppuccin Frappé'
        ghostty: 'Catppuccin Frappe'
    }
}

# Update Helix theme if enabled
if ($env.HELIX_ENABLED? == '1') {
    let helix_dir = ($env.HOME | path join '.config' 'helix')
    mkdir $helix_dir

    $"theme = \"($config.helix)\"\n" | save -f ($helix_dir | path join 'theme-override.toml')
}

# Update Zed theme if enabled
if ($env.ZED_ENABLED? == '1') {
    let zed_config = ($env.HOME | path join '.config' 'zed' 'settings.json')

    if (which zed | is-not-empty) and ($zed_config | path exists) {
        try {
            let settings = (open $zed_config)
            let updated = ($settings | upsert theme.mode 'system')
            $updated | to json | save -f $zed_config
        } catch {
            print $"(ansi red)Failed to update Zed config: ($in)(ansi reset)"
        }
    }
}

# Update GNOME/GTK theme
if (which gsettings | is-not-empty) {
    gsettings set org.gnome.desktop.interface color-scheme $"prefer-($config.variant)" | complete | null
}

# Send notification
if (which notify-send | is-not-empty) {
    notify-send 'Theme Sync' $"Applied ($config.variant) theme" | complete | null
}
