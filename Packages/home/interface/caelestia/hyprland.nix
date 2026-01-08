{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
in {
  wayland.windowManager.hyprland.settings =
    mkIf
    (config.wayland.windowManager.hyprland.enable or false) {
      exec = "hyprctl dispatch submap global";
      submap = "global";

      # Launcher with interrupt bindings
      bindi = ["SUPER, SPACE, caelestia:launcher"];

      bindin = [
        "SUPER, ESCAPE, caelestia:launcherInterrupt"
        "SUPER, mouse:272, global, caelestia:launcherInterrupt"
        "SUPER, mouse:273, global, caelestia:launcherInterrupt"
        "SUPER, mouse:274, global, caelestia:launcherInterrupt"
        "SUPER, mouse:275, global, caelestia:launcherInterrupt"
        "SUPER, mouse:276, global, caelestia:launcherInterrupt"
        "SUPER, mouse:277, global, caelestia:launcherInterrupt"
        "SUPER, mouse_up, global, caelestia:launcherInterrupt"
        "SUPER, mouse_down, global, caelestia:launcherInterrupt"
      ];

      bindl = [
        #~@ Media controls
        "SUPER CTRL, Space, global, caelestia:mediaToggle"
        ", XF86AudioPlay, global, caelestia:mediaToggle"
        ", XF86AudioPause, global, caelestia:mediaToggle"
        "SUPER CTRL, Equal, global, caelestia:mediaNext"
        ", XF86AudioNext, global, caelestia:mediaNext"
        "SUPER CTRL, Minus, global, caelestia:mediaPrev"
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
        "SUPER CTRL SHIFT, R, exec, pkill caelestia"
        "SUPER CTRL ALT, R, exec, pkill caelestia; caelestia shell -d"
      ];

      bind = [
        #~@ Screenshots and recording
        "SUPER SHIFT, S, global, caelestia:screenshotFreeze"
        "SUPER SHIFT ALT, S, global, caelestia:screenshot"
        "SUPER ALT, R, exec, caelestia record -s"
        "CTRL ALT, R, exec, caelestia record"
        "SUPER SHIFT ALT, R, exec, caelestia record -r"

        #~@ Utilities
        "SUPER, V, exec, pkill fuzzel || caelestia clipboard"
        "SUPER ALT, V, exec, pkill fuzzel || caelestia clipboard -d"
        "SUPER, Period, exec, pkill fuzzel || caelestia emoji -p"

        #~@ Special workspace toggles
        "SUPER, M, exec, caelestia toggle music"
        "SUPER ALT, M, exec, caelestia toggle sysmon"
        "SUPER ALT, D, exec, caelestia toggle communication"
        "SUPER ALT, T, exec, caelestia toggle todo"

        #~@ Resizer
        "SUPER, P, exec, caelestia resizer pip"
      ];
    };
}
