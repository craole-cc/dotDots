#TODO: The modules need to be options, not hardcoded
{
  config,
  lix,
  user,
  paths,
  pkgs,
  style,
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
    sub = "emulators";
    mod = "foot";
    kind = "terminal";
  };
  inherit (context) cfg;

  wrappers = mkScriptWrappers {
    inherit pkgs;
    scripts = let
      colorscheme = sh + "/interface/theme/colorscheme";
      verbosity = sh + "/output/verbosity";
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
        (import ./themes.nix {inherit style lix;})
      ];
    };
    # inherit (cfg) debug;
  };
  # include = let
  #   dirs = {
  #     config = with host.paths; {
  #       local = mkPath local.cfg "foot";
  #       store = mkPath store.cfg "foot";
  #     };
  #     themes = {
  #       pkgs = mkPath pkgs.foot.themes ["share" "foot" "themes"];
  #       dots = mkPath dirs.config.store "themes";
  #     };
  #   };
  #   mkThemePath = {
  #     from ? "pkgs",
  #     name,
  #   }:
  #     mkPath dirs.themes.${from} [name];
  # in [
  #   (mkThemePath {name = "catppuccin-frappe";})
  #   (mkThemePath {name = "catppuccin-latte";})
  #   (mkThemePath {
  #     name = "dark.ini";
  #     from = "dots";
  #   })
  #   (mkThemePath {
  #     name = "light.ini";
  #     from = "dots";
  #   })
  #   (mkPath dirs.config.store "config.ini")
  # ];
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = resolved.enable;
      };
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
