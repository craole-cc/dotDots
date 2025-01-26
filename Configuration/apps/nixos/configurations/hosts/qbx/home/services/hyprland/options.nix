# options.nix
{ lib, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types)
    bool
    str
    listOf
    attrsOf
    enum
    ;
in
{
  options.dots.services.hyprland = {
    enable = mkEnableOption "Hyprland, the dynamic tiling Wayland compositor that doesn’t sacrifice on its looks.";

    launcher = {
      modifier = mkOption {
        type = str;
        default = "SUPER";
        description = "Modifier key for the launcher (e.g., SUPER, ALT).";
      };
      primary = mkOption {
        type = attrsOf str;
        default = {
          name = "rofi";
          command = "rofi -show drun";
        };
        description = "Primary launcher configuration (name and command).";
      };
      secondary = mkOption {
        type = attrsOf str;
        default = {
          name = "fuzzel";
          command = "fuzzel";
        };
        description = "Secondary launcher configuration (name and command).";
      };
    };

    terminal = {
      primary = mkOption {
        type = str;
        default = "ghostty";
        description = "Primary terminal emulator.";
      };
      secondary = mkOption {
        type = str;
        default = "kitty";
        description = "Secondary terminal emulator.";
      };
    };

    editor = {
      primary = mkOption {
        type = str;
        default = "code";
        description = "Primary text editor.";
      };
      secondary = mkOption {
        type = str;
        default = "hx";
        description = "Secondary text editor.";
      };
    };

    browser = {
      modifier = mkOption {
        type = str;
        default = "SUPER";
        description = "Modifier key for the browser (e.g., SUPER, ALT).";
      };
      primary = mkOption {
        type = attrsOf str;
        default = {
          name = "firefox";
          command = "firefox";
        };
        description = "Primary browser configuration (name and command).";
      };
      secondary = mkOption {
        type = attrsOf str;
        default = {
          name = "brave";
          command = "brave";
        };
        description = "Secondary browser configuration (name and command).";
      };
    };

    keyboard = {
      swapCapsEscape = mkOption {
        type = bool;
        default = false;
        description = "Whether to swap Caps Lock and Escape keys.";
      };
    };

    workspaces = mkOption {
      type = listOf str;
      default = [
        "grave"
        "0"
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
        "F1"
        "F2"
        "F3"
        "F4"
        "F5"
        "F6"
        "F7"
        "F8"
        "F9"
        "F10"
        "F11"
        "F12"
      ];
      description = "List of workspace names or keys.";
    };

    directions = mkOption {
      type = attrsOf str;
      default = {
        left = "l";
        right = "r";
        up = "u";
        down = "d";
        h = "l";
        l = "r";
        k = "u";
        j = "d";
      };
      description = "Mapping of keys to Hyprland directions.";
    };
  };
}
