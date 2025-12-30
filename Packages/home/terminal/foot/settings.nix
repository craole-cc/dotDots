{
  main = {
    app-id = "foot";
    dpi-aware = "yes";
    font = "monospace:size=18";
    pad = "8x8";
    bold-text-in-bright = "yes";

    #> Automatically copy the selection to the clipboard
    # #? Options: "none", "primary", "clipboard", "both"
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

  # url = {
  #   launch = "xdg-open \${url}"; #? Click URLs to open in browser
  #   protocols = "http, https, ftp, ftps, file";
  # };
}
