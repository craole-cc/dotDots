{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.dots.env.gnome;
in {
  config = mkIf cfg.enable {
    #@ Enable GNOME desktop environment
    services.xserver.desktopManager.gnome.enable = true;

    #@ Enable GDM (GNOME Display Manager)
    services.xserver.displayManager.gdm.enable = true;

    #@ Workaround for GNOME autologin
    systemd.services = {
      "getty@tty1".enable = false;
      "autovt@tty1".enable = false;
    };
  };
}
