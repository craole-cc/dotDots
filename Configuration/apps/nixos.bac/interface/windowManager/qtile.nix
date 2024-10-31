{ ... }:

{
  imports = [ ../windowProtocol/X11.nix ];
  services.xserver = {
    desktopManager = {
      xfce = {
        enable = true;
        enableXfwm = false;
        noDesktop = true;
      };
      wallpaper.mode = "fill";
    };
    displayManager = {
      defaultSession = "none+qtile";
    };
    windowManager.qtile.enable = true;

  };
}
