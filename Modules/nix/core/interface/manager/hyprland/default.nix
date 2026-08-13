{
  config,
  lib,
  top,
  lix,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.resolved.interface;
  payload = {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
  };
  inherit (lix.modules.core.staging) mkStaged;
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = (cfg.windowManager == "hyprland");
  });
}
