{
  lib,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) oneOf nullOr;

  base = "interface";
in {
  options.DOTS.${base} = {
    manager = mkOption {
      description = "Desktop/Window Manager";
      default = "hyprland";
      type = nullOr (oneOf [
        "hyprland"
        "sway"
        "river"
        "xfce"
        "gnome"
        "plasma"
        "none"
      ]);
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
