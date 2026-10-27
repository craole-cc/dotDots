{
  config,
  lix,
  user,
  inputs,
  toolkit,
  pkgs,
  style,
  entryAfter,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "panels";
    mod = "dms-shell";
  };
  inherit (context) cfg ctx;
  inherit (lix.attrsets.aggregation) mergeSafe;
  inherit (lix.modules.construction) mkConfig mkContext mkForce;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.styles.icons.types) icon;
  inherit (lix.filesystem.primitives) concat;

  args = {
    inherit (toolkit.records) quickshell dms-shell;
    inherit binaries;
    inherit config inputs lix pkgs style themes user entryAfter toolkit;
    configHome =
      config.xdg.configHome or (concat {
        root = user.home;
        stem = ".config";
      });

    stateHome =
      config.xdg.stateHome or (concat {
        root = user.home;
        stem = ".local/state";
      });
  };

  inherit (import ./packages.nix args) binaries package;
  themes = import ./themes args;
  sync = import ./sync.nix args;
  activation = import ./activation.nix args;
  addons = import ./plugins args;
  pluginSettings = toolkit.write.json "dms-plugin-settings.json" (user.dms.plugins or {});
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable ({inherit context;} // ctx.wantsDmsShell);
      icons = mkOption {
        description = "Resolved DMS desktop icon contract";
        default = themes.icons.resolved;
        type = icon.home;
        readOnly = true;
      };
    };

    outputs = {
      programs.dank-material-shell = {
        inherit (cfg) enable;
        managePluginSettings = false;
        settings = (user.dms.settings or {}) // {
          customThemeFile = "${args.configHome}/DankMaterialShell/themes/catppuccin.json";
        };
        inherit (addons) plugins;
        inherit package;
        quickshell = {inherit (args.quickshell) package;};
        systemd = {
          enable = true;
          target = "graphical-session.target";
        };
      };

      xdg = {
        configFile = mergeSafe (
          [addons.files {"DankMaterialShell/plugin_settings.json".source = pluginSettings;}]
          ++ map (theme: theme.configFile) (with themes; [
            catppuccin
            foot
            hermes
            helix
          ])
        );
        inherit (themes) dataFile;
      };

      gtk = {
        enable = mkForce true;
        iconTheme = mkForce {inherit (cfg.icons) package name;};
      };

      home = {
        packages =
          (with themes.resolved.cursors; [
            dark.package
            light.package
          ])
          ++ addons.packages;
        sessionVariables = {
          QS_ICON_THEME = themes.icons.dark.theme;
        };
        activation =
          {
            configureDmsTheme = activation;
            migrateDmsPlugins = addons.migration;
          }
          // (with themes; {
            configureDmsHelixTheme = helix.activation;
            # configureDmsFootTheme = foot.activation;  # future
          });
      };

      systemd = import ./services.nix {inherit config lix sync;};
    };
  }
