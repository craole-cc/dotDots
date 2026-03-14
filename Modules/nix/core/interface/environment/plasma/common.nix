{
  config,
  lib,
  pkgs,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.interface;
in {
  config = mkIf (cfg.de == "plasma") {
    services = {
      desktopManager.plasma6.enable = true;
      #   displayManager.sddm = mkIf (cfg.dm == "sddm") {
      #     enable = true;
      #     wayland.enable = cfg.dp == "wayland";
      #   };
    };

    environment.systemPackages = with pkgs.kdePackages; [
      plasma-browser-integration
      kde-gtk-config
      kdialog
    ];
  };
}
