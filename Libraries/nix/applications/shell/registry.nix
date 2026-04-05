{...}: let
  __exports = {
    internal = registry;
    external = {
      registryOfShells = registry;
    };
  };

  registry = {
    shells = {
      #~@ POSIX-compatible
      bash = {
        posix = true;
        interactive = true;
        system = true;
        language = "c";
      };
      dash = {
        posix = true;
        interactive = false;
        system = true;
        language = "c";
      };
      sh = {
        posix = true;
        interactive = false;
        system = true;
        language = "c";
      };
      ksh = {
        posix = true;
        interactive = true;
        system = true;
        language = "c";
      };
      zsh = {
        posix = true;
        interactive = true;
        system = true;
        language = "c";
      };

      #~@ Modern
      fish = {
        posix = false;
        interactive = true;
        system = false;
        language = "c";
      };
      nushell = {
        posix = false;
        interactive = true;
        system = false;
        language = "rust";
      };
      elvish = {
        posix = false;
        interactive = true;
        system = false;
        language = "go";
      };
      pwsh = {
        posix = false;
        interactive = true;
        system = false;
        language = "csharp";
      };

      #~@ Legacy/niche
      tcsh = {
        posix = false;
        interactive = true;
        system = false;
        language = "c";
      };
    };

    lineEditors = {
      blesh = {
        language = "bash";
        config = ".blerc";
        shells = ["bash"];
        maturity = "young";
      };
      zle = {
        language = "c";
        config = null;
        shells = ["zsh"];
        maturity = "stable";
      };
      readline = {
        language = "c";
        config = ".inputrc";
        shells = ["bash" "sh" "ksh"];
        maturity = "stable";
      };
    };

    prompts = {
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
    };

    enhancements = {
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
    };
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
