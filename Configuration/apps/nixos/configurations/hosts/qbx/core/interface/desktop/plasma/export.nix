{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.dots.interface.desktopEnvironment.plasma;
in
{
  config = mkIf cfg.enable {
    services = {
      #@ Enable Plasma 6 desktop environment
      desktopManager.plasma6.enable = true;

      #@ Enable SDDM (Simple Desktop Display Manager)
      displayManager.sddm.enable = true;
    };

    environment = {
      #@ Include packages
      systemPackages = with pkgs; [ yakuake ];
      #@ Exclude packages
      plasma6.excludePackages = with pkgs; [ kate ];
    };
  };
}
