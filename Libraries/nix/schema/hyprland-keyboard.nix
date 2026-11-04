_: let
  native = action: {
    kind = "hyprland";
    inherit action;
  };
  command = action: {
    kind = "exec";
    inherit action;
  };
  fullscreen = native ''window.fullscreen({ mode = "fullscreen", action = "toggle" })'';
  floating = native ''window.float({ action = "toggle" })'';
  lock = command "dms ipc call lock lock";
  groupLock = native ''group.lock({ action = "toggle" })'';

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

  navigation = direction: workspace: [
    (native ''focus({ direction = "${direction}" })'')
    (native ''window.move({ direction = "${direction}" })'')
    (native ''focus({ workspace = "${workspace}" })'')
  ];
in {
  # Legacy named records and modern ordered groups share native dispatchers.
  # Chords are supplied separately by default, host and user keyboard scopes.
  legacy = {
    close = native "window.close()";
    inherit fullscreen;
    maximise = native ''window.fullscreen({ mode = "maximized", action = "toggle" })'';
    float = floating;
    pin = native ''window.pin({ action = "toggle" })'';
    split = native ''layout("togglesplit")'';
    pseudo = native ''window.pseudo({ action = "toggle" })'';
    groupToggle = native "group.toggle()";
    inherit groupLock;
    workspacePrev = native ''focus({ workspace = "previous" })'';
    windowCycle = native ''focus({ last = true })'';
    logout = native "exit()";
  };

  # These positional defaults apply only when a host or user declares a list.
  ordered = {
    close = [
      (native "window.close()")
      (native "exit()")
      (command "dms ipc call powermenu toggle")
    ];
    window = [fullscreen floating];
    lock = [lock (command "loginctl lock-session") groupLock];
    launcher = [
      (command "dms ipc call spotlight toggle")
      (command "dms ipc call clipboard toggle")
      (command "dms ipc call spotlight toggleWith files")
    ];
    workspaceNext = navigation "r" "e+1";
    workspacePrev = navigation "l" "e-1";
    wallpaper = [
      (command "variety --next")
      (command "variety --previous")
      (command "variety --show-preferences")
    ];
    volumeUp = volume "increment";
    volumeDown = volume "decrement";
    volumeMute = [(media "dms ipc call audio mute")];
    brightnessUp = brightness "increment";
    brightnessDown = brightness "decrement";
  };
}
