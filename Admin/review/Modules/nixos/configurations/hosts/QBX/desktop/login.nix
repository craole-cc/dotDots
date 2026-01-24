{
  config,
  lib,
  ...
}: let
  dom = "dots";
  mod = "desktop";
  cfg = config.${dom}.${mod};

  inherit (lib.modules) mkIf;
  inherit (lib.lists) elem;
  inherit (cfg.enums) users;

  # Count enabled display managers
  enabledDMs = with config.services; [
    (displayManager.sddm.enable)
    (xserver.displayManager.gdm.enable)
    (xserver.displayManager.lightdm.enable)
  ];
  activeCount = lib.count (x: x) enabledDMs;
in {
  config = {
    assertions = [
      {
        assertion = activeCount == 1;
        message = "Exactly one display manager must be enabled, found ${toString activeCount} enabled";
      }
      {
        assertion = cfg.login.user == null || elem cfg.login.user users;
        message = ''
          Invalid login user: "${toString cfg.login.user}"
          Available users:
          ${lib.concatMapStrings (u: " - ${u}\n") users}
          To resolve this, either:
          1. Choose an enabled user from the list above:
              dots.desktop.login.user = "craole";  # or another valid user
          2. Enable the user in your configuration:
              dots.users.${toString cfg.login.user}.enable = true;
          3. Or disable automatic login:
              dots.desktop.login.automatically = false;
        '';
      }
    ];

    services = {
      displayManager = {
        autoLogin = {
          enable = cfg.login.automatically;
          user = cfg.login.user;
        };
        sddm = {
          enable = cfg.login.manager == "sddm";
          wayland.enable = cfg.login.protocol == "wayland";
        };
      };
      xserver.displayManager = {
        gdm = {
          enable = cfg.login.manager != "gdm";
          wayland.enable = cfg.login.protocol == "wayland";
        };
        lightdm = {
          enable = cfg.login.manager == "lightdm";
        };
      };
    };

    #{ Workaround for GNOME autologin
    systemd.services = mkIf (cfg.environment == "gnome") {
      "getty@tty1".enable = false;
      "autovt@tty1".enable = false;
    };

    #{ Automatically enable the autologin user's profile
    dots.users.${cfg.login.user}.enable = true;
  };
}
