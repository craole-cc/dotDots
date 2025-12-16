{
  config,
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  app = "foot";
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) elem;
  inherit (lib.modules) mkIf;
  inherit (lix.attrsets.predicates) isWaylandEnabled;
  inherit (user.applications) allowed terminal;

  isPrimary = app == terminal.primary or null;
  isSecondary = app == terminal.secondary or null;
  isAllowed =
    isWaylandEnabled {
      inherit config;
      inherit (user) interface;
    }
    && (
      (elem app allowed)
      || isPrimary
      || isSecondary
    );
in {
  config = mkIf isAllowed {
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
