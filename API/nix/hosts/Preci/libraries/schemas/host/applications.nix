{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;

  default = {
    ai = [];
    browser = [];
    editor = {
      tty = [];
      gui = [];
    };
    terminal = [];
    explorer = [];
    launcher = [];
    bar = [];
    prompt = [];
    extra = [];
    utilities = {
      atuin.enable = false;
      bat.enable = false;
      btop.enable = false;
      clock.enable = false;
      direnv.enable = false;
      git.enable = false;
      gitui.enable = false;
      github.enable = false;
      grep.enable = false;
      home-manager.enable = false;
      jujutsu.enable = false;
      nh.enable = false;
      nix-index.enable = false;
      topgrade.enable = false;
      tmux.enable = false;
      yazi.enable = false;
      delta.enable = false;
    };
  };

  resolve = args:
    recursiveUpdate default (args.applications or {});
in {inherit default resolve;}
