{
  config,
  options,
  lix,
  user,
  pkgs,
  style,
  ...
}: let
  inherit (lix.attrsets.aggregation) mergeSafe;
  inherit (lix.modules.construction) mkContext mkConfig mkMerge mkLayer;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.lists.transformation) filter;
  inherit (lix.types.combinators) attrsOf either listOf nullOr oneOf;
  inherit (lix.types.primitives) bool int float str;
  inherit (lix.toolkit) packages;
  inherit (context) cfg;

  settingValue = nullOr (oneOf [bool int float str]);

  context = mkContext {
    inherit config;
    dom = "terminal";
    sub = "emulators";
    mod = "ghostty";
  };

  defaults = {
    enable = false;
    package = packages.ghostty;
    settings = mergeSafe [
      (import ./general.nix {})
      (import ./input.nix {})
    ];
    home = {
      packages = [];
      sessionVariables = {};
      shellAliases = {};
    };
  };

  resolved = userApplicationConfig {
    inherit context user pkgs;
    debug = false;
  };
in
  mkConfig {
    inherit context defaults;
    options = {
      enable = mkEnable {
        inherit context;
        condition = defaults.enable;
      };
      package = mkOption {
        description = "Ghostty package to install";
        inherit (options.programs.ghostty.package) type;
        default = defaults.package;
      };
      settings = mkOption {
        description = "Ghostty settings, including keybindings";
        type = attrsOf (either settingValue (listOf settingValue));
        default = defaults.settings;
      };
      home = {
        packages = mkOption {
          description = "Additional packages installed alongside Ghostty";
          inherit (options.home.packages) type;
          default = defaults.home.packages;
        };
        sessionVariables = mkOption {
          description = "Session variables provided by Ghostty";
          inherit (options.home.sessionVariables) type;
          default = defaults.home.sessionVariables;
        };
        shellAliases = mkOption {
          description = "Shell aliases provided by Ghostty";
          inherit (options.home.shellAliases) type;
          default = defaults.home.shellAliases;
        };
      };
    };
    resolutions = mkMerge [
      (mkLayer 1000 {
        inherit (resolved) enable package;
        settings = defaults.settings // {background-opacity = style.opacity.terminal.dark;};
        home = {
          packages =
            filter
            (package: package != resolved.package)
            (resolved.home.packages or []);
          sessionVariables = resolved.home.sessionVariables or {};
          shellAliases = resolved.home.shellAliases or {};
        };
      })
      (import ./themes.nix {inherit config lix context;})
    ];
    outputs = {
      programs.ghostty = {inherit (cfg) enable package settings;};
      inherit (cfg) home;
    };
  }
