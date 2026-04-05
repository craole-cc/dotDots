{
  blesh = {
    language = "bash";
    config = ".blerc";
    shells = ["bash"];
    maturity = "young";
  };
  zle = {
    language = "c";
    config = null;
    shells = ["zsh"];
    maturity = "stable";
  };
  readline = {
    language = "c";
    config = ".inputrc";
    shells = ["bash" "sh" "ksh"];
    maturity = "stable";
  };
}
