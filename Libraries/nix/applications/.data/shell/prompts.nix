{
  #~@ Cross-shell (work in bash, zsh, fish, nushell, etc.)
  starship = {
    language = "rust";
    config = "starship.toml";
    shells = ["bash" "zsh" "fish" "nushell" "elvish" "pwsh" "tcsh"];
    maturity = "stable";
  };
  ohmyposh = {
    language = "go";
    config = ".omp.json";
    shells = ["bash" "zsh" "fish" "nushell" "pwsh"];
    maturity = "stable";
  };
  liquidprompt = {
    language = "bash";
    config = ".liquidpromptrc";
    shells = ["bash" "zsh"];
    maturity = "stable";
  };

  #~@ Zsh-specific
  powerlevel10k = {
    language = "zsh";
    config = ".p10k.zsh";
    shells = ["zsh"];
    maturity = "stable";
  };
  spaceship = {
    language = "zsh";
    config = "spaceship.zsh";
    shells = ["zsh"];
    maturity = "stable";
  };
  pure = {
    language = "zsh";
    config = null;
    shells = ["zsh"];
    maturity = "stable";
  };
  prezto = {
    language = "zsh";
    config = ".zpreztorc";
    shells = ["zsh"];
    maturity = "stable";
  };

  #~@ Fish-specific
  tide = {
    language = "fish";
    config = null;
    shells = ["fish"];
    maturity = "stable";
  };
  hydro = {
    language = "fish";
    config = null;
    shells = ["fish"];
    maturity = "stable";
  };

  #~@ Nushell-specific
  oh-my-nu = {
    language = "nushell";
    config = null;
    shells = ["nushell"];
    maturity = "young";
  };

  #~@ Powerline-based
  powerline = {
    language = "python";
    config = "powerline.json";
    shells = ["bash" "zsh" "fish" "pwsh"];
    maturity = "legacy";
  };
  powerline-go = {
    language = "go";
    config = null;
    shells = ["bash" "zsh" "fish" "pwsh"];
    maturity = "stable";
  };
  powerline-rs = {
    language = "rust";
    config = null;
    shells = ["bash" "zsh" "fish"];
    maturity = "niche";
  };
}
