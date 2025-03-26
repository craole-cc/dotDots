{
  lib,
  pkgs,
  config,
  ...
}:
let
  mod = "wayland";
  # cfg = config.DOTS.${mod};

  inherit (lib.lists) elem;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) listOf package oneOf;
  inherit (config.DOTS.interface) manager;
in
{
  options.DOTS.${mod} = {
    enable = mkEnableOption mod // {
      default = elem manager [
        "hyprland"
        "sway"
        "river"
      ];
    };
    packages = {
      tui = mkOption {
        description = "List or terminal-specific packages";
        default = with pkgs; [
          wl-clipboard-rs
        ];
        type = listOf package;
      };
      gui = mkOption {
        description = "List or gui-specific packages";
        default = with pkgs; [
          #| Notification
          mako
          fuzzel
          foot
          grim
          slurp
        ];
        type = listOf package;
      };
    };
    manager = mkOption {
      description = "Desktop/Window Manager";
      default = "hyprland";
      type = oneOf [
        "hyprland"
        "sway"
        "river"
      ];
    };
  };
}
