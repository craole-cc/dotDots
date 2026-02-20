{
  config,
  lib,
  lix,
  user,
  pkgs,
  paths,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (pkgs) makeDesktopItem writeShellScriptBin;

  #~@ Script Wrappers
  script = paths.local.libs.shellscript + "/packages/wrappers/feet.sh";

  #> Main launcher (calls external script)
  command = writeShellScriptBin "feet" ''
    exec ${script} "$@"
  '';

  #> Quake mode launcher
  quake = writeShellScriptBin "feet-quake" ''
    exec ${script} --quake "$@"
  '';

  #> Monitor mode launcher
  monitor = writeShellScriptBin "feet-monitor" ''
    exec ${script} --monitor
  '';

  #~@ Desktop entries
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

  quakeDesktop = makeDesktopItem {
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

  #~@ Final Configuration Assembly
  cfg = userApplicationConfig {
    inherit user pkgs config;
    name = "foot";
    kind = "terminal";
    customCommand = "feet";
    resolutionHints = ["foot" "feet"];
    requiresWayland = true;
    extraPackages = [command quake monitor desktop quakeDesktop];
    extraProgramConfig = {
      server.enable = true;
      settings = mkMerge [
        (import ./settings.nix)
        (import ./input.nix)
        (import ./themes.nix)
      ];
    };
    debug = false;
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs home;

    #~@ Systemd User Service for Theme Monitoring
    # systemd.user.services.foot-theme-monitor = {
    #   Unit = {
    #     Description = "Foot terminal theme monitor";
    #     After = ["graphical-session.target"];
    #   };
    #   Service = {
    #     ExecStart = monitor;
    #     Restart = "on-failure";
    #     RestartSec = 5;
    #   };
    #   Install.WantedBy = ["graphical-session.target"];
    # };
  };
}
