{
  auto-format = true; # [Default: true]
  auto-save = {
    after-delay = {
      enable = true;
      timeout = 2500;
    };
  };
  cursorline = true; # [Default: false]
  cursor-shape = {
    insert = "bar";
    normal = "block";
    select = "underline";
  };
  statusline = {
    left = [
      "mode"
      "spinner"
      "spacer"
      "file-modification-indicator"
    ];
    center = [ "file-name" ];
    right = [
      "diagnostics"
      "version-control"
      "selections"
      "position"
      "file-encoding"
    ];
    mode = {
      normal = "NORMAL";
      insert = "INSERT";
      select = "SELECT";
    };
    separator = "│";
  };
  # idle-timeout = 150; # [Default: 250]
  indent-guides = {
    render = true; # [Default: false]
    character = "╎"; # "▏", "╎", "┆", "┊", "⸽"
    skip-levels = 1;
  };
  line-number = "relative";
  lsp = {
    enable = true; # [Default: true]
    display-messages = true; # [Default: true]
    display-progress-messages = true; # [Default: false]
    auto-signature-help = true; # [Default: true]
    display-inlay-hints = true; # [Default: false]
    display-signature-help-docs = true; # [Default: true]
    snippets = true; # [Default: true]
    goto-reference-include-declaration = true; # [Default: true]
  };
  mouse = false; # [Default: true]
  soft-wrap = {
    enable = false; # [Default: false]
    max-wrap = 24; # [Default: 20]
    max-indent-retain = 0; # [Default: 40]
    # wrap-indicator = ""; # [Default: "↪"]
    wrap-at-text-width = true; # [Default: false]
  };
  # text-width = 120;
}
