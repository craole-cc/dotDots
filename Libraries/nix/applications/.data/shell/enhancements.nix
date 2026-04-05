{
  #~@ History
  atuin = {
    language = "rust";
    config = "atuin/config.toml";
    shells = ["bash" "zsh" "fish" "nushell"];
    maturity = "stable";
    kind = "history";
  };
  mcfly = {
    language = "rust";
    config = null;
    shells = ["bash" "zsh" "fish"];
    maturity = "stable";
    kind = "history";
  };

  #~@ Navigation
  zoxide = {
    language = "rust";
    config = null;
    shells = ["bash" "zsh" "fish" "nushell" "elvish" "pwsh"];
    maturity = "stable";
    kind = "navigation";
  };

  #~@ Fuzzy finding
  fzf = {
    language = "go";
    config = null;
    shells = ["bash" "zsh" "fish"];
    maturity = "stable";
    kind = "fuzzy";
  };
  skim = {
    language = "rust";
    config = null;
    shells = ["bash" "zsh" "fish"];
    maturity = "stable";
    kind = "fuzzy";
  };
}
