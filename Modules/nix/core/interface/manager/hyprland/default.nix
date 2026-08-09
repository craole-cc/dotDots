{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.inputs.interface;
in {
  config = lib.mkMerge [
    (mkIf (cfg.windowManager == "hyprland") {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
  })
    {
      ${top}.output = mkIf (cfg.windowManager == "hyprland") {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
  };
    }
  ];
}
