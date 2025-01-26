# plasma6/common.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.dots.services.plasma;
in
{
  config = mkIf cfg.enable {
    services = {
      #@ Enable Plasma 6 desktop environment
      desktopManager.plasma6.enable = true;

      #@ Enable SDDM (Simple Desktop Display Manager)
      displayManager.sddm.enable = true;
    };

    #@ Exclude packages
    environment.plasma6.excludePackages = with pkgs; [
    ];
  };
}
