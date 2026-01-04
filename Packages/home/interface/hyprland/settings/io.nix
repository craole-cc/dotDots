{
  host,
  lib,
  lix,
  ...
}: let
  inherit (lix.hardware.display) mkHyprlandMonitors;
  applications = {
    terminal = {
      primary = {
        name = "ghostty";
        command = "ghostty";
      };
      secondary = {
        name = "foot";
        command = "footclient";
      };
    };
    browser = {
      primary = {
        name = "firefox";
        command = "firefox";
      };
      secondary = {
        name = "microsoft-edge";
        command = "microsoft-edge";
      };
    };
    editor = {
      primary = {
        name = "code";
        command = "code";
      };
      secondary = {
        name = "zed";
        command = "zeditor";
      };
    };
    launcher = {
      primary = {
        name = "vicinae";
        command = "vicinae open";
      };
      secondary = {
        name = "fuzzel";
        command = "fuzzel --list-executables-in-path";
      };
    };
  };
  inherit
    (applications)
    launcher
    terminal
    browser
    editor
    ;
  mat = lib.attrsets.mapAttrsToList;
  inherit (lib.strings) toUpper;
  # inherit (host.interface.keyboard) modifier swapCapsEscape;
  modifier = host.interface.keyboard.modifier or "SUPER";

  workspaces = [
    # "grave"
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
  "$MOD" = toUpper modifier;

  monitor = mkHyprlandMonitors {inherit host;};

  # input = {
  #   touchpad = {
  #     scroll_factor = 0.3;
  #     natural_scroll = false;
  #     tap-and-drag = true;
  #   };

  #   follow_mouse = 1;
  #   # force_no_accel = 1;
  #   # repeat_delay = 200;
  #   # repeat_rate = 40;
  #   accel_profile = "flat";
  #   kb_options = mkIf swapCapsEscape "caps:swapescape";
  # };

  # gestures = {
  #   workspace_swipe = true;
  #   workspace_swipe_forever = true;
  # };

  bind =
    [
      #| Applications
      "$MOD, GRAVE, exec, $TERMINAL_PRI"
      # "$MOD, GRAVE, exec, ${terminal.primary.command}"
      "$MOD, RETURN, exec, ${terminal.primary.command}"
      "CTRL ALT, RETURN,  exec, ${terminal.primary.command}"

      "$MODSHIFT, GRAVE, exec, ${terminal.secondary.command}"
      "$MODSHIFT, RETURN, exec, ${terminal.secondary.command}"

      "$MOD, B, exec, ${browser.primary.command}"
      "$MODSHIFT, B, exec, ${browser.secondary.command}"

      "$MOD, C, exec, ${editor.primary.command}"
      "$MODSHIFT, C, exec, ${editor.secondary.command}"

      #| System
      "$MOD, Q, killactive"

      # | Windows
      "$MOD, S, togglesplit"
      "$MOD, P, pseudo"

      "ALT, RETURN, fullscreen, 0"
      "ALT SHIFT, RETURN, togglefloating"
      # "$MOD, F, fullscreen, 1"
      # "$MODSHIFT, F, togglefloating"

      "$MOD, G, togglegroup"
      "$MOD, T, lockactivegroup, toggle"

      #~@ Cycle through active workspaces
      "$MOD, TAB, workspace, previous"

      #~@ Toggle the previously focused window
      "ALT, TAB, focuscurrentorlast"

      "$MOD, U, togglespecialworkspace"
      # "$MOD ALT, F, pin"

      #| Workspaces
      # special workspace
      # "$MOD SHIFT, grave, movetoworkspace, special"
      # "$MOD, grave, togglespecialworkspace, eDP-1"

      # cycle workspaces
      "$MOD, bracketleft, workspace, m-1"
      "$MOD, bracketright, workspace, m+1"

      # cycle monitors
      "$MODSHIFT, bracketleft, focusmonitor, l"
      "$MODSHIFT, bracketright, focusmonitor, r"

      # "$MOD, V, movetoworkspace, special"
    ]
    #~@ Change workspace
    ++ (map (n: "$MOD,${n},workspace,name:${n}") workspaces)
    #~@ Move window to workspace
    ++ (map (n: "$MODSHIFT,${n},movetoworkspacesilent,name:${n}") workspaces)
    #~@ Move focus
    ++ (mat (key: direction: "$MOD,${key},movefocus,${direction}") directions)
    #~@ Swap windows
    ++ (mat (key: direction: "$MODSHIFT,${key},swapwindow,${direction}") directions)
    #~@ Move windows
    ++ (mat (key: direction: "$MOD CONTROL,${key},movewindoworgroup,${direction}") directions)
    #~@ Move monitor focus
    ++ (mat (key: direction: "$MOD ALT,${key},focusmonitor,${direction}") directions)
    #~@ Move workspace to other monitor
    ++ (mat (
        key: direction: "$MOD ALTSHIFT,${key},movecurrentworkspacetomonitor,${direction}"
      )
      directions);

  bindm = [
    "$MOD, mouse:272, movewindow"
    "$MOD, mouse:273, resizewindow"
    "$MODSHIFT, mouse:272, resizewindow"
  ];

  bindr = with launcher; [
    #| Launcher
    "$MOD, $MOD_L, exec, ${primary.command}"
    "$MOD, SPACE, exec, ${secondary.command}"
    # "$MOD, $MOD_L, exec, pkill ${primary.name} || ${primary.command}"
    # "$MOD, SPACE, exec, pkill ${secondary.name} || ${secondary.command}"
  ];

  bindl = [
    #| System
    "$MODSHIFT, Q, exit"
    "$MODSHIFT, ESC, exit"
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

  bindle = [
    #| Volume
    ",XF86AudioRaiseVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 5%+"
    ",XF86AudioLowerVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 5%-"

    #| Backlight
    ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
    ",XF86MonBrightnessUp, exec, brightnessctl set +5%"
  ];

  binde = [
    #> Window
    "$MOD, EQUAL, splitratio, 0.25"
    "$MODSHIFT, EQUAL, splitratio, 0.015"
    "$MOD, MINUS, splitratio, -0.25"
    "$MODSHIFT, MINUS, splitratio, -0.015"
  ];
}
