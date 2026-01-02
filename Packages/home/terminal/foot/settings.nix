{
  main = {
    app-id = "foot";
    dpi-aware = "yes";
    font = "monospace:size=18";
    pad = "8x8";
    bold-text-in-bright = "yes";

    #~@ Initial Theme
    #? Options: "dark", "light"
    initial-color-theme = "dark"; #? Start with dark theme

    #~@ Selection Behavior
    #? Automatically copy the selection to the clipboard
    #? Options: "none", "primary", "clipboard", "both"
    selection-target = "both";
  };

  bell = {
    system = "no";
    urgent = "yes";
    notify = "yes";
    visual = "no";
    command = "no";
    command-focused = "no";
  };

  mouse = {
    hide-when-typing = "yes";
    alternate-scroll-mode = "yes";
  };

  scrollback = {
    lines = 10000;
    multiplier = 3.0;
  };
}
