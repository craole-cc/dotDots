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
  inherit (pkgs) writeShellScriptBin makeDesktopItem;

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

  #~@ Feet Wrapper Components
  feet = {
    #> Smart wrapper that auto-starts foot server if needed
    #? Checks for running server, starts one if missing, then connects via footclient
    #? Uses explicit socket path for reliable server/client communication
    command = writeShellScriptBin "feet" ''
      SOCKET="/run/user/$UID/foot-wayland-0.sock"

      # Start server if not running
      if ! pgrep -x "foot" >/dev/null; then
        ${foot} --server >/dev/null 2>&1 &
        # Wait for socket
        while [ ! -S "$SOCKET" ] && sleep 0.1; do :; done
      fi

      # Connect with explicit socket path
      exec ${footclient} --server-socket="$SOCKET" "$@"
    '';

    #> Desktop entry for application launcher
    #? Creates clickable "Feet Terminal" icon in application menus
    #? Inherits foot's icon and metadata
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
  #~@ Module Output
  #? Only apply configuration if application is allowed/enabled
  config = mkIf cfg.enable {
    inherit (cfg) programs home;
  };
}
