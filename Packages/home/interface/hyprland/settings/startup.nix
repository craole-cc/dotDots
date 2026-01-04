{
  exec-once = [
    # ============================================
    # D-Bus & Environment Setup
    # ============================================
    #~@ Update D-Bus activation environment with Wayland-specific variables
    #? This ensures GUI apps launched via D-Bus have correct display server info
    # "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

    #~@ Import environment variables into systemd user session
    #? Critical for systemd services to access Wayland display and desktop info
    # "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

    # ============================================
    # Visual Environment (Run Early)
    # ============================================
    #~@ Set cursor theme and size globally BEFORE launching apps
    #? Ensures all applications start with correct cursor
    "hyprctl setcursor Bibata-Modern-Ice 24"

    #~@ Initialize wallpaper (custom script or use hyprpaper/swaybg)
    # "init-wallpaper &"

    # ============================================
    # Terminal Daemon Servers
    # ============================================
    # Ghostty terminal daemon mode:
    # - Single instance across all windows (reduced memory footprint)
    # - Stays running when all windows are closed (instant reopening)
    # - No initial window (spawn via keybind when needed)
    # "ghostty --gtk-single-instance=true --quit-after-last-window-closed=false --initial-window=false &"

    # Foot terminal server daemon
    # - Faster terminal spawning (use 'footclient' to connect)
    # - Shared server process reduces resource usage
    # - Spawn clients with: footclient or 'foot --server'
    # "foot --server &"

    # ============================================
    # System Tray & Background Services
    # ============================================
    # NetworkManager applet for WiFi/network management from tray
    # "nm-applet &"

    # Battery/power alert daemon for low battery notifications
    # "poweralertd &"

    # Persist clipboard contents across application closures
    # Monitors both regular and primary selection clipboards
    # "wl-clip-persist --clipboard both &"

    # Clipboard history manager - stores clipboard for later recall
    # Access history with: cliphist list | wofi --dmenu | cliphist decode | wl-copy
    # "wl-paste --watch cliphist store &"

    # Status bar for workspaces, system info, tray icons
    # "waybar &"
    "noctalia-shell &"

    # Notification daemon (Sway Notification Center)
    # Control center accessible via keybind
    # "swaync &"

    # Vicinae server (custom service)
    # TODO: Document what this service provides
    # "vicinae server &"

    # Auto-mount removable drives with notifications
    # --smart-tray: only shows tray icon when devices are present
    "udiskie --automount --notify --smart-tray &"

    # ============================================
    # Application Launches (Workspace Assignment)
    # ============================================
    # Launch Microsoft Edge on workspace 1 silently (no focus switch)
    # Alternative: use "microsoft-edge-stable" or "microsoft-edge-dev" if needed
    "[workspace 3 silent] microsoft-edge"

    # Launch Firefox on workspace 2 silently
    "[workspace 3 silent] zen-twilight"

    # Launch Ghostty terminal window on workspace 3 silently
    # Note: Connects to daemon started above
    "[workspace 3 silent] ghostty"
    "[workspace 3 silent] footclient"

    # Alternative: Launch Foot client on workspace 3 instead of Ghostty
    "[workspace 1 silent] code"
  ];
}
