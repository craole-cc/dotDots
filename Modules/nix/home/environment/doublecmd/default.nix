{
  apps,
  config,
  fonts,
  lib,
  lix,
  pkgs,
  style,
  user,
  ...
}: let
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.lists.access) elemAt head;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.strings.construction) toJSON;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (lix.styles.palettes) mkTerminalPalette;
  inherit (lix.toolkit) write;

  context = mkContext {
    inherit config;
    dom = "environment";
    mod = "doublecmd";
  };
  appearance = write.rust {
    name = "dotdots-doublecmd-appearance";
    src = ./appearance.rs;
  };
  configHome = config.xdg.configHome;
  directory = "${configHome}/doublecmd";
  palettePath = "${config.xdg.cacheHome}/dms/dms-colors.json";
  font = role: let
    selected = head fonts.categories.${role};
  in {
    name = selected.family;
    inherit (selected) size;
  };
  fallback = write.text "doublecmd-appearance.json" (toJSON {
    inherit (style) mode;
    fonts = {
      general = font "sansSerif";
      fixed = font "monospace";
    };
    icons = {
      dark = config.themes.icons.dark.name;
      light = config.themes.icons.light.name;
    };
    palettes = mapAttrs (_: mode: let
      palette = mkTerminalPalette mode;
    in {
      inherit (palette) foreground background;
      surface = palette.selectionBackground;
      primary = palette.cursor;
      onPrimary = palette.background;
      outline = elemAt palette.bright 0;
      error = elemAt palette.regular 1;
      success = elemAt palette.regular 2;
      link = elemAt palette.regular 4;
    }) {inherit (user.theme.modes) dark light;};
  });
  appearanceCommand = "${appearance}/bin/dotdots-doublecmd-appearance --config ${escapeShellArg directory} --defaults ${fallback} --palette ${escapeShellArg palettePath}";
  launcher = write.bin "doublecmd" ''
    ${appearanceCommand}
    export QT_QPA_PLATFORMTHEME=qt5ct
    unset QT_STYLE_OVERRIDE
    export QT_PLUGIN_PATH="${pkgs.libsForQt5.qt5ct}/${pkgs.qt5.qtbase.qtPluginPrefix}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
    exec ${pkgs.doublecmd}/bin/doublecmd --config-dir=${escapeShellArg directory} "$@"
  '';
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = apps.needs "doublecmd";
    };
    outputs = {
      home.packages = [(lib.hiPrio launcher) pkgs.libsForQt5.qt5ct];
      systemd.user = {
        services.dotdots-doublecmd-appearance = {
          Unit = {
            Description = "Apply DMS palette changes to running Qt5 applications";
            PartOf = ["graphical-session.target"];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${appearanceCommand} --live";
          };
          Install.WantedBy = ["graphical-session.target"];
        };
        paths.dotdots-doublecmd-appearance = {
          Unit = {
            Description = "Watch the DMS palette for Double Commander";
            PartOf = ["graphical-session.target"];
          };
          Path.PathChanged = palettePath;
          Install.WantedBy = ["graphical-session.target"];
        };
      };
      xdg.desktopEntries.doublecmd = {
        name = "Double Commander";
        genericName = "File Manager";
        exec = "${launcher}/bin/doublecmd %F";
        icon = "doublecmd";
        terminal = false;
        categories = ["System" "FileTools" "FileManager"];
        mimeType = ["inode/directory"];
      };
    };
  }
