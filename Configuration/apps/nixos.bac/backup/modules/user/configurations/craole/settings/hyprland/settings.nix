{ config, ... }:
let
  inherit (config) dots;
  inherit (dots.hosts.${dots.lib.currentHost}) cpu gpu packages;
  inherit (packages) allowUnfree;
in
{
  config.dots.users.craole.applications.hyprland = {
    settings = {
      env = [
        "WLR_RENDERER_ALLOW_SOFTWARE, ${if gpu == "nvidia" || cpu == "vm" then "1" else "0"}"

        "WLR_NO_HARDWARE_CURSORS, ${if gpu == "nvidia" || cpu == "vm" then "1" else "0"}"

        "NIXPKGS_ALLOW_UNFREE, ${if allowUnfree then "1" else "0"}"

        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"

        "SDL_VIDEODRIVER,wayland" # Disable is issues
        "CLUTTER_BACKEND, wayland"
        "GDK_BACKEND,wayland,x11"

        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION, 1"
        "QT_AUTO_SCREEN_SCALE_FACTOR, 1"

        "NIXOS_OZONE_WL,1"
        # "MOZ_ENABLE_WAYLAND, 1"

        # "GTK_THEME=Adwaita-dark"
        # "XCURSOR_SIZE, 16"
        # "XCURSOR_THEME, Bibata-Modern-Ice"
        # "GTK_THEME=${gtk.name}"
        # "XCURSOR_SIZE,32"
        # "XCURSOR_SIZE,${(toString cursor.size)}"
        # "XCURSOR_THEME,${cursor.name}"
      ];

      # env = mapAttrsToList (name: value: "${name},${toString value}") {
      #   WLR_NO_HARDWARE_CURSORS =
      #     if gpu == "nvidia" || cpu == "vm"
      #     then "1"
      #     else "0";

      #   WLR_RENDERER_ALLOW_SOFTWARE =
      #     if gpu == "nvidia" || cpu == "vm"
      #     then 1
      #     else 0;

      #   NIXPKGS_ALLOW_UNFREE =
      #     if allowUnfree
      #     then 1
      #     else 0;

      #   XDG_CURRENT_DESKTOP = "Hyprland";
      #   XDG_SESSION_TYPE = "wayland";
      #   XDG_SESSION_DESKTOP = "Hyprland";

      #   GTK_THEME = gtk.name;
      #   XCURSOR_SIZE = cursor.size;
      #   XCURSOR_THEME = cursor.name;

      #   QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      #   QT_QPA_PLATFORM = "wayland;xcb";
      #   QT_AUTO_SCREEN_SCALE_FACTOR = 1;

      #   GDK_BACKEND = "wayland,x11";

      #   #   "SDL_VIDEODRIVER,wayland" # Disable is issues
      #   #   "CLUTTER_BACKEND, wayland"

      #   # SDL_VIDEODRIVER = "wayland";
      #   # _JAVA_AWT_WM_NONREPARENTING = 1;
      #   # WLR_DRM_NO_ATOMIC = 1;
      #   # CLUTTER_BACKEND = "wayland";
      #   # MOZ_ENABLE_WAYLAND = "1";
      #   # WLR_BACKEND = "vulkan";
      #   # GDK_BACKEND = "wayland";
      #   # TERM = "foot";
      #   # NIXOS_OZONE_WL = "1";
      # };
      exec-once = [
        # set cursor for HL itself
        # "hyprctl setcursor ${pointer.name} ${toString pointer.size}"
        # "systemctl --user start clight"
        # "hyprlock"
        "waybar"
        "dunst"
        "foot --server"
      ];

      general = {
        # sensitivity = 0.2;

        gaps_in = 4;
        gaps_out = 4;
        border_size = 1;
        allow_tearing = true;
        resize_on_border = true;

        layout = "dwindle";

        "col.active_border" = "rgba(88888888)";
        "col.inactive_border" = "rgba(00000088)";
      };

      debug = {
        disable_logs = false;
      };

      decoration = {
        rounding = 4;
        blur = {
          enabled = true;
          brightness = 1.0;
          contrast = 1.0;
          noise = 2.0e-2;

          passes = 3;
          size = 10;
        };

        drop_shadow = true;
        shadow_ignore_window = true;
        shadow_offset = "0 2";
        shadow_range = 20;
        shadow_render_power = 3;
        "col.shadow" = "rgba(00000055)";
      };

      animations = {
        enabled = true;
        animation = [
          "border, 1, 2, default"
          "fade, 1, 4, default"
          "windows, 1, 3, default, popin 80%"
          "workspaces, 1, 2, default, slide"
        ];
      };

      group = {
        groupbar = {
          font_size = 16;
          gradients = false;
        };

        # "col.border_active" = "rgba(${c.color_accent_primary}88);";
        # "col.border_inactive" = "rgba(${c.color_accent_primary_variant}88)";
      };

      input = {
        touchpad = {
          scroll_factor = 0.3;
          natural_scroll = false;
          tap-and-drag = true;
        };

        follow_mouse = 1;
        # force_no_accel = 1;
        # repeat_delay = 200;
        # repeat_rate = 40;
        accel_profile = "flat";
      };

      # dwindle = {
      #   # keep floating dimentions while tiling
      #   pseudotile = true;
      #   preserve_split = true;
      # };

      dwindle = {
        pseudotile = 0;
        force_split = 2;
        preserve_split = 1;
        default_split_ratio = 1.3;
      };
      master = {
        new_is_master = false;
        new_on_top = false;
        no_gaps_when_only = false;
        orientation = "top";
        mfact = 0.6;
        always_center_master = false;
      };

      misc = {
        # disable auto polling for config file changes
        disable_autoreload = true;

        force_default_wallpaper = 0;

        # disable dragging animation
        animate_mouse_windowdragging = false;

        # enable variable refresh rate (effective depending on hardware)
        vrr = 1;

        # we do, in fact, want direct scanout
        no_direct_scanout = false;
      };

      gestures = {
        # touchpad gestures
        workspace_swipe = true;
        workspace_swipe_forever = true;
      };

      xwayland = {
        force_zero_scaling = true;
      };
    };

    systemd = {
      enable = true;
      variables = [ "-all" ];
      extraCommands = [
        "systemctl --user stop graphical-session.target"
        "systemctl --user start hyprland-session.target"
      ];
    };
  };
}
