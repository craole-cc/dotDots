{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;

  default = {
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
      autoSwitch = false;
      dark = {
        flavor = null;
        accent = null;
        icons = null;
      };
      light = {
        flavor = null;
        accent = null;
        icons = null;
      };
      palettes = {};
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

  resolve = {interface ? args.interface or {}, ...} @ args:
    recursiveUpdate default interface;
in {inherit default resolve;}
