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
  dom = "interface";
  sub = "panels";
  mod = "dux-shell";
  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg ctx;
  quickshell = config.${context.top}.resolved.interface.panels.quickshell.defined;
  inherit (lix.attrsets.aggregation) mergeSafe recursiveUpdate;
  inherit (lix.modules.construction) mkConfig mkContext mkForce;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.styles.icons.types) icon;
  inherit (lix.filesystem.primitives) concat;
  inherit (lix.types.combinators) attrsOf;
  inherit (lix.types.primitives) package anything;
  inherit (lix.toolkit) packages;
  record = lix.toolkit.records.dux-shell;
  defaults = import ./defaults {inherit lix;};

  args = recursiveUpdate record {
    inherit config inputs lix pkgs style themes user entryAfter;
    dms = recursiveUpdate cfg (user.interface.dms or {});
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
        description = "Package to use for dux-shell";
        default = record;
        type = attrsOf anything;
        readOnly = true;
      };
      package = mkOption {
        description = "Package to use";
        default = record.package;
        type = package;
      };
      settings = mkOption {
        description = "DMS shell settings";
        default = defaults.settings;
        type = attrsOf anything;
      };
      schema = mkOption {
        description = "Reference schema for DMS settings and plugin data";
        default = defaults.schema;
        type = attrsOf anything;
      };
      plugins = mkOption {
        description = "DMS plugin settings";
        default = defaults.plugins;
        type = attrsOf anything;
      };
      session = mkOption {
        description = "DMS session settings";
        default = defaults.session;
        type = attrsOf anything;
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
        # Supply Khal through the toolkit instead of the upstream package set.
        enableCalendarEvents = false;
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
            yazi
          ])
        );
        inherit (themes) dataFile;
      };

      gtk = {
        enable = mkForce true;
        iconTheme = mkForce {inherit (cfg.icons) package name;};
      };

      catppuccin.yazi.enable = mkForce false;

      home = {
        packages =
          (with themes.resolved.cursors; [dark.package light.package])
          ++ addons.packages
          ++ (with packages; [dux-calendar dux-files khal vdirsyncer]);
        sessionVariables = {QS_ICON_THEME = themes.icons.dark.theme;};
        activation =
          {
            configureDmsTheme = activation;
            migrateDmsPlugins = addons.migration;
          }
          // (with themes; {
            configureDmsHelixTheme = helix.activation;
            configureDmsYaziTheme = yazi.activation;
            # configureDmsFootTheme = foot.activation;  # future
          });
      };

      systemd = import ./services.nix {inherit config lix sync;};
    };
  }
