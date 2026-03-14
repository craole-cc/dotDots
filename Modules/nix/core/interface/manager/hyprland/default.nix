{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.interface;
in {
  config = mkIf (cfg.wm == "hyprland") {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
  };
}
