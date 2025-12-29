{
  user,
  lib,
  ...
}: let
  app = "niri";
  isAllowed = (user.interface.windowManager or null) == app;
  inherit (lib.modules) mkIf;
in {
  programs = mkIf isAllowed {
    # ${app} = #TODO: Niri flake is outdated
    #   {enable = true;}
    #   // import ./bindings.nix
    #   // import ./layout.nix
    #   // import ./settings.nix;

    niriswitcher =
      {enable = true;}
      // import ./switcher/bindings.nix {inherit user;}
      // import ./switcher/settings.nix
      // import ./switcher/style.nix;
  };
}
