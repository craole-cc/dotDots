{mod, ...}: {
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
      #~@ Screenshots and recording
      "${mod} SHIFT, S, global, caelestia:screenshotFreeze"
      "${mod} SHIFT ALT, S, global, caelestia:screenshot"
      "${mod} ALT, R, exec, caelestia record -s"
      "CTRL ALT, R, exec, caelestia record"
      "${mod} SHIFT ALT, R, exec, caelestia record -r"

      #~@ Utilities
      "${mod}, V, exec, pkill fuzzel || caelestia clipboard"
      "${mod} ALT, V, exec, pkill fuzzel || caelestia clipboard -d"
      "${mod}, Period, exec, pkill fuzzel || caelestia emoji -p"

      #~@ Special workspace toggles
      # "${mod}, Grave, exec, caelestia toggle terminal"
      # "${mod} SHIFT, Grave, exec, caelestia toggle development"
      "${mod}, M, exec, caelestia toggle music"
      "${mod} ALT, M, exec, caelestia toggle sysmon"
      "${mod} ALT, D, exec, caelestia toggle communication"
      "${mod} ALT, T, exec, caelestia toggle todo"

      #~@ Resizer
      "${mod}, P, exec, caelestia resizer pip"
    ];
  };
}
