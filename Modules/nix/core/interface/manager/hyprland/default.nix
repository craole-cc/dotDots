{
  config,
  lib,
  top,
  lix,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.inputs.interface;
  payload = {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
  };
  inherit (lix.modules.core._) mkStaged;
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = (cfg.windowManager == "hyprland");
  });
}
