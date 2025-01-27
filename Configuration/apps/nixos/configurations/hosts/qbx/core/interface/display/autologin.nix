{ config, lib, ... }:
let
  cfg = config.dots.interface.autologin;
  gnomeEnabled = config.dots.interface.desktopEnvironment == "gnome";

  inherit (lib.modules) mkIf;
in
{
  config = mkIf cfg.enable {
    #@ Automatically enable the autologin user's profile
    dots.users.${cfg.user}.enable = true;

    #@ Enable autologin
    services.displayManager.autoLogin = {
      enable = true;
      user = cfg.user;
    };

    #@ Workaround for GNOME autologin
    systemd.services = mkIf gnomeEnabled {
      "getty@tty1".enable = false;
      "autovt@tty1".enable = false;
    };
  };
}
