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
  isWayland = with config.wayland.windowManager;
    (interface.displayProtocol == "wayland")
    || sway.enable
    || hyprland.enable;
  isAllowed =
    isWayland
    && (elem app enable || isPrimary || isSecondary);

  footWrapper = pkgs.writeShellScriptBin "feet" ''
    if ${pkgs.foot}/bin/footclient --no-wait 2>/dev/null; then
      exit 0
    else
      ${pkgs.foot}/bin/foot --server &
      sleep 0.1
      exec ${pkgs.foot}/bin/footclient
    fi
  '';
in {
  config = mkIf isAllowed {
    programs.${app} =
      {
        enable = true;
        server.enable = true;
      }
      // import ./input.nix
      // import ./themes.nix
      // import ./settings.nix;

    home.packages = [footWrapper];

    home.sessionVariables =
      {}
      // optionalAttrs isPrimary {TERMINAL = "feet";}
      // optionalAttrs isSecondary {TERMINAL_ALT = "feet";};
  };
}
