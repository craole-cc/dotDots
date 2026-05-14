_: {
  bash = {
    categories = [ "shell" ];
    config = {
      lang = [ "bash" ];
      file = ".bashrc";
      home = "$HOME";
    };
    engine = [ "c" ];
    interactive = true;
    posix = true;
    system = true;
    maturity = "stable";
  };
  dash = {
    categories = [ "shell" ];
    config = {
      lang = [ "sh" ];
      file = ".profile";
      home = "$HOME";
    };
    engine = [ "c" ];
    interactive = true;
    maturity = "stable";
    posix = true;
    system = true;
  };
  elvish = {
    categories = [ "shell" ];
    posix = false;
    interactive = true;
    system = false;
    engine = [ "go" ];
    config = {
      lang = [ "elvish" ];
      file = "rc.elv";
      home = "$XDG_CONFIG_HOME/elvish";
    };
    maturity = "young";
  };
  fish = {
    categories = [ "shell" ];
    posix = false;
    interactive = true;
    system = false;
    engine = [ "rust" ];
    config = {
      lang = [ "fish" ];
      file = "config.fish";
      home = "$XDG_CONFIG_HOME/fish";
    };
    maturity = "stable";
  };
  ksh = {
    categories = [ "shell" ];
    posix = true;
    interactive = true;
    system = true;
    engine = [ "c" ];
    config = {
      lang = [ "ksh" ];
      file = ".kshrc";
      home = "$HOME";
    };
    maturity = "stable";
  };
  nushell = {
    categories = [ "shell" ];
    posix = false;
    interactive = true;
    system = false;
    engine = [ "rust" ];
    config = {
      lang = [ "nu" ];
      file = "config.nu";
      home = "$XDG_CONFIG_HOME/nushell";
    };
    maturity = "young";
  };
  pwsh = {
    categories = [ "shell" ];
    posix = false;
    interactive = true;
    system = false;
    engine = [
      "dotnet"
      "csharp"
    ];
    config = {
      lang = [ "powershell" ];
      file = "profile.ps1";
      home = "$XDG_CONFIG_HOME/powershell";
    };
    maturity = "stable";
  };
  sh = {
    categories = [ "shell" ];
    posix = true;
    interactive = false;
    system = true;
    engine = [ "c" ];
    config = {
      lang = [ "sh" ];
      file = ".profile";
      home = "$HOME";
    };
    maturity = "legacy";
  };
  tcsh = {
    categories = [ "shell" ];
    posix = false;
    interactive = true;
    system = false;
    engine = [ "c" ];
    config = {
      lang = [ "csh" ];
      file = ".tcshrc";
      home = "$HOME";
    };
    maturity = "legacy";
  };
  zsh = {
    categories = [ "shell" ];
    posix = true;
    interactive = true;
    system = true;
    engine = [ "c" ];
    config = {
      lang = [ "zsh" ];
      file = ".zshrc";
      home = "$HOME";
    };
    maturity = "stable";
  };
}
