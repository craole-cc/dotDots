{
  config,
  options,
  lix,
  user,
  paths,
  pkgs,
  style,
  ...
}: let
  inherit (lix.attrsets.aggregation) mergeSafe;
  inherit (lix.modules.construction) mkContext mkConfig mkLayer mkForce;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.applications.construction) mkScriptWrappers;
  inherit (lix.types.combinators) attrsOf either listOf nullOr oneOf;
  inherit (lix.types.primitives) bool float int package path str;
  inherit (lix.lists.transformation) filter;
  inherit (lix.toolkit) packages;

  settingValue = nullOr (oneOf [bool float int path str]);
  inherit (pkgs) makeDesktopItem;
  inherit (paths.store.lib) sh;

  context = mkContext {
    inherit config;
    dom = "terminal";
    sub = "emulators";
    mod = "foot";
    kind = "terminal";
  };
  inherit (context) cfg;

  wrappers = mkScriptWrappers {
    inherit pkgs;
    scripts = let
      # colorscheme = sh + "/interface/theme/colorscheme";
      # verbosity = sh + "/output/verbosity";
      feet = sh + "/packages/wrappers/foot.sh";
      script = feet;
    in {
      inherit feet;
      feet-quake = {
        inherit script;
        extraArgs = ["--quake"];
      };
      feet-monitor = {
        inherit script;
        extraArgs = ["--monitor"];
      };
    };
  };

  desktop = makeDesktopItem {
    name = "feet";
    desktopName = "Feet";
    comment = "Fast, lightweight terminal emulator (server mode)";
    exec = "feet";
    icon = "foot";
    terminal = false;
    type = "Application";
    categories = ["System" "TerminalEmulator"];
  };

  quake = makeDesktopItem {
    name = "feet-quake";
    desktopName = "Feet Quake";
    comment = "Dropdown terminal (quake-style)";
    exec = "feet-quake";
    icon = "foot";
    terminal = false;
    type = "Application";
    categories = ["System" "TerminalEmulator"];
    noDisplay = true;
  };

  resolved = userApplicationConfig {
    inherit context user pkgs;
    inherit (cfg) customCommand resolutionHints requiresWayland;
    extraPackages =
      wrappers
      ++ [desktop quake]
      ++ cfg.extraPackages;
    inherit (cfg) debug;
  };

  defaults = {
    enable = false;
    package = packages.foot;
    settings = mergeSafe [
      (import ./settings.nix {})
      (import ./input.nix {})
      (import ./themes.nix {})
    ];
    server.enable = true;
    customCommand = "feet";
    resolutionHints = ["foot" "feet"];
    requiresWayland = true;
    extraPackages = [];
    debug = false;
    isPrimary = false;
    isPlatformCompatible = false;
    home = {
      packages = wrappers ++ [desktop quake];
      sessionVariables = {};
      shellAliases = {};
    };
  };
in
  mkConfig {
    inherit context defaults;
    options = {
      enable = mkEnable {
        inherit context;
        default = defaults.enable;
      };
      customCommand = mkOption {
        description = "Command name to run, overriding the resolved package binary.";
        default = defaults.customCommand;
        type = str;
      };
      resolutionHints = mkOption {
        description = "Candidate package names to try when resolving the `foot` package.";
        default = defaults.resolutionHints;
        type = listOf str;
      };
      requiresWayland = mkEnable {
        description = "Whether this application requires Wayland to be enabled.";
        default = defaults.requiresWayland;
      };
      extraPackages = mkOption {
        description = "Additional packages to install alongside the resolved application.";
        default = defaults.extraPackages;
        type = listOf package;
      };
      debug = mkEnable {
        description = "Trace the application resolution process during evaluation.";
        default = defaults.debug;
      };
      isPrimary = mkEnable {
        description = "Whether `foot` is the user's primary terminal choice.";
        default = resolved.isPrimary;
        readOnly = true;
      };
      isPlatformCompatible = mkEnable {
        description = "Whether platform requirements (Wayland) are satisfied.";
        default = resolved.isPlatformCompatible;
        readOnly = true;
      };
      package = mkOption {
        description = "The resolved `foot` package derivation.";
        default = defaults.package;
        type = nullOr package;
      };
      settings = mkOption {
        description = "Foot INI configuration settings";
        default = defaults.settings;
        type = attrsOf (attrsOf (either settingValue (listOf settingValue)));
      };
      server.enable = mkEnable {
        description = "Foot terminal server";
        default = defaults.server.enable;
      };
      home = {
        packages = mkOption {
          description = "Additional packages installed alongside Foot, including wrappers and launchers";
          inherit (options.home.packages) type;
          default = defaults.home.packages or {};
        };
        sessionVariables = mkOption {
          description = "Session variables provided by Foot";
          inherit (options.home.sessionVariables) type;
          default = defaults.home.sessionVariables or {};
        };
        shellAliases = mkOption {
          description = "Shell aliases provided by Foot";
          inherit (options.home.shellAliases) type;
          default = defaults.home.shellAliases or {};
        };
      };
    };

    resolutions = mkLayer 1000 {
      inherit (resolved) enable package;
      settings = mergeSafe [
        defaults.settings
        {key-bindings.color-theme-toggle = "Control+Alt+0";}
        (import ./themes.nix {opacity = style.opacity.terminal;})
      ];
      home = {
        packages =
          filter (package: package != resolved.package)
          (resolved.home.packages or []);
        inherit (resolved.home) sessionVariables shellAliases;
      };
    };

    outputs = {
      programs.foot = {
        inherit (cfg) enable package server;
        settings = mergeSafe [
          cfg.settings
          {
            main = with cfg.settings.main; {
              include = mkForce include;
              dpi-aware = mkForce dpi-aware;
            };
          }
        ];
      };
      inherit (cfg) home;
    };
  }
