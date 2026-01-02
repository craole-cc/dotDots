{
  #~@ Dark Theme (Theme 1)
  #? Active when system is in dark mode or between 6pm-6am
  colors-1 = {
    alpha = 0.97;
    background = "1e1e2e";
    foreground = "cdd6f4";

    #~@ Regular Colors (0-7)
    regular0 = "45475a"; # black
    regular1 = "f38ba8"; # red
    regular2 = "a6e3a1"; # green
    regular3 = "f9e2af"; # yellow
    regular4 = "89b4fa"; # blue
    regular5 = "f5c2e7"; # magenta
    regular6 = "94e2d5"; # cyan
    regular7 = "bac2de"; # white

    #~@ Bright Colors (8-15)
    bright0 = "585b70"; # bright black
    bright1 = "f38ba8"; # bright red
    bright2 = "a6e3a1"; # bright green
    bright3 = "f9e2af"; # bright yellow
    bright4 = "89b4fa"; # bright blue
    bright5 = "f5c2e7"; # bright magenta
    bright6 = "94e2d5"; # bright cyan
    bright7 = "a6adc8"; # bright white
  };

  #~@ Light Theme (Theme 2)
  #? Active when system is in light mode or between 6am-6pm
  colors-2 = {
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
