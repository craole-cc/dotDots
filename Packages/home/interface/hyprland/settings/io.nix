{
  host,
  lib,
  user,
  apps,
  lix,
  ...
}: let
  inherit (lix.hardware.display) mkHyprlandMonitors;
  mat = lib.attrsets.mapAttrsToList;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) toUpper;
  modifier = user.interface.keyboard.modifier or host.interface.keyboard.modifier or "SUPER";
  swapCapsEscape = user.interface.keyboard.swapCapsEscape or host.interface.keyboard.swapCapsEscape or null;

  workspaces = [
    "0"
    "1"
    "2"
    "3"
    "4"
    "5"
    "6"
    "7"
    "8"
    "9"
    "F1"
    "F2"
    "F3"
    "F4"
    "F5"
    "F6"
    "F7"
    "F8"
    "F9"
    "F10"
    "F11"
    "F12"
  ];

  directions = rec {
    left = "l";
    right = "r";
    up = "u";
    down = "d";
    k = up;
    j = down;
    h = left;
    l = right;
  };
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

  "MOD" = toUpper modifier;

  bindl = [
    #| System
    "SUPER CTRL, Q, exit"
    "SUPER SHIFT, ESC, exit"
    "CTRL ALT, DEL, exit"
    "CTRL ALT SHIFT, ESC, exit"

    #| Media Controls
    ", XF86AudioPlay, exec, playerctl play-pause"
    ", XF86AudioPrev, exec, playerctl previous"
    ", XF86AudioNext, exec, playerctl next"

    #| Audio
    ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
  ];

  bindr = with apps.launcher; [
    #| Launcher
    "SUPER, SUPER_L, exec, ${primary.command}"
    "SUPER, SPACE, exec, ${secondary.command}"
  ];

  bindle = [
    #| Volume
    ",XF86AudioRaiseVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 5%+"
    ",XF86AudioLowerVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 5%-"

    #| Backlight
    ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
    ",XF86MonBrightnessUp, exec, brightnessctl set +5%"
  ];

  bindm = [
    "SUPER, mouse:272, movewindow"
    "SUPER, mouse:273, resizewindow"
    "SUPER SHIFT, mouse:272, resizewindow"
  ];

  binde = [
    #> Window
    "SUPER, EQUAL, splitratio, 0.25"
    "SUPER SHIFT, EQUAL, splitratio, 0.015"
    "SUPER, MINUS, splitratio, -0.25"
    "SUPER SHIFT, MINUS, splitratio, -0.015"
  ];

  bind =
    [
      #~@ System
      "SUPER, Q, killactive"

      #~@ Windows
      "SUPER, S, togglesplit"
      "SUPER, P, pseudo"
      "ALT, RETURN, fullscreen, 0"
      "SUPER, F, fullscreen, 1"
      "ALT SHIFT, RETURN, togglefloating"
      "SUPER SHIFT, F, togglefloating"
      "SUPER CTRL, F, pin"

      "SUPER, G, togglegroup"
      "SUPER, T, lockactivegroup, toggle"

      #~@ Cycle through active workspaces
      "SUPER, TAB, workspace, previous"

      #~@ Toggle the previously focused window
      "ALT, TAB, focuscurrentorlast"
    ]
    #> Change workspace
    ++ (map (n: "SUPER,${n},workspace,name:${n}") workspaces)
    #> Move window to workspace
    ++ (map (n: "SUPER SHIFT,${n},movetoworkspacesilent,name:${n}") workspaces)
    #> Move focus
    ++ (mat (key: direction: "SUPER,${key},movefocus,${direction}") directions)
    #> Swap windows
    ++ (mat (key: direction: "SUPER SHIFT,${key},swapwindow,${direction}") directions)
    #> Move windows
    ++ (mat (key: direction: "SUPER CONTROL,${key},movewindoworgroup,${direction}") directions)
    #> Move monitor focus
    ++ (mat (key: direction: "SUPER ALT,${key},focusmonitor,${direction}") directions)
    #> Move workspace to other monitor
    ++ (mat (
        key: direction: "SUPER ALT SHIFT,${key},movecurrentworkspacetomonitor,${direction}"
      )
      directions)
    ++ (with apps; [
      #~@ Applications
      # "SUPER, GRAVE, exec,  ${terminal.primary.command}"
      # "SUPER SHIFT, GRAVE, exec, ${terminal.secondary.command}"
      # "SUPER, B, exec, ${browser.primary.command}"
      # "SUPER SHIFT, B, exec, ${browser.secondary.command}"
      # "SUPER, C, exec, ${editor.primary.command}"
      # "SUPER SHIFT, C, exec, ${editor.secondary.command}"

      # "SUPER, GRAVE, exec, ${terminal.primary.command}"
      "SUPER, RETURN, exec, ${terminal.primary.command}"
      "SUPER SHIFT, RETURN, exec, ${terminal.secondary.command}"
    ]);
}
