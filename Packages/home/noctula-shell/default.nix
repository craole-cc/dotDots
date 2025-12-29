{
  # config,
  lib,
  user,
  inputs,
  # pkgs,
  # host,
  # system,
  # bar,
  ...
}: let
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkForce mkIf;
  inherit (lib.strings) hasInfix toJSON;
  isAllowed = hasInfix "noctalia" (user.interface.bar or null);
in {
  programs = mkIf isAllowed {
    noctalia-shell.enable = true;
    waybar.enable = mkForce false;
  };
}
