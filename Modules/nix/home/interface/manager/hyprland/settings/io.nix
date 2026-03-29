{
  lix,
  apps,
  lib,
  host,
  keyboard,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix.hardware.display) mkHyprlandMonitors;
  inherit (lix.schema.io) mkHyprKeybindings;

  mod = keyboard.modifier;
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
    kb_options = mkIf keyboard.swapCapsEscape "caps:swapescape";
  };

  bind = mkHyprKeybindings keyboard;

  bindr = [
    "${mod}, SUPER_L, exec, ${apps.launcher.primary.command}"
  ];

  #~@ Locked binds — active even when screen is locked
  bindl = [
    ", XF86AudioPlay, exec, playerctl play-pause"
    ", XF86AudioPrev, exec, playerctl previous"
    ", XF86AudioNext, exec, playerctl next"
    ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
  ];

  #~@ Locked + repeating
  bindle = [
    ", XF86AudioRaiseVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 5%+"
    ", XF86AudioLowerVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 5%-"
    ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
    ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
  ];

  bindm = [
    "${mod}, mouse:272, movewindow"
    "${mod}, mouse:273, resizewindow"
    "${mod} SHIFT, mouse:272, resizewindow"
  ];

  binde = [
    "${mod}, EQUAL, splitratio, 0.25"
    "${mod} SHIFT, EQUAL, splitratio, 0.015"
    "${mod}, MINUS, splitratio, -0.25"
    "${mod} SHIFT, MINUS, splitratio, -0.015"
  ];
}
