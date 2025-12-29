{
  lib,
  user,
  inputs,
  ...
}: let
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkForce mkIf;
  inherit (lib.strings) hasInfix;
  isAllowed = hasInfix "noctalia" (user.interface.bar or null);
in {
  programs = mkIf isAllowed {
    noctalia-shell =
      {enable = true;}
      // import ./settings.nix;

    waybar.enable = mkForce false;
  };
}
