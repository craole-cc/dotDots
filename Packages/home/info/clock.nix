{
  programs.clock-rs = {
    enable = true;
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
}
