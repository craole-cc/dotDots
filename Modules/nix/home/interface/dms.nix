{
  config,
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lib.hm.dag) entryAfter;
  inherit (lib.modules) mkForce;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.styles.icons) mkIcon;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (pkgs) coreutils dms-shell jq quickshell;

  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "panels";
    mod = "dms-shell";
  };
  inherit (context) cfg ctx;

  style = user.style or {};
  polarity = (style.theme or {}).polarity or "dark";
  iconStyle = style.icons or {};
  resolvedIcons = mkIcon {
    inherit pkgs polarity;
    icon = iconStyle.${polarity} or null;
  };

  iconTheme = cfg.icons.name;
  themeName = "dotdots-catppuccin";
  themeFile = ./themes/dms-catppuccin.json;
  themePath = "${config.xdg.configHome}/DankMaterialShell/themes/${themeName}.json";
  footFallback = pkgs.writeText "dms-foot-fallback.ini" ''
    [colors-dark]
    foreground=c6d0f5
    background=303446
    selection-foreground=c6d0f5
    selection-background=51576d
    cursor=303446 ca9ee6

    regular0=51576d
    regular1=e78284
    regular2=a6d189
    regular3=e5c890
    regular4=8caaee
    regular5=ca9ee6
    regular6=81c8be
    regular7=b5bfe2
    bright0=626880
    bright1=e78284
    bright2=a6d189
    bright3=e5c890
    bright4=8caaee
    bright5=ca9ee6
    bright6=81c8be
    bright7=c6d0f5
  '';
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable ({inherit context;} // ctx.wantsDmsShell);
      icons = mkOption {
        description = "Resolved DMS desktop icon contract";
        default = resolvedIcons;
        type = lix.styles.icons.types.icon.home;
        readOnly = true;
      };
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

      xdg = {
        configFile."DankMaterialShell/themes/${themeName}.json".source = themeFile;
        dataFile."icons/${cfg.icons.name}".source =
          "${cfg.icons.package}/share/icons/${cfg.icons.name}";
      };

      gtk = {
        enable = mkForce true;
        iconTheme = mkForce {inherit (cfg.icons) package name;};
      };

      home.sessionVariables.QS_ICON_THEME = cfg.icons.name;

      # DMS owns its mutable settings file. Preserve the user's bar/widget/etc.
      # settings and only assert the declarative dotDots theme selection.
      home.activation.configureDmsTheme = entryAfter ["writeBoundary"] ''
        settings="$HOME/.config/DankMaterialShell/settings.json"
        foot_theme="$HOME/.config/foot/dank-colors.ini"
        theme=${escapeShellArg themePath}
        icons=${escapeShellArg iconTheme}
        tmp="$(${coreutils}/bin/mktemp)"
        trap '${coreutils}/bin/rm -f "$tmp"' EXIT

        $DRY_RUN_CMD ${coreutils}/bin/mkdir -p "$(${coreutils}/bin/dirname "$settings")"
        $DRY_RUN_CMD ${coreutils}/bin/mkdir -p "$(${coreutils}/bin/dirname "$foot_theme")"
        if [ ! -e "$foot_theme" ]; then
          $DRY_RUN_CMD ${coreutils}/bin/install -m 0644 ${footFallback} "$foot_theme"
        fi

        if [ -L "$settings" ]; then
          echo "Refusing to replace managed DMS settings symlink: $settings" >&2
          exit 1
        fi

        if [ -f "$settings" ]; then
          ${jq}/bin/jq --arg theme "$theme" --arg icons "$icons" '
            . + {
              currentThemeName: "custom",
              currentThemeCategory: "custom",
              customThemeFile: $theme,
              runDmsMatugenTemplates: true,
              matugenTemplateGtk: true,
              matugenTemplateFoot: true,
              matugenTemplateVscode: true,
              iconThemeDark: $icons,
              iconThemeLight: $icons,
              iconThemePerMode: false
            }
          ' "$settings" > "$tmp"
        else
          ${jq}/bin/jq -n --arg theme "$theme" --arg icons "$icons" '{
            currentThemeName: "custom",
            currentThemeCategory: "custom",
            customThemeFile: $theme,
            runDmsMatugenTemplates: true,
            matugenTemplateGtk: true,
            matugenTemplateFoot: true,
            matugenTemplateVscode: true,
            iconThemeDark: $icons,
            iconThemeLight: $icons,
            iconThemePerMode: false
          }' > "$tmp"
        fi

        $DRY_RUN_CMD ${coreutils}/bin/install -m 0600 "$tmp" "$settings"

        # Set dependencies first. currentThemeName is last because changing it
        # loads the custom file and regenerates all enabled Matugen consumers.
        $DRY_RUN_CMD ${dms-shell}/bin/dms ipc call settings set customThemeFile "$theme" >/dev/null 2>&1 || true
        $DRY_RUN_CMD ${dms-shell}/bin/dms ipc call settings set runDmsMatugenTemplates true >/dev/null 2>&1 || true
        $DRY_RUN_CMD ${dms-shell}/bin/dms ipc call settings set matugenTemplateGtk true >/dev/null 2>&1 || true
        $DRY_RUN_CMD ${dms-shell}/bin/dms ipc call settings set matugenTemplateFoot true >/dev/null 2>&1 || true
        $DRY_RUN_CMD ${dms-shell}/bin/dms ipc call settings set matugenTemplateVscode true >/dev/null 2>&1 || true
        $DRY_RUN_CMD ${dms-shell}/bin/dms ipc call settings set iconThemeDark "$icons" >/dev/null 2>&1 || true
        $DRY_RUN_CMD ${dms-shell}/bin/dms ipc call settings set iconThemeLight "$icons" >/dev/null 2>&1 || true
        $DRY_RUN_CMD ${dms-shell}/bin/dms ipc call settings set iconThemePerMode false >/dev/null 2>&1 || true
        $DRY_RUN_CMD ${dms-shell}/bin/dms ipc call settings set currentThemeCategory custom >/dev/null 2>&1 || true
        $DRY_RUN_CMD ${dms-shell}/bin/dms ipc call settings set currentThemeName custom >/dev/null 2>&1 || true
      '';
    };
  }
