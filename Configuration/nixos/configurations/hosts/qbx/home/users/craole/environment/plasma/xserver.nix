{ config, lib, ... }:
let
  inherit (lib.modules) mkIf;
  cfg = config.dots.env.gnome;
in
{
  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      videoDrivers = if config.hardware.nvidia.modesetting.enable then [ "nvidia" ] else [ ];
      # libinput.enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };
}
