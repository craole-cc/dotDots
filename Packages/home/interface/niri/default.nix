{
  user,
  lix,
  lib,
  config,
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
