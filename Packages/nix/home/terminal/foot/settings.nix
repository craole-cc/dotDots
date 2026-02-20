{
  main = {
    app-id = "foot";
    dpi-aware = "yes";
    font = "monospace:size=13";
    pad = "24x24";
    bold-text-in-bright = "yes";

    #~@ Initial Theme
    #? Options: "dark", "light"
    # initial-color-theme = 1; #? Start with dark theme
    initial-color-theme = "dark";

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
