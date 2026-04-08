{...}: {
  blesh = {
    categories = ["shell" "line-editor"];
    engine = ["bash"];
    config = {
      lang = ["bash"];
      file = ".blerc";
      path = "$HOME";
    };
    shells = ["bash"];
    maturity = "young";
  };
  readline = {
    categories = ["shell" "line-editor"];
    engine = ["c"];
    config = {
      lang = ["readline"];
      file = ".inputrc";
      path = "$HOME";
    };
    shells = ["bash" "sh" "ksh"];
    maturity = "stable";
  };
  zle = {
    categories = ["shell" "line-editor"];
    engine = ["c" "zsh"];
    shells = ["zsh"];
    maturity = "stable";
  };
}
