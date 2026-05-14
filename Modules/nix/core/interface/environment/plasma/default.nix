{
  config,
  lib,
  pkgs,
  top,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.interface;
in
{
  config = mkIf (cfg.desktopEnvironment == "plasma") {
    services.desktopManager.plasma6 = {
      enable = true;
      # enableQt5Integration = false;
    };
    environment.systemPackages = with pkgs.kdePackages; [
      plasma-browser-integration
      kde-gtk-config
      kdialog
    ];
  };
}
