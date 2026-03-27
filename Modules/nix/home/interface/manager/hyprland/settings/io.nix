{
  lix,
  apps,
  lib,
  host,
  keyboard,
  ...
}: let
  inherit (lib.lists) filter;
  inherit (lib.modules) mkIf;
  inherit (lix.hardware.display) mkHyprlandMonitors;
  inherit (lix.schema.io) mkHyprKeybinds;

  systemBinds = filter (x: x != null) (
    map mkHyprKeybinds (with keyboard; [
      browser
      browserSec
      close
      code
      fileManager
      float
      fullscreen
      groupLock
      groupToggle
      lock
      logout
      maximize
      pin
      pseudo
      reboot
      reboot_soft
      screenshot
      screenshotRegion
      screenshotWindow
      shutdown
      sleep
      split
      terminal
      terminalSec
      visual
      visualSec
      windowCycle
      workspacePrev
    ])
  );

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

  bind =
    systemBinds
    # ++ [
    #   #~@ Window management (hyprland-specific, not in schema)
    #   "${mod}, S, togglesplit"
    #   "${mod}, P, pseudo"
    #   "${mod}, F, fullscreen, 1"
    #   "${mod}, G, togglegroup"
    #   "${mod}, T, lockactivegroup, toggle"
    #   "${mod}, TAB, workspace, previous"
    #   "ALT, RETURN, fullscreen, 0"
    #   "ALT SHIFT, RETURN, togglefloating"
    #   "${mod} SHIFT, F, togglefloating"
    #   "${mod} CTRL, F, pin"
    #   "ALT, TAB, focuscurrentorlast"
    # ]
    ++ [];

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
