# options.nix
{lib, ...}: let
  inherit (lib.options) mkEnableOption;
in {
  options.dots.services.dunst = {
    enable = mkEnableOption "Dunst, a lightweight notification daemon.";
  };
}
