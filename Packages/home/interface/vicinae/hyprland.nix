{
  mkIf,
  config,
  ...
}: {
  wayland.windowManager.hyprland.settings =
    mkIf
    (config.wayland.windowManager.hyprland.enable or false) {
      bind = ["ALT, SPACE, exec, vicinae toggle"];
    };
}
# Usage tips:
# - Super+Space: Toggle vicinae (primary)
# - Super+R: Toggle vicinae (alternative)
# - Alt+Space: Toggle vicinae (Spotlight-style)
# - Super+A: Jump directly to applications
# - Super+Shift+V: Open clipboard history
# - Super+Shift+F: Open file search
# - Super+/: Open vicinae
# Updated vicinae/default.nix pattern with conditional import:
# imports = lib.optional cfg.enable ./hyprland.nix;
