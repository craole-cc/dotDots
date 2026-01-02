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

  app = userApplication {
    inherit user pkgs config;
    name = "foot";
    kind = "terminal";
    customCommand = "feet";
    resolutionHints = ["foot" "feet"];
    requiresWayland = true;
    # debug = true;
  };

  # bin = rec {
  #   foot = getExe' app.package "foot";
  #   footclient = getExe' app.package "footclient";
  #   feet = pkgs.writeShellScriptBin app.command ''
  #     if ${footclient} --no-wait 2>/dev/null; then exit 0 ; else
  #       ${foot} --server &
  #       sleep 0.1
  #       exec ${footclient}
  #     fi
  #   '';
  # };

  foot = getExe' app.package "foot";
  footclient = getExe' app.package "footclient";
  feet = {
    #> Create the feet wrapper that auto-starts server if needed
    command = pkgs.writeShellScriptBin "feet" ''
      # Check if server is already running
      if ! ${footclient} --version &>/dev/null || ! pgrep -x "foot" &>/dev/null; then
        # Start server in background (no window)
        ${foot} --server >/dev/null 2>&1 &
        # Wait for server to be ready
        for i in {1..10}; do
          if ${footclient} --version &>/dev/null; then
            break
          fi
          sleep 0.1
        done
      fi
      # Connect to server
      exec ${footclient} "$@"
    '';

    #> Create desktop entry for feet
    wrapper = pkgs.makeDesktopItem {
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

  cfg = userApplicationConfig {
    inherit app user pkgs config;
    extraPackages = with feet; [command wrapper];
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
  };
}
