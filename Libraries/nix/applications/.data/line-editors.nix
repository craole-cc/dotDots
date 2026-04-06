{...}: {
  blesh = {
    categories = ["shell" "line-editor"];
    language = "bash";
    config = ".blerc";
    shells = ["bash"];
    maturity = "young";
  };
  zle = {
    categories = ["shell" "line-editor"];
    language = "c";
    config = null;
    shells = ["zsh"];
    maturity = "stable";
  };
  readline = {
    categories = ["shell" "line-editor"];
    language = "c";
    config = ".inputrc";
    shells = ["bash" "sh" "ksh"];
    maturity = "stable";
  };
}
