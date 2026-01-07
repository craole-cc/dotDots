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
        name = "zen-twilight";
        command = "zen-twilight";
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
        name = "caelestia";
        command = "caelestia:launcher";
      };
      secondary = {
        name = "vicinae";
        command = "vicinae toggle";
        # name = "fuzzel";
        # command = "fuzzel --list-executables-in-path";
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
  monitor = mkHyprlandMonitors {inherit host;};

  input = {
    touchpad = {
      scroll_factor = 0.3;
      natural_scroll = false;
      tap-and-drag = true;
    };

    follow_mouse = "0";
    # force_no_accel = 1;
    # repeat_delay = 200;
    # repeat_rate = 40;
    accel_profile = "flat";
    # kb_options = mkIf swapCapsEscape "caps:swapescape";
  };

  # "SUPER" = toUpper modifier;

  bindl = [
    #| System
    "SUPER SHIFT, Q, exit"
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

  # bindi = [
  #   "SUPER, SUPER_L, global, ${launcher.primary.command}"
  # ];

  bindr = with launcher; [
    #| Launcher
    "SUPER, SUPER_L, global, ${primary.command}"
    "SUPER, SPACE, exec,  ${secondary.command}"
    # "SUPER, SPACE, exec, pkill ${secondary.name} || ${secondary.command}"
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
      #| System
      "SUPER, Q, killactive"

      #| Applications
      # "SUPER, GRAVE, exec,  ${terminal.primary.command}"
      # "SUPER SHIFT, GRAVE, exec, ${terminal.secondary.command}"
      "SUPER, B, exec, ${browser.primary.command}"
      "SUPER SHIFT, B, exec, ${browser.secondary.command}"
      "SUPER, C, exec, ${editor.primary.command}"
      "SUPER SHIFT, C, exec, ${editor.secondary.command}"

      # "SUPER, GRAVE, exec, ${terminal.primary.command}"
      "SUPER, RETURN, exec, ${terminal.primary.command}"
      "CTRL ALT, RETURN,  exec, ${terminal.primary.command}"
      "SUPER SHIFT, RETURN, exec, ${terminal.secondary.command}"
      # "SUPER SHIFT, C, exec, ${editor.secondary.command}"

      # | Windows
      "SUPER, S, togglesplit"
      "SUPER, P, pseudo"

      "ALT, RETURN, fullscreen, 0"
      "ALT SHIFT, RETURN, togglefloating"
      # "SUPER, F, fullscreen, 1"
      # "SUPER SHIFT, F, togglefloating"

      "SUPER, G, togglegroup"
      "SUPER, T, lockactivegroup, toggle"

      #~@ Cycle through active workspaces
      "SUPER, TAB, workspace, previous"

      #~@ Toggle the previously focused window
      "ALT, TAB, focuscurrentorlast"

      "SUPER, U, togglespecialworkspace"
      # "SUPER ALT, F, pin"

      #| Workspaces
      # special workspace
      # "SUPER SHIFT, grave, movetoworkspace, special"
      # "SUPER, grave, togglespecialworkspace, eDP-1"

      # cycle workspaces
      "SUPER, bracketleft, workspace, m-1"
      "SUPER, bracketright, workspace, m+1"

      # cycle monitors
      "SUPER SHIFT, bracketleft, focusmonitor, l"
      "SUPER SHIFT, bracketright, focusmonitor, r"

      # "SUPER, V, movetoworkspace, special"
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
      directions);
}
