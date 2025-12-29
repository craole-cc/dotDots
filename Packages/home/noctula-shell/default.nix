{
  lib,
  user,
  inputs,
  ...
}: let
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkForce mkIf;
  inherit (lib.strings) hasInfix;
  barConfig = user.interface.bar or null;
  isAllowed = barConfig != null && hasInfix "noctalia" barConfig;
in {
  programs = mkIf isAllowed {
    noctalia-shell =
      {enable = true;}
      // import ./settings.nix;

    waybar.enable = mkForce false;
  };
}
