{...}: {
  blesh = {
    categories = ["shell" "line-editor"];
    engine = ["bash"];
    config = {
      lang = ["bash"];
      file = ".blerc";
      home = "$HOME";
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
      home = "$HOME";
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
