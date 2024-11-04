{
  host,
  user,
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:
with lib;
let
  inherit (host.processor) cpu gpu;
  inherit (user) allowUnfree;
in
mapAttrsToList (name: value: "${name},${toString value}") {
  WLR_NO_HARDWARE_CURSORS = if gpu == "nvidia" || cpu == "vm" then 1 else 0;
  WLR_RENDERER_ALLOW_SOFTWARE = if gpu == "nvidia" || cpu == "vm" then 1 else 0;
  NIXPKGS_ALLOW_UNFREE = if allowUnfree then 1 else 0;

  XDG_CURRENT_DESKTOP = "Hyprland";
  XDG_SESSION_TYPE = "wayland";
  XDG_SESSION_DESKTOP = "Hyprland";

  # GTK_THEME = gtk.name;
  # XCURSOR_SIZE = cursor.size;
  # XCURSOR_THEME = cursor.name;

  QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  QT_QPA_PLATFORM = "wayland;xcb";
  QT_AUTO_SCREEN_SCALE_FACTOR = 1;

  GDK_BACKEND = "wayland,x11";

  #   "SDL_VIDEODRIVER,wayland" # This is know to be problematic
  #   "CLUTTER_BACKEND, wayland"

  # SDL_VIDEODRIVER = "wayland";
  # _JAVA_AWT_WM_NONREPARENTING = 1;
  # WLR_DRM_NO_ATOMIC = 1;
  # CLUTTER_BACKEND = "wayland";
  # MOZ_ENABLE_WAYLAND = "1";
  # WLR_BACKEND = "vulkan";
  # GDK_BACKEND = "wayland";
  # TERM = "foot";
  # NIXOS_OZONE_WL = "1";
}
