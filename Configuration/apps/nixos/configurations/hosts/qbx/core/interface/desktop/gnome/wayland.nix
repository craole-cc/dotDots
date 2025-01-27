{ config, lib, ... }:
let
  inherit (lib.modules) mkIf;
  cfgEnabled =
    config.dots.interface.desktopEnvironment == "gnome"
    && config.dots.interface.display.protocol == "wayland";
in
{
  config = mkIf cfgEnabled {
    services.xserver.displayManager.gdm.wayland = true;

    environment.sessionVariables = {
      #@ Enable Wayland for Firefox
      MOZ_ENABLE_WAYLAND = "1";

      #@ Use Wayland for QT applications
      QT_QPA_PLATFORM = "wayland";

      #@ Use Wayland for SDL applications
      SDL_VIDEODRIVER = "wayland";

      #@ Disable reparenting for Java applications (e.g. Eclipse)
      # This is required for Java applications to work with Wayland
      _JAVA_AWT_WM_NONREPARENTING = "1";

      # TODO: are these necessary?
      # MOZ_DBUS_REMOTE = 1; # for firefox, allows it to communicate with gnome-shell
      # MOZ_USE_XINPUT2 = 1; # for firefox, enables XInput2 extension
      # QT_AUTO_SCREEN_SCALE_FACTOR = 1; # for qt apps, auto detect screen scale factor
      # _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dsun.java2d.xrender=true";
      #   -Dawt.useSystemAAFontSettings=on: enable antialiasing
      #   -Dswing.aatext=true: enable anti-aliased text
      #   -Dsun.java2d.xrender=true: enable XRender extension for Java2D
    };
  };
}
