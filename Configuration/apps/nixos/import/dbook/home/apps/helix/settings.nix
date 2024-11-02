{
  programs.helix.settings = {
    editor = {
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
        left = ["mode" "spinner" "spacer" "file-modification-indicator"];
        center = ["file-name"];
        right = ["diagnostics" "version-control" "selections" "file-encoding"];
        mode = {
          normal = "NORMAL";
          insert = "INSERT";
          select = "SELECT";
        };
        seperator = "|";
      };
      idle-timeout=50;
      line-number="relative";
      lsp={
        auto-signature-help=true;
        display-inlay-hints=true;
        display-messages=true;
        display-signature-help-docs=true;
        snippets=true;
      };
      # indent
    };
  };
}
