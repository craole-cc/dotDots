{
  config,
  options,
  lix,
  pkgs,
  style,
  user,
  ...
}: let
  inherit (lix.attrsets.aggregation) mergeSafe;
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.modules.construction) mkConfig mkContext mkLayer mkMerge;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.lists.transformation) filter;
  inherit (lix.toolkit) packages;
  inherit (context) cfg;

  context = mkContext {
    inherit config;
    dom = "terminal";
    sub = "emulators";
    mod = "kitty";
  };

  defaults = {
    enable = false;
    package = packages.kitty;
    settings = mergeSafe [(import ./general.nix {})];
    extraConfig = "";
    home = {
      packages = [];
      sessionVariables = {};
      shellAliases = {};
    };
  };

  resolved = userApplicationConfig {
    inherit context user pkgs;
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
        description = "Kitty package to install";
        inherit (options.programs.kitty.package) type;
        default = defaults.package;
      };
      settings = mkOption {
        description = "Kitty configuration settings";
        inherit (options.programs.kitty.settings) type;
        default = defaults.settings;
      };
      extraConfig = mkOption {
        description = "Additional Kitty configuration, including generated theme files";
        inherit (options.programs.kitty.extraConfig) type;
        default = defaults.extraConfig;
      };
      home = {
        packages = mkOption {
          description = "Additional packages installed alongside Kitty";
          inherit (options.home.packages) type;
          default = defaults.home.packages;
        };
        sessionVariables = mkOption {
          description = "Session variables provided by Kitty";
          inherit (options.home.sessionVariables) type;
          default = defaults.home.sessionVariables;
        };
        shellAliases = mkOption {
          description = "Shell aliases provided by Kitty";
          inherit (options.home.shellAliases) type;
          default = defaults.home.shellAliases;
        };
      };
    };
    resolutions = mkMerge [
      (mkLayer 1000 {
        inherit (resolved) enable package;
        settings = defaults.settings // {background_opacity = style.opacity.terminal.dark;};
        home = {
          packages = filter (package: package != resolved.package) (resolved.home.packages or []);
          sessionVariables = resolved.home.sessionVariables or {};
          shellAliases = resolved.home.shellAliases or {};
        };
      })
      (import ./themes.nix {inherit context lix;})
    ];
    outputs = {
      programs.kitty = {inherit (cfg) enable package settings extraConfig;};
      inherit (cfg) home;
    };
  }
