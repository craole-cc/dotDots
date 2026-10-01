{lib, ...}: let
  inherit (lib.attrsets) recursiveUpdate;

  default = {
    agent = [];
    bar = [];
    browser = ["brave"];
    common = [];
    editor = ["helix"]; # TTY editor
    explorer = [];
    extra = [];
    ide = ["vscode-fhs"]; # GUI
    launcher = ["vicinae"];
    prompt = ["starship"];
    shell = ["bash"];
    terminal = ["ghostty "];
  };

  resolve = {args ? {}}:
    recursiveUpdate default (args.packages or {});
in {inherit default resolve;}
