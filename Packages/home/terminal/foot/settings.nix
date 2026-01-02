{
  main = {
    app-id = "foot";
    dpi-aware = "yes";
    font = "monospace:size=14";
    pad = "8x8";
    bold-text-in-bright = "yes";

    #~@ Initial Theme
    #? Options: 1 (dark), 2 (light)
    initial-color-theme = "1"; # Start with dark theme

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
