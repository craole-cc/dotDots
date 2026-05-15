{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.interface;
in {
  config = mkIf (cfg.windowManager == "hyprland") {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
  };
}
