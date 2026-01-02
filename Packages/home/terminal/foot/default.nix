{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe';
  inherit (lix.applications.generators) userApplicationConfig userApplication;
  inherit (pkgs) writeShellScriptBin makeDesktopItem;

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

  #~@ Universal Theme Detection
  #? Checks multiple sources in order of priority
  #? Works with: KDE, GNOME, Cosmic, Hyprland, Sway, etc.
  detectTheme = writeShellScriptBin "foot-detect-system-theme" ''
    # Helper to check if command exists
    has_cmd() { command -v "$1" >/dev/null 2>&1; }

    #| 1. Check freedesktop portal (works with most modern DEs)
    if has_cmd dbus-send; then
      THEME=$(dbus-send --session --print-reply=literal --reply-timeout=100 \
        --dest=org.freedesktop.portal.Desktop \
        /org/freedesktop/portal/desktop \
        org.freedesktop.portal.Settings.Read \
        string:'org.freedesktop.appearance' string:'color-scheme' 2>/dev/null | \
        grep -oP 'uint32 \K\d+')

      #| 0 = no preference, 1 = dark, 2 = light
      case "$THEME" in
        1) echo "dark"; exit 0 ;;
        2) echo "light"; exit 0 ;;
      esac
    fi

    #| 2. Check GNOME settings
    if has_cmd gsettings; then
      SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "")
      case "$SCHEME" in
        *"dark"*|*"'prefer-dark'"*) echo "dark"; exit 0 ;;
        *"light"*|*"'prefer-light'"*) echo "light"; exit 0 ;;
      esac
    fi

    #| 3. Check KDE Plasma
    if [ -f "$HOME/.config/kdeglobals" ]; then
      KDE_THEME=$(grep "ColorScheme=" "$HOME/.config/kdeglobals" | cut -d= -f2)
      case "$KDE_THEME" in
        *[Dd]ark*|*[Bb]reeze[Dd]ark*) echo "dark"; exit 0 ;;
        *[Ll]ight*|*[Bb]reeze[Ll]ight*|*[Bb]reeze) echo "light"; exit 0 ;;
      esac
    fi

    #| 4. Check GTK theme
    for conf in "$HOME/.config/gtk-4.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"; do
      if [ -f "$conf" ]; then
        GTK_THEME=$(grep "^gtk-theme-name" "$conf" | cut -d= -f2 | tr -d ' "')
        case "$GTK_THEME" in
          *[Dd]ark*) echo "dark"; exit 0 ;;
          *[Ll]ight*) echo "light"; exit 0 ;;
        esac
      fi
    done

    #| 5. Check environment variables
    case "$GTK_THEME:$QT_STYLE_OVERRIDE" in
      *[Dd]ark*) echo "dark"; exit 0 ;;
      *[Ll]ight*) echo "light"; exit 0 ;;
    esac

    #| 6. Time-based fallback (6am-6pm = light, otherwise dark)
    HOUR=$(date +%H)
    if [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 18 ]; then
      echo "light"
    else
      echo "dark"
    fi
  '';

  #~@ Feet Wrapper Components
  feet = {
    command = writeShellScriptBin "feet" ''
      SOCKET="/run/user/$UID/foot-wayland-0.sock"

      #> Detect current system theme
      THEME=$(${detectTheme}/bin/detect-system-theme)

      #> Map theme to foot's numeric values (1=dark, 2=light)
      if [ "$THEME" = "light" ]; then
        FOOT_THEME=2
      else
        FOOT_THEME=1
      fi

      #> Check if server is running
      SERVER_RUNNING=false
      if pgrep -x "foot" >/dev/null && [ -S "$SOCKET" ]; then
        SERVER_RUNNING=true
      fi

      #> Theme change detection
      if [ "$SERVER_RUNNING" = true ]; then
        THEME_FILE="/tmp/foot-theme-$UID"
        LAST_THEME=""
        [ -f "$THEME_FILE" ] && LAST_THEME=$(cat "$THEME_FILE")

        if [ "$LAST_THEME" != "$THEME" ]; then
          echo "Theme changed from '$LAST_THEME' to '$THEME', restarting foot server..."
          pkill -x foot
          sleep 0.3
          SERVER_RUNNING=false
        fi
      fi

      #> Start server if needed with correct theme
      if [ "$SERVER_RUNNING" = false ]; then
        echo "$THEME" > "/tmp/foot-theme-$UID"

        # Start server - foot will use initial-color-theme from config
        # But we can override with --initial-color-theme
        ${foot} --server --initial-color-theme=$FOOT_THEME >/dev/null 2>&1 &

        for i in {1..20}; do
          [ -S "$SOCKET" ] && break
          sleep 0.1
        done
      fi

      exec ${footclient} --server-socket="$SOCKET" "$@"
    '';

    wrapper = makeDesktopItem {
      name = "feet";
      desktopName = "Feet Terminal";
      comment = "Fast, lightweight terminal emulator (server mode)";
      exec = "feet";
      icon = "foot";
      terminal = false;
      type = "Application";
      categories = ["System" "TerminalEmulator"];
    };
  };

  #~@ Final Configuration Assembly
  cfg = userApplicationConfig {
    inherit app user pkgs config;
    extraPackages = with feet; [command wrapper detectTheme];
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
  };
}
