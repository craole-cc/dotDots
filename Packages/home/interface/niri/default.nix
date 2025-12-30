{
  user,
  lix,
  lib,
  config,
  src,
  ...
}: let
  app = "niri";
  inherit (lib.modules) mkIf;
  inherit (lix.attrsets.predicates) waylandEnabled;

  isAllowed =
    waylandEnabled {
      inherit config;
      interface = user.interface or {};
    }
    && (user.interface.windowManager or null) == app;
in {
  config = mkIf isAllowed {
    xdg.configFile."niri/config.kdl" = mkIf (src != null) {
      source = src + "/Configuration/niri/default.kdl";
    };

    programs = {
      # ${app} = #TODO: Niri flake is outdated
      #   {enable = true;}
      #   // import ./bindings.nix
      #   // import ./layout.nix
      #   // import ./settings.nix;

      niriswitcher = import ./switcher {inherit user;};
    };
  };
}
