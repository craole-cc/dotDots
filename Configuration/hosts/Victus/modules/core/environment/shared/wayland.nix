{
  lib,
  lix,
  host,
  ...
}: let
  #~@ Inherit CPU and GPU specs from host specs
  inherit (host.specs) cpu gpu;

  #~@ Utility functions from internal/external libraries
  inherit (lib.lists) any;
  inherit (lib.modules) mkIf;
  inherit (lix.trivial) boolToOneZero;

  #~@ Detect Nvidia GPU from host specs
  isNvidia = any (b: b == "nvidia") (
    with gpu; [primary.brand secondary.brand]
  );

  #~@ Determine if CPU brand is a virtual machine
  isVM = cpu.brand == "vm";

  #~@ Enable Wayland support if Nvidia GPU or VM CPU
  wlr = rec {
    enable = isNvidia || isVM;
    bool = boolToOneZero enable;
  };

  #~@ Enable this entire configuration module based on external 'enabled' utility
  enable = host.interface.displayProtocol == "wayland";
in {
  config = mkIf enable {
    xdg.portal = {
      inherit enable;
      wlr = {inherit (wlr) enable;};
    };

    environment.sessionVariables = {
      #? For Clutter/GTK apps
      CLUTTER_BACKEND = "wayland";

      #? For GTK apps
      GDK_BACKEND = "wayland";

      #? Required for Java UI apps on Wayland
      _JAVA_AWT_WM_NONREPARENTING = "1";

      #? Enable Firefox native Wayland backend
      MOZ_ENABLE_WAYLAND = "1";

      #? Force Chromium/Electron apps to use Wayland
      NIXOS_OZONE_WL = "1";

      #? Qt apps use Wayland
      QT_QPA_PLATFORM = "wayland";

      #? Disable client-side decorations for Qt apps
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

      #? Auto scale for HiDPI displays
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";

      #? SDL2 apps Wayland backend
      SDL_VIDEODRIVER = "wayland";

      #? Allow software rendering fallback on Nvidia/VM
      WLR_RENDERER_ALLOW_SOFTWARE = wlr.bool;

      #? Disable hardware cursors on Nvidia/VM
      WLR_NO_HARDWARE_CURSORS = wlr.bool;

      #? Indicate Wayland session to apps
      XDG_SESSION_TYPE = "wayland";
    };
  };
}
