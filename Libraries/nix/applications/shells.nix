{
  _,
  lib,
  ...
}: let
  inherit (_.lists.access) length;
  inherit (_.lists.construction) mkEnum;
  inherit (_.trivial.tests) mkTest runTests;
  inherit (lib.attrsets) filterAttrs;

  __exports = {
    internal = {
      inherit registry enums;
      inherit (registry) lineEditors shells prompts;
      inherit
        (registry.shells)
        elvish
        nushell
        pwsh
        tcsh
        bash
        dash
        zsh
        ksh
        sh
        fish
        ;
      inherit (registry.lineEditors) blesh zle readline;
      inherit
        (registry.prompts)
        starship
        ohmyposh
        liquidprompt
        powerlevel10k
        spaceship
        pure
        prezto
        tide
        hydro
        powerline
        powerline-go
        ;
    };
    external = {};
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
        base = "shell";
        config = ".blerc";
        shells = ["bash"];
        maturity = "young";
      };
      zle = {
        base = "shell";
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

  enums = {
    shells = mkEnum {
      values = registry.shells;
      nullable = true;
    };
    interactive = mkEnum {
      values = filterAttrs (_: s: s.interactive) registry.shells;
      nullable = true;
    };
    system = mkEnum {
      values = filterAttrs (_: s: s.system) registry.shells;
      nullable = true;
    };
    lineEditors = mkEnum {
      values = registry.lineEditors;
      nullable = true;
    };
    prompts = mkEnum {
      values = registry.prompts;
      nullable = true;
    };
    promptsMultiShell = mkEnum {
      values = filterAttrs (_: p: length p.shells > 1) registry.prompts;
      nullable = true;
    };
    enhancements = mkEnum {
      values = registry.enhancements;
      nullable = true;
    };
    enhancementsByKind = kind:
      mkEnum {
        values = filterAttrs (_: e: e.kind == kind) registry.enhancements;
        nullable = true;
      };
  };
in
  __exports.internal
  // {
    _rootAliases = __exports.external;

    _tests = runTests {
      validatesBash = mkTest true (enums.shells.validator.check "bash");
      validatesZsh = mkTest true (enums.shells.validator.check "zsh");
      validatesFish = mkTest true (enums.shells.validator.check "fish");
      caseInsensitive = mkTest true (enums.shells.validator.check "NUSHELL");

      systemExcludesFish = mkTest false (enums.system.validator.check "fish");
      systemExcludesPwsh = mkTest false (enums.system.validator.check "pwsh");
      systemIncludesBash = mkTest true (enums.system.validator.check "bash");
      systemIncludesZsh = mkTest true (enums.system.validator.check "zsh");

      interactiveExcludesDash = mkTest false (enums.interactive.validator.check "dash");
      interactiveExcludesSh = mkTest false (enums.interactive.validator.check "sh");
      interactiveIncludesFish = mkTest true (enums.interactive.validator.check "fish");
      interactiveIncludesBash = mkTest true (enums.interactive.validator.check "bash");

      lineEditorValidatesBlesh = mkTest true (enums.lineEditors.validator.check "blesh");
      lineEditorValidatesReadline = mkTest true (enums.lineEditors.validator.check "readline");
      lineEditorRejectsPrompt = mkTest false (enums.lineEditors.validator.check "starship");

      promptValidatesStarship = mkTest true (enums.prompts.validator.check "starship");
      promptValidatesOhmyposh = mkTest true (enums.prompts.validator.check "ohmyposh");
      promptRejectsUnknown = mkTest false (enums.prompts.validator.check "bash");
      promptMultiShellExcludesTide = mkTest false (enums.promptsMultiShell.validator.check "tide");
      promptMultiShellIncludesStarship = mkTest true (enums.promptsMultiShell.validator.check "starship");
    };
  }
