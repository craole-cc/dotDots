{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.inputs.interface;
in {
  config = mkIf (cfg.windowManager == "hyprland") {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
  };
}
