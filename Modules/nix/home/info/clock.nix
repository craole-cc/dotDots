{config, top, ...}: {
  programs.clock-rs = {
    enable = config.${top}.applications.utilities.clock.enable;
    settings = {
      general = {
        color = "magenta";
        interval = 250;
        blink = true;
        bold = true;
      };

      position = {
        horizontal = "start";
        vertical = "end";
      };

      date = {
        fmt = "%A, %B %d, %Y";
        use_12h = true;
        utc = false;
        hide_seconds = false;
      };
    };
  };
}
