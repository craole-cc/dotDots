#TODO: The modules need to be options, not hardcoded
{
  config,
  lib,
  lix,
  user,
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

  context = mkContext {
    inherit config;
    dom = "terminal";
    sub = "core";
    mod = "foot";
  };
  inherit (context) cfg;

  dmsEnabled = config.programs.dank-material-shell.enable or false;
  dmsColorsPath = "~/.config/foot/dotdots-dms-colors.ini";

  themeSync = pkgs.writeShellApplication {
    name = "feet-theme-sync";
    runtimeInputs = with pkgs; [
      coreutils
      dms-shell
      jq
      procps
      systemd
    ];
    text = builtins.readFile ./theme-sync.sh;
  };

  wrappers = mkScriptWrappers {
    inherit pkgs;
    scripts = let
      script = ./wrapper.sh;
    in {
      feet = script;
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
      ++ (if dmsEnabled then [themeSync] else [])
      ++ cfg.extraPackages;
    extraProgramConfig = {
      server.enable = true;
      settings = mkMerge [
        (import ./settings.nix {inherit lix;})
        (import ./input.nix)
        (import ./themes.nix {
          inherit dmsEnabled dmsColorsPath;
        })
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
    outputs = mkMerge [
      {inherit (resolved) programs home;}
      (
        if dmsEnabled
        then {
          # DMS owns palette values at runtime. Keep a dual dark/light Foot
          # palette materialized before the Home Manager Foot server starts,
          # then follow DMS mode changes without requiring per-terminal F12.
          systemd.user.services.foot.Service.ExecStartPre =
            "${themeSync}/bin/feet-theme-sync prepare";

          systemd.user.services.feet-theme-sync = {
            Unit = {
              Description = "Synchronize Foot with Dank Material Shell";
              PartOf = ["graphical-session.target"];
              After = ["graphical-session.target"];
            };
            Service = {
              ExecStart = "${themeSync}/bin/feet-theme-sync monitor";
              Restart = "on-failure";
              RestartSec = "2s";
            };
            Install.WantedBy = ["graphical-session.target"];
          };

          # Activation may run before DMS has generated its color state. The
          # helper seeds a safe fallback in that case; the monitor replaces it
          # as soon as DMS's dual-scheme state becomes available.
          home.activation.prepareFootDmsTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
            ${themeSync}/bin/feet-theme-sync prepare
          '';
        }
        else {}
      )
    ];
  }
