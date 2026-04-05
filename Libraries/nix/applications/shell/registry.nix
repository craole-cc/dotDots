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
        base = "c";
      };
      dash = {
        posix = true;
        interactive = false;
        system = true;
        base = "c";
      };
      sh = {
        posix = true;
        interactive = false;
        system = true;
        base = "c";
      };
      ksh = {
        posix = true;
        interactive = true;
        system = true;
        base = "c";
      };
      zsh = {
        posix = true;
        interactive = true;
        system = true;
        base = "c";
      };

      #~@ Modern
      fish = {
        posix = false;
        interactive = true;
        system = false;
        base = "c";
      };
      nushell = {
        posix = false;
        interactive = true;
        system = false;
        base = "rust";
      };
      elvish = {
        posix = false;
        interactive = true;
        system = false;
        base = "go";
      };
      pwsh = {
        posix = false;
        interactive = true;
        system = false;
        base = "dotnet";
      };

      #~@ Legacy/niche
      tcsh = {
        posix = false;
        interactive = true;
        system = false;
        base = "c";
      };
    };
    lineEditors = {
      blesh = {
        base = "shellscript";
        config = ".blerc";
        shells = ["bash"];
        maturity = "young";
      };
      zle = {
        base = "shellscript";
        config = null;
        shells = ["zsh"];
        maturity = "stable";
      };
      readline = {
        base = "c";
        config = ".inputrc";
        shells = ["bash" "sh" "ksh"];
        maturity = "stable";
      };
    };
    prompts = {
      #~@ Cross-shell (work in bash, zsh, fish, nushell, etc.)
      starship = {
        base = "rust";
        config = "starship.toml";
        shells = ["bash" "zsh" "fish" "nushell" "elvish" "pwsh" "tcsh"];
        maturity = "stable";
      };
      ohmyposh = {
        base = "go";
        config = ".omp.json";
        shells = ["bash" "zsh" "fish" "nushell" "pwsh"];
        maturity = "stable";
      };
      liquidprompt = {
        base = "shell";
        config = ".liquidpromptrc";
        shells = ["bash" "zsh"];
        maturity = "stable";
      };

      #~@ Zsh-specific
      powerlevel10k = {
        base = "shell";
        config = ".p10k.zsh";
        shells = ["zsh"];
        maturity = "stable";
      };
      spaceship = {
        base = "shell";
        config = "spaceship.zsh";
        shells = ["zsh"];
        maturity = "stable";
      };
      pure = {
        base = "shell";
        config = null;
        shells = ["zsh"];
        maturity = "stable";
      };
      prezto = {
        base = "shell";
        config = ".zpreztorc";
        shells = ["zsh"];
        maturity = "stable";
      };

      #~@ Fish-specific
      tide = {
        base = "shell";
        config = null;
        shells = ["fish"];
        maturity = "stable";
      };
      hydro = {
        base = "shell";
        config = null;
        shells = ["fish"];
        maturity = "stable";
      };

      #~@ Nushell-specific
      oh-my-nu = {
        base = "nushell";
        config = null;
        shells = ["nushell"];
        maturity = "young";
      };

      #~@ Powerline-based
      powerline = {
        base = "python";
        config = "powerline.json";
        shells = ["bash" "zsh" "fish" "pwsh"];
        maturity = "legacy";
      };
      powerline-go = {
        base = "go";
        config = null;
        shells = ["bash" "zsh" "fish" "pwsh"];
        maturity = "stable";
      };
      powerline-rs = {
        base = "rust";
        config = null;
        shells = ["bash" "zsh" "fish"];
        maturity = "niche";
      };
    };
    enhancements = {
      #~@ History
      atuin = {
        base = "rust";
        config = "atuin/config.toml";
        shells = ["bash" "zsh" "fish" "nushell"];
        maturity = "stable";
        kind = "history";
      };
      mcfly = {
        base = "rust";
        config = null;
        shells = ["bash" "zsh" "fish"];
        maturity = "stable";
        kind = "history";
      };

      #~@ Navigation
      zoxide = {
        base = "rust";
        config = null;
        shells = ["bash" "zsh" "fish" "nushell" "elvish" "pwsh"];
        maturity = "stable";
        kind = "navigation";
      };

      #~@ Fuzzy finding
      fzf = {
        base = "go";
        config = null;
        shells = ["bash" "zsh" "fish"];
        maturity = "stable";
        kind = "fuzzy";
      };
      skim = {
        base = "rust";
        config = null;
        shells = ["bash" "zsh" "fish"];
        maturity = "stable";
        kind = "fuzzy";
      };
    };
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
