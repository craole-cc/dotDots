{
  config,
  lib,
  pkgs,
  top,
  lix,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.resolved.interface;
  payload = {
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
  inherit (lix.modules.core.staging) mkStaged;
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = (cfg.desktopEnvironment == "plasma");
  });
}
