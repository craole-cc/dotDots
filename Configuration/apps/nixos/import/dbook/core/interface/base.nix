{ lib, config, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) oneOf nullOr;
  inherit (lib.lists) elem;

  base = "interface";
  cfg = config.DOTS.${base};
in
{
  options.DOTS.${base} = {
    manager = mkOption {
      description = "Desktop/Window Manager";
      default = "hyprland";
      type = nullOr oneOf [
        "hyprland"
        "sway"
        "river"
        "xfce"
        "gnome"
        "plasma"
        "none"
      ];
    };
    isMinimal = mkEnableOption "no desktop";
    # isMinimal = mkEnableOption "no desktop" // {
    # default = elem cfg.manager [
    #   "none"
    #   null
    # ];
    # };
  };
}
