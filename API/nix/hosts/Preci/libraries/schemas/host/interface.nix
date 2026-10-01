{lib, ...}: let
  inherit (lib.attrsets) recursiveUpdate;

  default = {
    boot = {
      loader = {
        manager = "systemd-boot";
        device = "nodev";
        timeout = 5;
      };
    };
    desktops = [];
    fonts = {
      clock = [];
      emoji = [];
      material = [];
      monospace = [];
      sans = [];
      serif = [];
    };
    themes = {
      polarity = "dark";
    };
    cursors = {
      accent = null;
      dark = null;
      light = null;
    };
    keyboard = {
      layout = null;
      variant = "";
      swapCapsEscape = false;
      vimKeybinds = false;
      bindings.modifier = ["SUPER"];
    };
  };

  resolve = {args ? {}}:
    recursiveUpdate default (args.interface or {});
in {inherit default resolve;}
