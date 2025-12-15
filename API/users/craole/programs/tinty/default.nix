# mod/theme.nix
{
  lib,
  pkgs,
  config,
  ...
}:
let
  HOME = config.home.homeDirectory;
  themesDir = "${HOME}/.local/share/tinted-theming/tinty/themes";
  inherit (lib.modules) mkIf mkForce;
  inherit (lib.strings) optionalString;
  inherit (lib.hm.dag) entryAfter;
  isEnabled = pkg: config.programs.${pkg}.enable;

  # Script that syncs tinty's theme to enabled apps only
  syncThemes = pkgs.writeShellScript "sync-tinty-themes" ''
    #!/bin/sh
    CURRENT=$(${pkgs.tinty}/bin/tinty current 2>/dev/null)

    case "$CURRENT" in
      *light*)
        VARIANT="light"
        HELIX_THEME="catppuccin_latte"
        ZED_THEME="Catppuccin Latte"
        GHOSTTY_THEME="Catppuccin Latte"
        ;;
      *)
        VARIANT="dark"
        HELIX_THEME="catppuccin_frappe"
        ZED_THEME="Catppuccin Frappé"
        GHOSTTY_THEME="Catppuccin Frappe"
        ;;
    esac

    ${optionalString (isEnabled "helix") ''
            # Update Helix theme
            mkdir -p "${HOME}/.config/helix"
            cat > "${HOME}/.config/helix/theme-override.toml" <<EOF
      theme = "$HELIX_THEME"
      EOF
    ''}

    ${optionalString (isEnabled "zed-editor") ''
      # Update Zed theme (follows system mode)
      if command -v zed >/dev/null 2>&1 && [ -f "${HOME}/.config/zed/settings.json" ]; then
        ${pkgs.jq}/bin/jq ".theme.mode = \"system\"" \
          "${HOME}/.config/zed/settings.json" > "${HOME}/.config/zed/settings.json.tmp" && \
          mv "${HOME}/.config/zed/settings.json.tmp" "${HOME}/.config/zed/settings.json"
      fi
    ''}

    # Update GNOME/GTK for system-wide theme
    if command -v gsettings >/dev/null 2>&1; then
      gsettings set org.gnome.desktop.interface color-scheme "prefer-$VARIANT"
    fi

    # Notify user
    if command -v notify-send >/dev/null 2>&1; then
      notify-send "Theme Sync" "Applied $VARIANT theme"
    fi
  '';
in
{
  home.packages = with pkgs; [
    tinty
    (writeShellScriptBin "sync-themes" ''${syncThemes}'')
  ];

  # Link all themes to tinty's expected location
  home.activation.setupTintyThemes = entryAfter [ "writeBoundary" ] ''
    mkdir -p ${themesDir}
    cd ${themesDir}

    for theme in ${HOME}/Configuration/assets/themes/*.yaml; do
      basename=$(basename "$theme")
      if grep -q 'system: "base16"' "$theme" 2>/dev/null; then
        prefix="base16-"
      elif grep -q 'system: "base24"' "$theme" 2>/dev/null; then
        prefix="base24-"
      else
        continue
      fi

      case "$basename" in
        base16-*|base24-*)
          ln -sf "$theme" "$basename"
          ;;
        *)
          ln -sf "$theme" "''${prefix}''${basename}"
          ;;
      esac
    done
  '';

  xdg.configFile."tinted-theming/tinty/config.toml".text = ''
    [[items]]
    path = "${themesDir}"
    name = "schemes"
    themes-dir = "${themesDir}"

    shell-hook-path = "${HOME}/.config/tinty/hook.sh"
  '';

  programs = {
    helix = mkIf (isEnabled "helix") {
      settings.theme = mkForce "catppuccin_latte";
    };

    bash.initExtra = mkIf (isEnabled "bash") ''
      # Sync themes on shell start
      command -v sync-themes >/dev/null 2>&1 && sync-themes
    '';

    zsh.initExtra = mkIf (isEnabled "zsh") ''
      # Sync themes on shell start
      command -v sync-themes >/dev/null 2>&1 && sync-themes
    '';
  };
}
