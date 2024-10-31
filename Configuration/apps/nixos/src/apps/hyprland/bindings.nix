{
  lib ? import <nixpkgs/lib> { },
  applications,
  workspaces,
  directions,
  ...
}:
let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.strings) toUpper;
in
with applications;
{

  "$MOD" = toUpper launcher.modifier;

  bind =
    [
      #| Applications
      "$MOD, GRAVE, exec, ${terminal.primary}"
      "$MOD, RETURN, exec, ${terminal.primary}"
      "CTRL ALT, RETURN,  exec, ${terminal.primary}"

      "$MODSHIFT, GRAVE, exec, ${terminal.secondary}"
      "$MODSHIFT, RETURN, exec, ${terminal.secondary}"

      "$MOD, B, exec, ${browser.primary.command}"
      "$MODSHIFT, B, exec, ${browser.secondary.command}"

      "$MOD, C, exec, ${editor.primary}"
      "$MODSHIFT, C, exec, ${editor.secondary}"

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

      "$MOD, TAB, workspace, previous" # > Cycle through active workspaces
      "ALT, TAB, focuscurrentorlast" # > Toggle the previously focused window

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
    ++ (
      # Change workspace
      map (n: "$MOD,${n},workspace,name:${n}") workspaces
    )
    ++ (
      # Move window to workspace
      map (n: "$MODSHIFT,${n},movetoworkspacesilent,name:${n}") workspaces
    )
    ++ (
      # Move focus
      mapAttrsToList (key: direction: "$MOD,${key},movefocus,${direction}") directions
    )
    ++ (
      # Swap windows
      mapAttrsToList (key: direction: "$MODSHIFT,${key},swapwindow,${direction}") directions
    )
    ++ (
      # Move windows
      mapAttrsToList (key: direction: "$MOD CONTROL,${key},movewindoworgroup,${direction}") directions
    )
    ++ (
      # Move monitor focus
      mapAttrsToList (key: direction: "$MOD ALT,${key},focusmonitor,${direction}") directions
    )
    ++ (
      # Move workspace to other monitor
      mapAttrsToList (
        key: direction: "$MOD ALTSHIFT,${key},movecurrentworkspacetomonitor,${direction}"
      ) directions
    );

  bindm = [
    "$MOD, mouse:272, movewindow"
    "$MOD, mouse:273, resizewindow"
    "$MODSHIFT, mouse:272, resizewindow"
  ];

  bindr = [
    #| Launcher
    "$MOD, $MOD_L, exec, pkill ${launcher.primary.name} || ${launcher.primary.command}"
    "$MOD, SPACE, exec, pkill ${launcher.secondary.name} || ${launcher.secondary.command}"
  ];

  bindl = [
    #| System
    "$MODSHIFT, Q, exit"
    "$MODSHIFT, ESC, exit"
    "CTRL ALT, DEL, exit"

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
