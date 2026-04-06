{...}: {
  starship = {
    categories = ["shell" "prompt"];
    language = "rust";
    config = "starship.toml";
    shells = ["bash" "zsh" "fish" "nushell" "elvish" "pwsh" "tcsh"];
    maturity = "stable";
  };
  ohmyposh = {
    categories = ["shell" "prompt"];
    language = "go";
    config = ".omp.json";
    shells = ["bash" "zsh" "fish" "nushell" "pwsh"];
    maturity = "stable";
  };
  liquidprompt = {
    categories = ["shell" "prompt"];
    language = "bash";
    config = ".liquidpromptrc";
    shells = ["bash" "zsh"];
    maturity = "stable";
  };
  powerlevel10k = {
    categories = ["shell" "prompt"];
    language = "zsh";
    config = ".p10k.zsh";
    shells = ["zsh"];
    maturity = "stable";
  };
  spaceship = {
    categories = ["shell" "prompt"];
    language = "zsh";
    config = "spaceship.zsh";
    shells = ["zsh"];
    maturity = "stable";
  };
  pure = {
    categories = ["shell" "prompt"];
    language = "zsh";
    config = null;
    shells = ["zsh"];
    maturity = "stable";
  };
  prezto = {
    categories = ["shell" "prompt"];
    language = "zsh";
    config = ".zpreztorc";
    shells = ["zsh"];
    maturity = "stable";
  };
  tide = {
    categories = ["shell" "prompt"];
    language = "fish";
    config = null;
    shells = ["fish"];
    maturity = "stable";
  };
  hydro = {
    categories = ["shell" "prompt"];
    language = "fish";
    config = null;
    shells = ["fish"];
    maturity = "stable";
  };
  oh-my-nu = {
    categories = ["shell" "prompt"];
    language = "nushell";
    config = null;
    shells = ["nushell"];
    maturity = "young";
  };
  powerline = {
    categories = ["shell" "prompt"];
    language = "python";
    config = "powerline.json";
    shells = ["bash" "zsh" "fish" "pwsh"];
    maturity = "legacy";
  };
  powerline-go = {
    categories = ["shell" "prompt"];
    language = "go";
    config = null;
    shells = ["bash" "zsh" "fish" "pwsh"];
    maturity = "stable";
  };
  powerline-rs = {
    categories = ["shell" "prompt"];
    language = "rust";
    config = null;
    shells = ["bash" "zsh" "fish"];
    maturity = "niche";
  };
}
