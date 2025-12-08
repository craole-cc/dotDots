{
  host,
  lib,
  ...
}: let
  inherit (lib.lists) any;
  inherit (host) packages;
  inherit (host.specs) cpu gpu;
  isNvidia = any (b: b == "nvidia") [gpu.primary.brand gpu.secondary.brand];
  isVM = cpu.brand == "vm";
  wlr =
    if (isNvidia || isVM)
    then "1"
    else "0";
  allowUnfree =
    if packages.allowUnfree
    then "1"
    else "0";
in {
  env = [
    "WLR_RENDERER_ALLOW_SOFTWARE, ${wlr}"
    "WLR_NO_HARDWARE_CURSORS, ${wlr}"

    "NIXPKGS_ALLOW_UNFREE, ${allowUnfree}"

    "XDG_CURRENT_DESKTOP,Hyprland"
    "XDG_SESSION_TYPE,wayland"
    "XDG_SESSION_DESKTOP,Hyprland"

    "SDL_VIDEODRIVER,wayland"
    "CLUTTER_BACKEND, wayland"
    "GDK_BACKEND,wayland,x11"

    "QT_QPA_PLATFORM,wayland;xcb"
    "QT_WAYLAND_DISABLE_WINDOWDECORATION, 1"
    "QT_AUTO_SCREEN_SCALE_FACTOR, 1"

    "NIXOS_OZONE_WL,1"
    "MOZ_ENABLE_WAYLAND, 1"

    # "GTK_THEME=Adwaita-dark"
    # "XCURSOR_SIZE, 16"
    # "XCURSOR_THEME, Bibata-Modern-Ice"
    # "GTK_THEME=${gtk.name}"
    # "XCURSOR_SIZE,32"
    # "XCURSOR_SIZE,${(toString cursor.size)}"
    # "XCURSOR_THEME,${cursor.name}"
  ];

  xwayland = {
    force_zero_scaling = true;
  };
}
