{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe';
  inherit (lix.applications.generators) userApplicationConfig userApplication;
  inherit (pkgs) makeDesktopItem;

  #~@ Application Configuration
  app = userApplication {
    inherit user pkgs config;
    name = "foot";
    kind = "terminal";
    customCommand = "feet";
    resolutionHints = ["foot" "feet"];
    requiresWayland = true;
  };

  #~@ Executable Paths
  foot = getExe' app.package "foot";
  footclient = getExe' app.package "footclient";

  #~@ Theme Detection Script
  detectTheme =
    pkgs.writeShellScriptBin "foot-detect-theme"
    (builtins.readFile ./detect-theme.sh);

  #~@ Theme Monitor Service
  #? Background service that watches for theme changes
  themeMonitor = pkgs.writeShellScriptBin "foot-theme-monitor" (
    builtins.replaceStrings
    ["@detectTheme@" "@foot@"]
    ["${detectTheme}/bin/foot-detect-theme" foot]
    (builtins.readFile ./foot-theme-monitor.sh)
  );

  #~@ Feet Wrapper Components
  feet = {
    #> Smart wrapper with theme detection
    command = pkgs.writeShellScriptBin "feet" (
      builtins.replaceStrings
      ["@detectTheme@" "@foot@" "@footclient@"]
      ["${detectTheme}/bin/foot-detect-theme" foot footclient]
      (builtins.readFile ./feet-wrapper.sh)
    );

    #> Quake mode toggle
    quake = pkgs.writeShellScriptBin "feet-quake" (
      builtins.replaceStrings
      ["@footclient@"]
      [footclient]
      (builtins.readFile ./feet-quake.sh)
    );

    #> Desktop entries
    wrapper = makeDesktopItem {
      name = "feet";
      desktopName = "Feet Terminal";
      comment = "Fast, lightweight terminal emulator (server mode)";
      exec = "feet";
      icon = "foot";
      terminal = false;
      type = "Application";
      categories = ["System" "TerminalEmulator"];
    };

    quakeDesktop = makeDesktopItem {
      name = "feet-quake";
      desktopName = "Feet Quake Terminal";
      comment = "Dropdown terminal (quake-style)";
      exec = "feet-quake";
      icon = "foot";
      terminal = false;
      type = "Application";
      categories = ["System" "TerminalEmulator"];
      noDisplay = true; # Don't show in menu, use keybinding instead
    };
  };

  #~@ Final Configuration Assembly
  cfg = userApplicationConfig {
    inherit app user pkgs config;
    extraPackages = with feet; [command quake wrapper quakeDesktop detectTheme themeMonitor];
    extraProgramConfig = {
      server.enable = true;
      settings =
        {}
        // (import ./settings.nix)
        // (import ./input.nix)
        // (import ./themes.nix)
        // {};
    };
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs home;

    #~@ Systemd User Service for Theme Monitoring
    #? Auto-starts on login and monitors theme changes
    systemd.user.services.foot-theme-monitor = {
      Unit = {
        Description = "Foot terminal theme monitor";
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${themeMonitor}/bin/foot-theme-monitor";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
