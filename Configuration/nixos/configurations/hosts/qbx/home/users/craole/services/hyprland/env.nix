{
  osConfig,
  pkgs,
  ...
}: let
  inherit (osConfig) nixpkgs hardware;
  nvidia = hardware.nvidia.modesetting.enable;
  vm = false; # TODO: how can i tell this system is not a vm?
in {
  wayland.windowManager.hyprland = {
    settings.env = [
      "NIXPKGS_ALLOW_UNFREE, ${
        if nixpkgs.config.allowUnfree
        then "1"
        else "0"
      }"

      #@ NVidia Settings
      "WLR_RENDERER_ALLOW_SOFTWARE, ${
        if nvidia || vm
        then "1"
        else "0"
      }"
      "WLR_NO_HARDWARE_CURSORS, ${
        if nvidia || vm
        then "1"
        else "0"
      }"
      "LIBVA_DRIVER_NAME, ${
        if nvidia || vm
        then "nvidia"
        else ""
      }"
      "__GLX_VENDOR_LIBRARY_NAME, ${
        if nvidia || vm
        then "nvidia"
        else ""
      }"
      "ELECTRON_OZONE_PLATFORM_HINT, ${
        if nvidia || vm
        then "auto"
        else ""
      }"
      "LIBVA_DRIVER_NAME, ${
        if nvidia || vm
        then "nvidia"
        else ""
      }"
      "NIXOS_OZONE_WL, ${
        if nvidia || vm
        then "1"
        else "0"
      }"

      "XDG_CURRENT_DESKTOP,Hyprland"
      "XDG_SESSION_TYPE,wayland"
      "XDG_SESSION_DESKTOP,Hyprland"

      "SDL_VIDEODRIVER,wayland" # Disable is issues
      "CLUTTER_BACKEND, wayland"
      "GDK_BACKEND,wayland,x11"

      "QT_QPA_PLATFORM,wayland;xcb"
      "QT_WAYLAND_DISABLE_WINDOWDECORATION, 1"
      "QT_AUTO_SCREEN_SCALE_FACTOR, 1"

      # "MOZ_ENABLE_WAYLAND, 1"

      # "GTK_THEME=Adwaita-dark"
      # "XCURSOR_SIZE, 16"
      # "XCURSOR_THEME, Bibata-Modern-Ice"
      # "GTK_THEME=${gtk.name}"
      # "XCURSOR_SIZE,32"
      # "XCURSOR_SIZE,${(toString cursor.size)}"
      # "XCURSOR_THEME,${cursor.name}"
    ];

    systemd = {
      enable = true;
      variables = ["-all"];
      extraCommands = [
        "systemctl --user stop graphical-session.target"
        "systemctl --user start hyprland-session.target"
      ];
    };
  };

  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = with pkgs; [xdg-desktop-portal-gtk];
  };
}
