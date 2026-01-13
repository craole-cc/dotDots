{
  host,
  lib,
  user,
  lix,
  ...
}: let
  inherit (lix.hardware.display) mkHyprlandMonitors;
  inherit (lib.modules) mkIf;
  swapCapsEscape = user.interface.keyboard.swapCapsEscape or host.interface.keyboard.swapCapsEscape or null;
in {
  monitor = mkHyprlandMonitors {inherit host;};

  input = {
    touchpad = {
      scroll_factor = 0.3;
      natural_scroll = false;
      tap-and-drag = true;
    };

    follow_mouse = true;
    # force_no_accel = 1;
    # repeat_delay = 200;
    # repeat_rate = 40;
    accel_profile = "flat";
    kb_options = mkIf swapCapsEscape "caps:swapescape";
  };

  bindl = [
    #~@ System
    "$MOD CTRL, Q, exit"
    "$MOD SHIFT, ESC, exit"
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

  bindr = [
    #~@ Launcher
    "$MOD, SUPER_L, exec, $launcher"
    "$MOD, SPACE, exec, $launcherAlt"
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
    "$MOD, mouse:272, movewindow"
    "$MOD, mouse:273, resizewindow"
    "$MOD SHIFT, mouse:272, resizewindow"
  ];

  binde = [
    #~@ Window
    "$MOD, EQUAL, splitratio, 0.25"
    "$MOD SHIFT, EQUAL, splitratio, 0.015"
    "$MOD, MINUS, splitratio, -0.25"
    "$MOD SHIFT, MINUS, splitratio, -0.015"
  ];

  bind =
    [
      #~@ System
      "$MOD, Q, killactive"

      #~@ Windows
      "$MOD, S, togglesplit"
      "$MOD, P, pseudo"
      "ALT, RETURN, fullscreen, 0"
      "$MOD, F, fullscreen, 1"
      "ALT SHIFT, RETURN, togglefloating"
      "$MOD SHIFT, F, togglefloating"
      "$MOD CTRL, F, pin"

      "$MOD, G, togglegroup"
      "$MOD, T, lockactivegroup, toggle"

      #~@ Cycle through active workspaces
      "$MOD, TAB, workspace, previous"

      #~@ Toggle the previously focused window
      "ALT, TAB, focuscurrentorlast"
    ]
    ++ [
      #~@ Applications
      # "$MOD, GRAVE, exec,  ${terminal.primary.command}"
      # "$MOD SHIFT, GRAVE, exec, ${terminal.secondary.command}"
      # "$MOD, B, exec, ${browser.primary.command}"
      # "$MOD SHIFT, B, exec, ${browser.secondary.command}"
      # "$MOD, C, exec, ${editor.primary.command}"
      # "$MOD SHIFT, C, exec, ${editor.secondary.command}"

      # "$MOD, GRAVE, exec, ${terminal.primary.command}"
      "$MOD, RETURN, exec, $terminal"
      "$MOD SHIFT, RETURN, exec, $terminalAlt"
    ];
}
