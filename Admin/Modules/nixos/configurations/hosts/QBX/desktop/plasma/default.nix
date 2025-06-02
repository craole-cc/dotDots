{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.dots.interface.desktop.environment.plasma;
in
{
  config = mkIf cfg.enable {
    #~@ Enable Plasma 6 desktop environment
    services.desktopManager.plasma6.enable = true;

    environment = {
      #~@ Include packages
      systemPackages = with pkgs; [ yakuake ];

      #~@ Exclude packages
      plasma6.excludePackages = with pkgs; [ kate ];
    };
  };
}
