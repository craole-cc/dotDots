{ config, lib, ... }:
let
  inherit (lib.modules) mkIf;
  cfg = config.dots.services.gnome.wayland;
in
{
  config = mkIf cfg.enable {
    services.xserver.displayManager.gdm.wayland = true;

    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      # MOZ_DBUS_REMOTE = 1;
      # MOZ_USE_XINPUT2 = 1;
      # QT_AUTO_SCREEN_SCALE_FACTOR = 1;
      # _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dsun.java2d.xrender=true";
    };
  };
}
