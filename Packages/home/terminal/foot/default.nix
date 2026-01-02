{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lib.meta) getExe';
  inherit (lib.modules) mkIf;
  inherit (lib.strings) replaceStrings readFile;
  inherit (lix.applications.generators) userApplicationConfig userApplication;
  inherit (pkgs) makeDesktopItem;

  #~@ Application Configuration
  app = userApplication {
    inherit user pkgs config;
    name = "foot";
    kind = "terminal";
    customCommand = "feet";
    resolutionHints = ["foot" "feet"];
    requiresWayland = true;
  };

  #~@ Executable Paths
  foot = getExe' app.package "foot";
  footclient = getExe' app.package "footclient";

  #~@ Consolidated Theme Manager Script
  #? Single script that handles detection, monitoring, and theme application
  themeManager = pkgs.writeShellScriptBin "foot-theme-manager" ''
    #!/bin/sh
    #~@ Foot Theme Manager
    #? Unified theme detection, monitoring, and application

    USER_ID=$(id -u)
    THEME_FILE="/tmp/foot-theme-$USER_ID"
    SOCKET="/run/user/$USER_ID/foot-wayland-0.sock"

    #> Helper to check if command exists
    has_cmd() { command -v "$1" >/dev/null 2>&1; }

    #> Theme Detection Function
    detect_theme() {
      #| 1. Check KDE Plasma
      if [ -f "$HOME/.config/kdeglobals" ]; then
        KDE_SCHEME=$(grep "^ColorScheme=" "$HOME/.config/kdeglobals" | head -1 | cut -d= -f2)
        case "$KDE_SCHEME" in
          *[Dd]ark*)
            echo "dark"
            return 0
            ;;
          *[Ll]ight*)
            echo "light"
            return 0
            ;;
          *)
            INACTIVE_COLOR=$(grep -A5 "^\[ColorEffects:Inactive\]" "$HOME/.config/kdeglobals" | grep "^Color=" | cut -d= -f2)
            if [ -n "$INACTIVE_COLOR" ]; then
              R=$(echo "$INACTIVE_COLOR" | cut -d, -f1)
              if [ "$R" -gt 100 ] 2>/dev/null; then
                echo "light"
                return 0
              else
                echo "dark"
                return 0
              fi
            fi
            ;;
        esac
      fi

      #| 2. Check freedesktop portal
      if has_cmd dbus-send; then
        THEME=$(dbus-send --session --print-reply=literal --reply-timeout=100 \
          --dest=org.freedesktop.portal.Desktop \
          /org/freedesktop/portal/desktop \
          org.freedesktop.portal.Settings.Read \
          string:'org.freedesktop.appearance' string:'color-scheme' 2>/dev/null |
          grep -oE 'uint32 [0-9]+' | awk '{print $2}')

        case "$THEME" in
          1)
            echo "dark"
            return 0
            ;;
          2)
            echo "light"
            return 0
            ;;
        esac
      fi

      #| 3. Check GNOME settings
      if has_cmd gsettings; then
        SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "")
        case "$SCHEME" in
          *dark*|*prefer-dark*)
            echo "dark"
            return 0
            ;;
          *light*|*prefer-light*)
            echo "light"
            return 0
            ;;
        esac
      fi

      #| 4. Check GTK theme
      for conf in "$HOME/.config/gtk-4.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"; do
        if [ -f "$conf" ]; then
          GTK_THEME=$(grep "^gtk-theme-name" "$conf" | cut -d= -f2 | tr -d ' "')
          case "$GTK_THEME" in
            *[Dd]ark*)
              echo "dark"
              return 0
              ;;
            *[Ll]ight*)
              echo "light"
              return 0
              ;;
          esac
        fi
      done

      #| 5. Check environment variables
      case "''${GTK_THEME:-}:''${QT_STYLE_OVERRIDE:-}" in
        *[Dd]ark*)
          echo "dark"
          return 0
          ;;
        *[Ll]ight*)
          echo "light"
          return 0
          ;;
      esac

      #| 6. Time-based fallback
      HOUR=$(date +%H)
      if [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 18 ]; then
        echo "light"
      else
        echo "dark"
      fi
    }

    #> Theme Monitor Mode
    monitor_mode() {
      echo "Starting foot theme monitor..."

      # Initialize theme file
      CURRENT_THEME=$(detect_theme)
      echo "$CURRENT_THEME" > "$THEME_FILE"
      echo "Initial theme: $CURRENT_THEME"

      while true; do
        sleep 2
        NEW_THEME=$(detect_theme)

        if [ -f "$THEME_FILE" ]; then
          LAST_THEME=$(cat "$THEME_FILE")

          if [ "$LAST_THEME" != "$NEW_THEME" ]; then
            echo "Theme changed: $LAST_THEME → $NEW_THEME"
            echo "$NEW_THEME" > "$THEME_FILE"

            # Restart foot server
            if pgrep -x foot >/dev/null; then
              echo "Restarting foot server..."
              pkill -x foot
              sleep 0.5

              # Start with correct theme
              if [ "$NEW_THEME" = "light" ]; then
                ${foot} --server -o main.initial-color-theme=2 >/dev/null 2>&1 &
              else
                ${foot} --server -o main.initial-color-theme=1 >/dev/null 2>&1 &
              fi
            fi
          fi
        fi
      done
    }

    #> Quake Mode
    quake_mode() {
      QUAKE_ID="foot-quake"

      if pgrep -f "$QUAKE_ID" >/dev/null; then
        if command -v hyprctl >/dev/null 2>&1; then
          hyprctl dispatch togglespecialworkspace quake
        elif command -v swaymsg >/dev/null 2>&1; then
          swaymsg '[app_id="'$QUAKE_ID'"]' scratchpad show
        else
          pkill -f "$QUAKE_ID"
        fi
      else
        if command -v hyprctl >/dev/null 2>&1; then
          ${footclient} \
            --app-id="$QUAKE_ID" \
            --window-size-chars=200x50 \
            --server-socket="$SOCKET" &
          sleep 0.1
          hyprctl dispatch movetoworkspacesilent special:quake,"$QUAKE_ID"
          hyprctl dispatch togglespecialworkspace quake
        elif command -v swaymsg >/dev/null 2>&1; then
          ${footclient} \
            --app-id="$QUAKE_ID" \
            --window-size-chars=200x50 \
            --server-socket="$SOCKET" &
          sleep 0.2
          swaymsg '[app_id="'$QUAKE_ID'"]' move scratchpad
          swaymsg '[app_id="'$QUAKE_ID'"]' scratchpad show
        else
          ${footclient} \
            --app-id="$QUAKE_ID" \
            --window-size-pixels=1920x600 \
            --server-socket="$SOCKET" &
        fi
      fi
    }

    #> Main execution
    case "''${1:-}" in
      --monitor)
        monitor_mode
        ;;
      --quake)
        quake_mode
        ;;
      --detect)
        detect_theme
        ;;
      *)
        # Default: launch terminal with theme detection
        THEME=$(detect_theme)

        if [ "$THEME" = "light" ]; then
          FOOT_THEME=2
        else
          FOOT_THEME=1
        fi

        # Check if server is running
        if pgrep -x "foot" >/dev/null && [ -S "$SOCKET" ]; then
          if [ -f "$THEME_FILE" ]; then
            LAST_THEME=$(cat "$THEME_FILE")

            if [ "$LAST_THEME" != "$THEME" ]; then
              echo "Theme changed: $LAST_THEME → $THEME (restarting server...)"
              pkill -x foot
              sleep 0.3
            else
              exec ${footclient} --server-socket="$SOCKET" "$@"
            fi
          else
            exec ${footclient} --server-socket="$SOCKET" "$@"
          fi
        fi

        # Save current theme and start server
        echo "$THEME" > "$THEME_FILE"
        ${foot} --server -o main.initial-color-theme="$FOOT_THEME" >/dev/null 2>&1 &

        # Wait for socket
        i=0
        while [ $i -lt 20 ]; do
          if [ -S "$SOCKET" ]; then
            sleep 0.1
            break
          fi
          sleep 0.1
          i=$((i + 1))
        done

        exec ${footclient} --server-socket="$SOCKET" "$@"
        ;;
    esac
  '';

  #~@ Wrapper Scripts
  feet = {
    command = pkgs.writeShellScriptBin "feet" ''
      exec ${themeManager}/bin/foot-theme-manager "$@"
    '';

    quake = pkgs.writeShellScriptBin "feet-quake" ''
      exec ${themeManager}/bin/foot-theme-manager --quake
    '';

    desktop = makeDesktopItem {
      name = "feet";
      desktopName = "Feet Terminal";
      comment = "Fast, lightweight terminal emulator (server mode)";
      exec = "feet";
      icon = "foot";
      terminal = false;
      type = "Application";
      categories = ["System" "TerminalEmulator"];
    };

    quakeDesktop = makeDesktopItem {
      name = "feet-quake";
      desktopName = "Feet Quake Terminal";
      comment = "Dropdown terminal (quake-style)";
      exec = "feet-quake";
      icon = "foot";
      terminal = false;
      type = "Application";
      categories = ["System" "TerminalEmulator"];
      noDisplay = true;
    };
  };

  #~@ Final Configuration Assembly
  cfg = userApplicationConfig {
    inherit app user pkgs config;
    extraPackages = with feet; [command quake desktop quakeDesktop themeManager];
    extraProgramConfig = {
      server.enable = true;
      settings =
        {}
        // (import ./settings.nix)
        // (import ./input.nix)
        // (import ./themes.nix)
        // {};
    };
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs home;

    #~@ Systemd User Service for Theme Monitoring
    systemd.user.services.foot-theme-monitor = {
      Unit = {
        Description = "Foot terminal theme monitor";
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${themeManager}/bin/foot-theme-manager --monitor";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
