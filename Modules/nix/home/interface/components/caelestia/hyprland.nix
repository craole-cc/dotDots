{ mod, ... }:
{
  wayland.windowManager.hyprland.settings = {
    bindl = [
      #~@ Media controls
      "${mod} CTRL, Space, global, caelestia:mediaToggle"
      "${mod} CTRL, Equal, global, caelestia:mediaNext"
      "${mod} CTRL, Minus, global, caelestia:mediaPrev"

      #~@ Brightness
      ", XF86MonBrightnessUp, global, caelestia:brightnessUp"
      ", XF86MonBrightnessDown, global, caelestia:brightnessDown"

      #~@ Screenshot
      ", Print, exec, caelestia screenshot"
    ];

    bindr = [
      #~@ Kill/restart Caelestia
      "${mod} CTRL SHIFT, R, exec, pkill caelestia"
      "${mod} CTRL ALT, R, exec, pkill caelestia; caelestia shell -d"
    ];

    bind = [
      #~@ Drawers
      "${mod}, SPACE, exec, caelestia shell drawers toggle launcher"
      "${mod}, COMMA, exec, caelestia shell drawers toggle dashboard"
      "${mod}, SEMICOLON, exec, caelestia shell drawers toggle sidebar"
      "${mod} SHIFT, N, exec, caelestia shell drawers toggle session"
      "${mod} SHIFT, U, exec, caelestia shell drawers toggle utilities"

      #~@ Notifications
      "${mod} SHIFT, C, exec, caelestia shell notifs clear"

      #~@ Wallpaper
      "${mod} ALT, W, exec, caelestia wallpaper -r"
      "${mod} SHIFT, W, exec, caelestia shell drawers toggle launcher" # open launcher → wallpaper action

      #~@ Screenshots and recording
      "${mod} SHIFT, S, global, caelestia:screenshotFreeze"
      "${mod} SHIFT ALT, S, global, caelestia:screenshot"
      "${mod} ALT, R, exec, caelestia record -s"
      "CTRL ALT, R, exec, caelestia record"
      "${mod} SHIFT ALT, R, exec, caelestia record -r"

      #~@ Utilities
      "${mod}, V, exec, caelestia clipboard"
      "${mod} ALT, V, exec, caelestia clipboard -d"
      "${mod}, Period, exec, caelestia emoji -p"

      #~@ Special workspace toggles
      "${mod}, M, exec, caelestia toggle music"
      "${mod} ALT, M, exec, caelestia toggle sysmon"
      "${mod} ALT, D, exec, caelestia toggle communication"
      "${mod} ALT, T, exec, caelestia toggle todo"

      #~@ Resizer
      "${mod}, P, exec, caelestia resizer pip"

      #~@ Lock
      "${mod} SHIFT, L, exec, caelestia shell lock lock"
    ];
  };
}
