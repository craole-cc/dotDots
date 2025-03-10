{
  config,
  lib,
  ...
}: let
  cfg = config.dots.services.hyprland;
  inherit (lib.modules) mkIf;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      exec-once = [
        # set cursor for HL itself
        # "hyprctl setcursor ${pointer.name} ${toString pointer.size}"
        # "systemctl --user start clight"
        "hyprlock"
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

        # drop_shadow = true; #? Does not exist
        # shadow_ignore_window = true; #? Does not exist
        # shadow_offset = "0 2"; #? Does not exist
        # shadow_range = 20; #? Does not exist
        # shadow_render_power = 3; #? Does not exist
        # "col.shadow" = "rgba(00000055)"; #? Does not exist
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

      dwindle = {
        pseudotile = 0;
        force_split = 2;
        preserve_split = 1;
        default_split_ratio = 1.3;
      };

      master = {
        # new_is_master = false; #? Does not exist
        new_on_top = false;
        # no_gaps_when_only = false; #? Does not exist
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
        # no_direct_scanout = false; #? Does not exist
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
  };
}
