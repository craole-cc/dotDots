{
  host,
  pkgs,
  mkIf,
  enable,
  ...
}: {
  config = mkIf enable {
    services = {
      desktopManager.gnome = {
        enable = true;
        flashback.customSessions = [
          {
            wmName = "leftwm";
            wmLabel = "LeftWM";
            wmCommand = "${pkgs.leftwm}/bin/leftwm";
            enableGnomePanel = false;
          }
          {
            wmName = "qtile";
            wmLabel = "Qtile";
            wmCommand = "${pkgs.python3Packages.qtile}/bin/qtile";
            enableGnomePanel = false;
          }
          {
            wmName = "xmonad";
            wmLabel = "XMonad";
            wmCommand = "${pkgs.haskellPackages.xmonad}/bin/xmonad";
            enableGnomePanel = false;
          }
          {
            wmName = "dwm";
            wmLabel = "dwm";
            wmCommand = "${pkgs.dwm}/bin/dwm";
            enableGnomePanel = false;
          }
        ];
      };

      displayManager = {
        gdm = {
          enable = true;
          wayland = host.interface.displayProtocol == "wayland";
        };
      };

      gnome = {
        # core-developer-tools.enable = false; # TODO This should be enabled based on policy
      };

      #{ Xterm is unnecessary since console is enabled automatically
      xserver.excludePackages = [pkgs.xterm];
    };

    systemd.services = {
      "getty@tty1".enable = false;
      "autovt@tty1".enable = false;
    };
  };
}
