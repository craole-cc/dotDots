_: let
  native = action: {
    kind = "hyprland";
    inherit action;
  };
  command = action: {
    kind = "exec";
    inherit action;
  };
  media = action: (command action) // {locked = true;};
  volume = direction:
    map (
      step:
        (media "dms ipc call audio ${direction} ${toString step}")
        // {repeating = true;}
    ) [5 1 10];
  brightness = direction:
    map (
      step:
        (media ''dms ipc call brightness ${direction} ${toString step} ""'')
        // {repeating = true;}
    ) [5 1 10];
in {
  bindings = {
    overview.action = "dms ipc call hypr toggleOverview";
    workspaceRename.action = "dms ipc call workspace-rename open";
    keybinds.action = "dms ipc call keybinds toggle hyprland";
    lock.action = "dms ipc call lock lock";
    screenshot.action = "dms screenshot full";
    screenshotRegion.action = "dms screenshot";
    screenshotWindow.action = "dms screenshot window";
    launcher.action = "dms ipc call spotlight toggle";
    clipboard.action = "dms ipc call clipboard toggle";
    notifications.action = "dms ipc call notifications toggle";
    controlCenter.action = "dms ipc call control-center toggle";
    powerMenu.action = "dms ipc call powermenu toggle";
    taskManager.action = "dms ipc call processlist toggle";
    nightMode.action = "dms ipc call night toggle";
    doNotDisturb.action = "dms ipc call notifications toggleDoNotDisturb";
    dash.action = "dms ipc call dash toggle overview";
  };

  ordered = {
    screenshot = let
      region = command "dms screenshot";
      screen = command "dms screenshot full";
      window = command "dms screenshot window";
    in [region screen window region screen window];
    close = [
      (native "window.close()")
      (native "exit()")
      (command "dms ipc call powermenu toggle")
    ];
    lock = [
      (command "dms ipc call lock lock")
      (command "loginctl lock-session")
      (native ''group.lock_active({ action = "toggle" })'')
    ];
    launcher = [
      (command "dms ipc call spotlight toggle")
      (command "dms ipc call clipboard toggle")
      (command "dms ipc call spotlight toggleWith files")
    ];
    volumeUp = volume "increment";
    volumeDown = volume "decrement";
    volumeMute = [(media "dms ipc call audio mute")];
    brightnessUp = brightness "increment";
    brightnessDown = brightness "decrement";
    volume = volume "increment" ++ volume "decrement" ++ [(media "dms ipc call audio mute")];
    brightness = brightness "increment" ++ brightness "decrement";
  };
}
