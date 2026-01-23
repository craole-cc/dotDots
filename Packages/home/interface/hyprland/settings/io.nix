{
  lix,
  lib,
  host,
  keyboard,
  ...
}: let
  inherit (lix.hardware.display) mkHyprlandMonitors;
  inherit (lib.modules) mkIf;
  inherit (keyboard) mod swapCapsEscape;
in {
  monitor = mkHyprlandMonitors {inherit host;};

  input = {
    touchpad = {
      scroll_factor = 0.3;
      natural_scroll = false;
      tap-and-drag = true;
    };

    follow_mouse = false;
    accel_profile = "flat";
    kb_options = mkIf swapCapsEscape "caps:swapescape";
  };

  bind = [
    #~@ System
    "${mod}, Q, killactive"

    #~@ Windows
    "${mod}, S, togglesplit"
    "${mod}, P, pseudo"
    "ALT, RETURN, fullscreen, 0"
    "${mod}, F, fullscreen, 1"
    "ALT SHIFT, RETURN, togglefloating"
    "${mod} SHIFT, F, togglefloating"
    "${mod} CTRL, F, pin"

    "${mod}, G, togglegroup"
    "${mod}, T, lockactivegroup, toggle"

    #~@ Cycle through active workspaces
    "${mod}, TAB, workspace, previous"

    #~@ Toggle the previously focused window
    "ALT, TAB, focuscurrentorlast"

    #~@ Applications
    "${mod}, RETURN, exec, ${apps.terminal.primary.command}"
    "${mod} SHIFT, RETURN, exec, ${apps.terminal.secondary.command}"
  ];

  bindr = [
    #~@ Launcher
    "${mod}, SUPER_L, exec, ${apps.launcher.primary.command}"
    "${mod}, SPACE, exec, ${apps.launcher.secondary.command}"
  ];

  bindl = [
    #~@ System
    "${mod} CTRL, Q, exit"
    "${mod} SHIFT, ESC, exit"
    "CTRL ALT, DEL, exit"
    "CTRL ALT SHIFT, ESC, exit"

    #~@ Media Controls
    ", XF86AudioPlay, exec, playerctl play-pause"
    ", XF86AudioPrev, exec, playerctl previous"
    ", XF86AudioNext, exec, playerctl next"

    #~@ Audio
    ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
  ];

  bindle = [
    #~@ Volume
    ",XF86AudioRaiseVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 5%+"
    ",XF86AudioLowerVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 5%-"

    #~@ Backlight
    ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
    ",XF86MonBrightnessUp, exec, brightnessctl set +5%"
  ];

  bindm = [
    "${mod}, mouse:272, movewindow"
    "${mod}, mouse:273, resizewindow"
    "${mod} SHIFT, mouse:272, resizewindow"
  ];

  binde = [
    #~@ Window
    "${mod}, EQUAL, splitratio, 0.25"
    "${mod} SHIFT, EQUAL, splitratio, 0.015"
    "${mod}, MINUS, splitratio, -0.25"
    "${mod} SHIFT, MINUS, splitratio, -0.015"
  ];
}
