{
  config,
  lib,
  lix,
  user,
  pkgs,
  src,
  ...
}: let
  inherit (lib.modules) mkIf;
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

  #~@ External Script Path
  #? Reference the script from your dotfiles structure

  #~@ Feet Wrapper - Simple passthrough to external script
  feet = let
    script = src + "/Bin/shellscript/packages/wrappers/feet.sh";

    #> Main launcher (calls external script)
    command = pkgs.writeShellScriptBin "feet" ''
      exec ${script} "$@"
    '';

    #> Quake mode launcher
    quake = pkgs.writeShellScriptBin "feet-quake" ''
      exec ${script} --quake "$@"
    '';

    #> Desktop entries
    desktop = makeDesktopItem {
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
      noDisplay = true;
    };
  in {inherit script command desktop quake quakeDesktop;};

  #~@ Final Configuration Assembly
  cfg = userApplicationConfig {
    inherit app user pkgs config;
    extraPackages = with feet; [command quake desktop quakeDesktop];
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
    systemd.user.services.foot-theme-monitor = {
      Unit = {
        Description = "Foot terminal theme monitor";
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${feet.script} --monitor";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
