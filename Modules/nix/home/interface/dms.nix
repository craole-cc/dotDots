{
  config,
  lib,
  lix,
  pkgs,
  ...
}: let
  inherit (lib.hm.dag) entryAfter;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (pkgs) coreutils dms-shell jq quickshell;

  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "panels";
    mod = "dms-shell";
  };
  inherit (context) cfg ctx;

  themeName = "dotdots-catppuccin";
  themeFile = ./themes/dms-catppuccin.json;
  themePath = "${config.xdg.configHome}/DankMaterialShell/themes/${themeName}.json";
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable ({inherit context;} // ctx.wantsDmsShell);
    };
    outputs = {
      programs.dank-material-shell = {
        enable = cfg.enable;

        # The flake module is still used for Home Manager integration, but its
        # pinned package closure is expensive to rebuild locally. Victus tracks
        # nixos-unstable, where both packages are available from nixpkgs and can
        # normally be substituted from cache.nixos.org.
        package = dms-shell;
        quickshell.package = quickshell;
      };

      xdg.configFile."DankMaterialShell/themes/${themeName}.json".source = themeFile;

      # DMS owns its mutable settings file. Preserve the user's bar/widget/etc.
      # settings and only assert the declarative dotDots theme selection.
      home.activation.configureDmsTheme = entryAfter ["writeBoundary"] ''
        settings="$HOME/.config/DankMaterialShell/settings.json"
        theme=${escapeShellArg themePath}
        tmp="$(${coreutils}/bin/mktemp)"
        trap '${coreutils}/bin/rm -f "$tmp"' EXIT

        $DRY_RUN_CMD ${coreutils}/bin/mkdir -p "$(${coreutils}/bin/dirname "$settings")"

        if [ -L "$settings" ]; then
          echo "Refusing to replace managed DMS settings symlink: $settings" >&2
          exit 1
        fi

        if [ -f "$settings" ]; then
          ${jq}/bin/jq --arg theme "$theme" \
            '. + {currentThemeName: "custom", customThemeFile: $theme}' \
            "$settings" > "$tmp"
        else
          ${jq}/bin/jq -n --arg theme "$theme" \
            '{currentThemeName: "custom", customThemeFile: $theme}' \
            > "$tmp"
        fi

        $DRY_RUN_CMD ${coreutils}/bin/install -m 0600 "$tmp" "$settings"

        # Apply immediately when DMS is already running; the persisted JSON is
        # still authoritative when the service is not active during activation.
        $DRY_RUN_CMD ${dms-shell}/bin/dms ipc call settings set currentThemeName custom >/dev/null 2>&1 || true
        $DRY_RUN_CMD ${dms-shell}/bin/dms ipc call settings set customThemeFile "$theme" >/dev/null 2>&1 || true
      '';
    };
  }
