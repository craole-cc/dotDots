{user, ...}: let
  app = "niri";
  isAllowed = (user.interface.windowManager or null) == app;
in {
  programs.${app} =
    {enable = true;}
    // import ./settings.nix;
}
