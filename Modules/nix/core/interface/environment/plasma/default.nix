{
  config,
  lib,
  pkgs,
  top,
  lix,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.inputs.interface;
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
  inherit (lix.modules.core._) mkStaged;
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = (cfg.desktopEnvironment == "plasma");
  });
}
