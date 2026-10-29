{
  _,
  terminals ? [],
}: let
  inherit (_.lists.access) elemAt length;
  inherit (_.lists.construction) genList;
  command = action: {
    kind = "exec";
    inherit action;
  };
  media = action: (command action) // {locked = true;};
  scale = action:
    map (step: (media (action step)) // {repeating = true;}) [5 1 10];
  native = action: command "niri msg action ${action}";
  navigation = direction: workspace: [
    (native "focus-column-${direction}")
    (native "move-column-${direction}")
    (native "focus-workspace-${workspace}")
  ];
in {
  legacy = {
    browserSend = native "move-window-to-workspace dotdots-browser-1";
    close = native "close-window";
    fullscreen = native "fullscreen-window";
    maximise = native "maximize-window-to-edges";
    float = native "toggle-window-floating";
    pin = command "";
    split = native "consume-or-expel-window-right";
    pseudo = native "toggle-column-tabbed-display";
    groupToggle = native "toggle-column-tabbed-display";
    groupLock = native "toggle-column-tabbed-display";
    workspacePrev = native "focus-workspace-up";
    windowCycle = native "focus-window-previous";
    windowCycleReverse = native "focus-window-previous";
    windowCycleRelease = [];
    windowLast = native "focus-window-previous";
    logout = native "quit";
  };

  ordered = {
    terminalOpen = genList (index: command (elemAt terminals index).command) (
      if length terminals < 2
      then length terminals
      else 2
    );
    close = [
      (native "close-window")
      (native "quit")
      (command "dms ipc call powermenu toggle")
    ];
    window = [
      (native "fullscreen-window")
      (native "maximize-window-to-edges")
      (native "toggle-window-floating")
      (native "maximize-column")
      (native "switch-focus-between-floating-and-tiling")
      (command "niri msg action move-window-to-floating && sleep 0.2 && niri-float-sticky -ipc toggle_sticky")
    ];
    lock = [
      (command "dms ipc call lock lock")
      (command "loginctl lock-session")
      (command "dms ipc call lock lock")
    ];
    workspaceNext = navigation "right" "down";
    workspacePrev = navigation "left" "up";
    workspace = navigation "right" "down" ++ navigation "left" "up";
    windowCycle = [
      (native "focus-window-previous")
    ];
    windowCycleReverse = [
      (native "focus-window-previous")
    ];
    windowLast = [
      (native "focus-window-previous")
    ];
    logout = [
      (native "quit")
    ];
    wallpaper = [
      (command "varietyctl next")
      (command "varietyctl previous")
      (command "varietyctl preferences")
      (command "varietyctl love")
      (command "varietyctl trash")
      (command "varietyctl toggle-effects")
      (command "varietyctl snapshot")
      (command "varietyctl view")
      (command "varietyctl source")
    ];
    volume =
      scale (step: "wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ ${toString step}%+")
      ++ scale (step: "wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ ${toString step}%-")
      ++ [(media "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")];
    brightness =
      scale (step: "brightnessctl set +${toString step}%")
      ++ scale (step: "brightnessctl set ${toString step}%-");
    volumeUp = scale (step: "wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ ${toString step}%+");
    volumeDown = scale (step: "wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ ${toString step}%-");
    volumeMute = [(media "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")];
    brightnessUp = scale (step: "brightnessctl set +${toString step}%");
    brightnessDown = scale (step: "brightnessctl set ${toString step}%-");
  };
}
