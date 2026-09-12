{
  programs.zed-editor.userSettings = {
    theme = {
      mode = "system";
      light = "DankShell Light";
      dark = "DankShell Dark";
    };

    # Zed's editor icon theme is its own asset system, not the freedesktop
    # desktop icon theme. Candy remains the desktop-wide icon contract while
    # Zed consumes DMS for its UI/editor color palette.
    icon_theme = {
      light = "Catppuccin Latte";
      dark = "Catppuccin Frappé";
    };
  };
}
