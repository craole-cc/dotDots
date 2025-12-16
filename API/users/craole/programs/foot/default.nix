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
  isAllowed =
    (
      (interface.displayProtocol == "wayland")
      || config.windowManager.wayland.enable
    )
    && (
      (elem app enable)
      || (isPrimary || isSecondary)
    );

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
    programs.${app} = {
      enable = true;
      server.enable = true;
    };

    home.packages = [footWrapper];

    imports = [
      ./settings.nix
      ./themes.nix
    ];

    home.sessionVariables =
      {}
      // optionalAttrs isPrimary {TERMINAL = "feet";}
      // optionalAttrs isSecondary {TERMINAL_ALT = "feet";};
  };
}
