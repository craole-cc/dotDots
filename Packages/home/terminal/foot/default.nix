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
  inherit (builtins) readFile replaceStrings;

  #~@ Application Configuration
  #? Base foot terminal application with custom command wrapper
  app = userApplication {
    inherit user pkgs config;
    name = "foot";
    kind = "terminal";
    customCommand = "feet";
    resolutionHints = ["foot" "feet"];
    requiresWayland = true;
  };

  #~@ Executable Paths
  #? Extract binary paths from the foot package
  foot = getExe' app.package "foot";
  footclient = getExe' app.package "footclient";

  #~@ Theme Detection Script
  #? POSIX-compliant shell script to detect system theme
  detectTheme =
    pkgs.writeShellScriptBin "foot-detect-theme"
    (readFile ./detect-theme.sh);

  #~@ Feet Wrapper Components
  feet = {
    #> Smart wrapper with theme detection
    #? POSIX-compliant wrapper that manages foot server
    command = pkgs.writeShellScriptBin "feet" (
      replaceStrings
      ["@detectTheme@" "@foot@" "@footclient@"]
      ["${detectTheme}/bin/foot-detect-theme" foot footclient]
      (readFile ./feet.sh)
    );

    #> Desktop entry for application launcher
    #? Creates clickable "Feet Terminal" icon in application menus
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
  };

  #~@ Final Configuration Assembly
  #? Combines application metadata, packages, and program-specific settings
  cfg = userApplicationConfig {
    inherit app user pkgs config;
    extraPackages = with feet; [command wrapper detectTheme];
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
  #~@ Module Output
  #? Only apply configuration if application is allowed/enabled
  config = mkIf cfg.enable {
    inherit (cfg) programs home;
  };
}
