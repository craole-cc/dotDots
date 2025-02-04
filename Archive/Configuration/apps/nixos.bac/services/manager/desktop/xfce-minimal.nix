{ ... }:
{
  imports = [
    ./wallpaper.nix
    ../../server/x
  ];
  services.xserver.desktopManager = {
    xfce = {
      enable = true;
      enableXfwm = false;
      noDesktop = true;
      enableScreensaver = false;
    };
    xterm.enable = false;
  };
}
