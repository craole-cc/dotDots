{...}: {
  atuin = {
    categories = ["shell" "enhancement"];
    language = "rust";
    config = "atuin/config.toml";
    shells = ["bash" "zsh" "fish" "nushell"];
    maturity = "stable";
    kind = "history";
  };
  mcfly = {
    categories = ["shell" "enhancement"];
    language = "rust";
    config = null;
    shells = ["bash" "zsh" "fish"];
    maturity = "stable";
    kind = "history";
  };
  zoxide = {
    categories = ["shell" "enhancement"];
    language = "rust";
    config = null;
    shells = ["bash" "zsh" "fish" "nushell" "elvish" "pwsh"];
    maturity = "stable";
    kind = "navigation";
  };
  fzf = {
    categories = ["shell" "enhancement"];
    language = "go";
    config = null;
    shells = ["bash" "zsh" "fish"];
    maturity = "stable";
    kind = "fuzzy";
  };
  skim = {
    categories = ["shell" "enhancement"];
    language = "rust";
    config = null;
    shells = ["bash" "zsh" "fish"];
    maturity = "stable";
    kind = "fuzzy";
  };
}
