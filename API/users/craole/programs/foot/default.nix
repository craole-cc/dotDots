{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  app = "foot";
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) elem;
  inherit (lib.modules) mkIf;
  inherit (user) enable interface;
  inherit (user.applications.terminal) primary secondary;
  isPrimary = app == primary;
  isSecondary = app == secondary;

  isWayland =
    (interface.displayProtocol or null == "wayland")
    || (config.wayland.windowManager.sway.enable or false)
    || (config.wayland.windowManager.hyprland.enable or false);

  isAllowed =
    isWayland
    && (elem app enable || isPrimary || isSecondary);
in {
  config = mkIf (elem app enable || isPrimary || isSecondary) {
    programs.${app} = {
      enable = true;
      server.enable = true;
      settings =
        (import ./settings.nix)
        // (import ./input.nix)
        // (import ./themes.nix);
    };

    home = {
      packages = with pkgs; [
        (writeShellScriptBin "feet" ''
          if ${foot}/bin/footclient --no-wait 2>/dev/null; then
            exit 0
          else
            ${foot}/bin/foot --server &
            sleep 0.1
            exec ${foot}/bin/footclient
          fi
        '')
      ];
      sessionVariables =
        optionalAttrs isPrimary {TERMINAL = "feet";}
        // optionalAttrs isSecondary {TERMINAL_ALT = "feet";};
    };
  };
}
