{
  #~@ Catppuccin Frappe (Dark Theme)
  #? Active when system is in dark mode
  colors-dark = {
    alpha = 0.97;
    background = "303446";
    foreground = "c6d0f5";

    #~@ Regular Colors (0-7)
    regular0 = "51576d"; # black
    regular1 = "e78284"; # red
    regular2 = "a6d189"; # green
    regular3 = "e5c890"; # yellow
    regular4 = "8caaee"; # blue
    regular5 = "f4b8e4"; # magenta
    regular6 = "81c8be"; # cyan
    regular7 = "b5bfe2"; # white

    #~@ Bright Colors (8-15)
    bright0 = "626880"; # bright black
    bright1 = "e78284"; # bright red
    bright2 = "a6d189"; # bright green
    bright3 = "e5c890"; # bright yellow
    bright4 = "8caaee"; # bright blue
    bright5 = "f4b8e4"; # bright magenta
    bright6 = "81c8be"; # bright cyan
    bright7 = "a5adce"; # bright white
  };

  #~@ Catppuccin Latte (Light Theme)
  #? Active when system is in light mode
  colors-light = {
    alpha = 0.97;
    background = "eff1f5";
    foreground = "4c4f69";

    #~@ Regular Colors (0-7)
    regular0 = "5c5f77"; # black
    regular1 = "d20f39"; # red
    regular2 = "40a02b"; # green
    regular3 = "df8e1d"; # yellow
    regular4 = "1e66f5"; # blue
    regular5 = "ea76cb"; # magenta
    regular6 = "179299"; # cyan
    regular7 = "acb0be"; # white

    #~@ Bright Colors (8-15)
    bright0 = "6c6f85"; # bright black
    bright1 = "d20f39"; # bright red
    bright2 = "40a02b"; # bright green
    bright3 = "df8e1d"; # bright yellow
    bright4 = "1e66f5"; # bright blue
    bright5 = "ea76cb"; # bright magenta
    bright6 = "179299"; # bright cyan
    bright7 = "bcc0cc"; # bright white
  };

  #~@ Cursor Configuration
  #? Visual appearance and behavior of the text cursor
  cursor = {
    style = "beam"; #? Options: block, underline, beam
    blink = "yes";
    blink-rate = 500;
    beam-thickness = 1.5;
  };
}
