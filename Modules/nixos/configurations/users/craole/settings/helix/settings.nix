let
  app = "helix";
  user = "craole";
in
{
  config.dot.users.${user}.applications.${app} = {
    settings = {
      auto-save = true;
      auto-format = true;
      bufferline = "never";
      cursorline = true;
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
      idle-timeout = 50;
      line-number = "relative";
      lsp = {
        auto-signature-help = true;
        display-inlay-hints = true;
        display-messages = true;
        display-signature-help-docs = true;
        snippets = true;
      };
      indent-guides = {
        render = true;
        character = "╎"; # "▏", "╎", "┆", "┊", "⸽"
        skip-levels = 1;
        rainbow-option = "normal";
      };
      mouse = false;
      soft-wrap = {
        enable = true;
        wrap-at-text-width = true;
      };
      text-width = 120;
    };
  };
}
