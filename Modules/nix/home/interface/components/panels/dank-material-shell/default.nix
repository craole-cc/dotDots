{
  config,
  lix,
  user,
  inputs,
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
  quickshell = context.resolved.cfg.interface.panels.quickshell.explicit;
  dcalPackage = inputs.nixPackages.legacyPackages.${pkgs.stdenv.hostPlatform.system}.dux-calendar;
  inherit (lix.attrsets.aggregation) mergeSafe recursiveUpdate;
  inherit (lix.modules.construction) mkConfig mkContext mkForce;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.styles.icons.types) icon;
  inherit (lix.filesystem.primitives) concat;
  inherit (lix.types.combinators) attrsOf;
  inherit (lix.types.primitives) package anything;
  inherit (lix.toolkit) packages;

  record = import ./record.nix {inherit pkgs inputs lix;};
  args = recursiveUpdate record {
    inherit config inputs lix pkgs style themes user entryAfter;
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

  themes = import ./themes args;
  sync = import ./sync.nix args;
  activation = import ./activation.nix args;
  addons = import ./plugins args;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable ({inherit context;} // ctx.wantsDmsShell);
      record = mkOption {
        description = "Package to use for dms-shell";
        default = record;
        type = attrsOf anything;
        readOnly = true;
      };
      package = mkOption {
        description = "Package to use";
        default = record.package;
        type = package;
      };
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
        settings = {};
        clipboardSettings = {};
        session = {};
        inherit (addons) plugins;
        inherit (cfg) package;
        quickshell.package = quickshell.package;
        systemd = {
          enable = true;
          target = "graphical-session.target";
        };
      };

      xdg = {
        configFile = mergeSafe (
          [addons.files]
          ++ map (theme: theme.configFile) (with themes; [
            catppuccin
            accent
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
          ++ addons.packages
          ++ [
            dcalPackage
            pkgs.khal
            pkgs.vdirsyncer
          ];
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

      systemd = import ./services.nix {inherit config dcalPackage lix pkgs quickshell sync;};
    };
  }
