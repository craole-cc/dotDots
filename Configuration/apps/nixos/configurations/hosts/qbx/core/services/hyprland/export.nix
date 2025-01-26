{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config) nixpkgs hardware;
  nvidia = hardware.nvidia.modesetting.enable;
  vm = false; # TODO: how can i tell this system is not a vm?
  cfg = config.dots.services.hyprland;
in
{
  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    environment.sessionVariables = {
      #| Unfree packages
      NIXPKGS_ALLOW_UNFREE = if nixpkgs.config.allowUnfree then "1" else "0";

      #| NVIDIA settings
      WLR_RENDERER_ALLOW_SOFTWARE = if nvidia || vm then "1" else "0";
      WLR_NO_HARDWARE_CURSORS = if nvidia || vm then "1" else "0";
      LIBVA_DRIVER_NAME = if nvidia || vm then "nvidia" else "";
      __GLX_VENDOR_LIBRARY_NAME = if nvidia || vm then "nvidia" else "";
      ELECTRON_OZONE_PLATFORM_HINT = if nvidia || vm then "auto" else "";
      NIXOS_OZONE_WL = if nvidia || vm then "1" else "0";

      #| Desktop environment settings
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";

      #| Graphics and rendering settings
      SDL_VIDEODRIVER = "wayland"; # Disable if issues
      CLUTTER_BACKEND = "wayland";
      GDK_BACKEND = "wayland,x11";

      #| QT settings
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";

      #| Firefox settings
      MOZ_ENABLE_WAYLAND = "1";

      #| Theme and cursor settings (The default looks better)
      # GTK_THEME = "Adwaita-dark";
      # XCURSOR_SIZE = "16";
      # XCURSOR_THEME = "Bibata-Modern-Ice";
      # GTK_THEME = gtk.name;
      # XCURSOR_SIZE = toString cursor.size;
      # XCURSOR_THEME = cursor.name;
    };
  };
}
