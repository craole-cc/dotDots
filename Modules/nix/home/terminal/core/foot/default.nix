#TODO: The modules need to be options, not hardcoded
{
  config,
  lix,
  user,
  paths,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig mkMerge;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.applications.construction) mkScriptWrappers;
  inherit (lix.types.combinators) listOf nullOr;
  inherit (lix.types.primitives) bool package str;
  inherit (pkgs) makeDesktopItem;
  # sh = paths.repo.lib.sh.store;
  inherit (paths.store.lib) sh;

  context = mkContext {
    inherit config;
    dom = "terminal";
    sub = "core";
    mod = "foot";
  };
  inherit (context) cfg;

  wrappers = mkScriptWrappers {
    inherit pkgs;
    scripts = let
      colorscheme = sh + "/interface/theme/colorscheme";
      verbosity = sh + "/output/verbosity";
      feet = sh + "/packages/wrappers/foot.sh";
      /**
      Q: Should colorscheme keep its own -q/--quiet and -d/--verbose flags as shortcuts (mapping to verbosity levels), or drop them in favor of verbosity's own flag syntax?
      A: No — replace -q/-d entirely with verbosity's own flags (--level, +1, etc.)

      Q: Should colorscheme resolve the verbosity tool the same three-tier way (env var, relative to script, PATH) that we just built for foot.sh?
      A: Yes, use the same resolve_tool/run_tool pattern from foot.sh
      */
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
    categories = [
      "System"
      "TerminalEmulator"
    ];
  };

  quake = makeDesktopItem {
    name = "feet-quake";
    desktopName = "Feet Quake";
    comment = "Dropdown terminal (quake-style)";
    exec = "feet-quake";
    icon = "foot";
    terminal = false;
    type = "Application";
    categories = [
      "System"
      "TerminalEmulator"
    ];
    noDisplay = true;
  };

  resolved = userApplicationConfig {
    inherit context user pkgs;
    inherit (cfg) customCommand resolutionHints requiresWayland;
    extraPackages =
      wrappers
      ++ [
        desktop
        quake
      ]
      ++ cfg.extraPackages;
    extraProgramConfig = {
      server.enable = true;
      settings = mkMerge [
        (import ./settings.nix {inherit lix;})
        (import ./input.nix)
        (import ./themes.nix)
      ];
    };
    inherit (cfg) debug;
  };
in
  mkConfig {
    inherit context;
    options = {
      customCommand = mkOption {
        description = "Command name to run, overriding the resolved package binary.";
        default = "feet";
        type = str;
      };
      resolutionHints = mkOption {
        description = "Candidate package names to try when resolving the `foot` package.";
        default = [
          "foot"
          "feet"
        ];
        type = listOf str;
      };
      requiresWayland = mkOption {
        description = "Whether this application requires Wayland to be enabled.";
        default = true;
        type = bool;
      };
      extraPackages = mkOption {
        description = "Additional packages to install alongside the resolved application.";
        default = [];
        type = listOf package;
      };
      debug = mkOption {
        description = "Trace the application resolution process during evaluation.";
        default = false;
        type = bool;
      };

      enable = mkEnable {
        inherit context;
        condition = resolved.enable;
      };
      isPrimary = mkOption {
        description = "Whether `foot` is the user's primary terminal choice.";
        default = resolved.isPrimary;
        type = bool;
        readOnly = true;
      };
      isPlatformCompatible = mkOption {
        description = "Whether platform requirements (Wayland) are satisfied.";
        default = resolved.isPlatformCompatible;
        type = bool;
        readOnly = true;
      };
      package = mkOption {
        description = "The resolved `foot` package derivation.";
        default = resolved.package;
        type = nullOr package;
        readOnly = true;
      };
    };
    outputs = {inherit (resolved) programs home;};
  }
