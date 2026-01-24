{mod, ...}: {
  wayland.windowManager.hyprland.settings = {
    exec = "hyprctl dispatch submap global";
    submap = "global";

    # # Launcher with interrupt bindings
    # bindi = ["${mod}, SPACE, caelestia:launcher"];

    bindin = [
      # "${mod}, ESCAPE, caelestia:launcherInterrupt"
      # "${mod}, mouse:272, global, caelestia:launcherInterrupt"
      # "${mod}, mouse:273, global, caelestia:launcherInterrupt"
      # "${mod}, mouse:274, global, caelestia:launcherInterrupt"
      # "${mod}, mouse:275, global, caelestia:launcherInterrupt"
      # "${mod}, mouse:276, global, caelestia:launcherInterrupt"
      # "${mod}, mouse:277, global, caelestia:launcherInterrupt"
      # "${mod}, mouse_up, global, caelestia:launcherInterrupt"
      # "${mod}, mouse_down, global, caelestia:launcherInterrupt"
    ];

    bindl = [
      #~@ Media controls
      "${mod} CTRL, Space, global, caelestia:mediaToggle"
      ", XF86AudioPlay, global, caelestia:mediaToggle"
      ", XF86AudioPause, global, caelestia:mediaToggle"
      "${mod} CTRL, Equal, global, caelestia:mediaNext"
      ", XF86AudioNext, global, caelestia:mediaNext"
      "${mod} CTRL, Minus, global, caelestia:mediaPrev"
      ", XF86AudioPrev, global, caelestia:mediaPrev"
      ", XF86AudioStop, global, caelestia:mediaStop"

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
