{...}: {
  hydro = {
    categories = ["shell" "prompt"];
    engine = ["fish"];
    shells = ["fish"];
    maturity = "stable";
  };
  liquidprompt = {
    categories = ["shell" "prompt"];
    engine = ["bash"];
    config = {
      lang = ["bash"];
      file = ".liquidpromptrc";
      path = "$HOME";
    };
    shells = ["bash" "zsh"];
    maturity = "stable";
  };
  oh-my-nu = {
    categories = ["shell" "prompt"];
    engine = ["nu"];
    shells = ["nushell"];
    maturity = "young";
  };
  ohmyposh = {
    categories = ["shell" "prompt"];
    engine = ["go"];
    config = {
      lang = ["toml"];
      file = "zen.toml";
      path = "$XDG_CONFIG_HOME/ohmyposh";
    };
    shells = ["bash" "zsh" "fish" "nushell" "pwsh"];
    maturity = "stable";
  };
  powerlevel10k = {
    categories = ["shell" "prompt"];
    engine = ["zsh"];
    config = {
      lang = ["zsh"];
      file = ".p10k.zsh";
      path = "$HOME";
    };
    shells = ["zsh"];
    maturity = "stable";
  };
  powerline = {
    categories = ["shell" "prompt"];
    engine = ["python"];
    config = {
      lang = ["json"];
      file = "config.json";
      path = "$XDG_CONFIG_HOME/powerline";
    };
    shells = ["bash" "zsh" "fish" "pwsh"];
    maturity = "legacy";
  };
  powerline-go = {
    categories = ["shell" "prompt"];
    engine = ["go"];
    shells = ["bash" "zsh" "fish" "pwsh"];
    maturity = "stable";
  };
  powerline-rs = {
    categories = ["shell" "prompt"];
    engine = ["rust"];
    shells = ["bash" "zsh" "fish"];
    maturity = "young";
  };
  prezto = {
    categories = ["shell" "prompt"];
    engine = ["zsh"];
    config = {
      lang = ["zsh"];
      file = ".zpreztorc";
      path = "$HOME";
    };
    shells = ["zsh"];
    maturity = "stable";
  };
  pure = {
    categories = ["shell" "prompt"];
    engine = ["zsh"];
    shells = ["zsh"];
    maturity = "stable";
  };
  spaceship = {
    categories = ["shell" "prompt"];
    engine = ["zsh"];
    config = {
      lang = ["zsh"];
      file = "spaceship.zsh";
      path = "$XDG_CONFIG_HOME/spaceship";
    };
    shells = ["zsh"];
    maturity = "stable";
  };
  starship = {
    categories = ["shell" "prompt"];
    engine = ["rust"];
    config = {
      lang = ["toml"];
      file = "starship.toml";
      path = "$XDG_CONFIG_HOME";
    };
    shells = ["bash" "zsh" "fish" "nushell" "elvish" "pwsh" "tcsh"];
    maturity = "stable";
  };
  tide = {
    categories = ["shell" "prompt"];
    engine = ["fish"];
    shells = ["fish"];
    maturity = "stable";
  };
}
