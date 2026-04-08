{...}: {
  atuin = {
    categories = ["shell" "enhancement"];
    engine = ["rust"];
    config = {
      lang = ["toml"];
      file = "config.toml";
      home = "$XDG_CONFIG_HOME/atuin";
    };
    shells = ["bash" "zsh" "fish" "nushell"];
    maturity = "stable";
    kind = "history";
  };
  fzf = {
    categories = ["shell" "enhancement"];
    engine = ["go"];
    config = null;
    shells = ["bash" "zsh" "fish"];
    maturity = "stable";
    kind = "fuzzy";
  };
  mcfly = {
    categories = ["shell" "enhancement"];
    engine = ["rust"];
    config = {
      lang = ["toml"];
      file = "config.toml";
      home = "$XDG_DATA_HOME/mcfly";
    };
    shells = ["bash" "zsh" "fish"];
    maturity = "stable";
    kind = "history";
  };
  skim = {
    categories = ["shell" "enhancement"];
    engine = ["rust"];
    config = null;
    shells = ["bash" "zsh" "fish"];
    maturity = "stable";
    kind = "fuzzy";
  };
  zoxide = {
    categories = ["shell" "enhancement"];
    engine = ["rust"];
    config = null;
    shells = ["bash" "zsh" "fish" "nushell" "elvish" "pwsh"];
    maturity = "stable";
    kind = "navigation";
  };
}
