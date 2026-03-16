{
  config,
  lib,
  lix,
  user,
  pkgs,
  tree,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;
  inherit (lix.applications.utilities) mkScriptWrappers;
  inherit (pkgs) makeDesktopItem;

  #~@ Script Wrappers
  wrappers = mkScriptWrappers {
    inherit pkgs;
    scripts = let
      script = tree.store.lib.sh + "/packages/wrappers/feet.sh";
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

  #~@ Final Configuration Assembly
  cfg = userApplicationConfig {
    inherit user pkgs config;
    name = "foot";
    kind = "terminal";
    customCommand = "feet";
    resolutionHints = ["foot" "feet"];
    requiresWayland = true;
    extraPackages = wrappers ++ [desktop quake];
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
  };
}
