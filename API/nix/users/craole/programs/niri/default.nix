{
  niri = {
    enable = true;
    settings = {
      layout = {
        gaps = 20;
        border = {
          width = 3;
          active.colour = "#89b4fa";
          inactive.colour = "#45475a";
        };
      };

      binds = {
        "Mod+Return".action = "spawn footclient";
        "Mod+Shift+Return".action = "spawn footclient";
        "Mod+D".action = "spawn fuzzel";
        "Mod+Q".action = "close-window";
        "Mod+1".action = "focus-workspace 1";
        "Mod+2".action = "focus-workspace 2";
      };
    };
  };
}
