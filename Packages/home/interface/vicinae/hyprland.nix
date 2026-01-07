{
  mkIf,
  config,
  ...
}: {
  wayland.windowManager.hyprland.settings =
    mkIf
    (config.wayland.windowManager.hyprland.enable or false) {
      # Primary launcher trigger - Super+Space
      bindr = [
        "SUPER, SPACE, exec, vicinae toggle"
      ];

      bind = [
        # Alternative launcher triggers
        "SUPER, R, exec, vicinae toggle" # Common launcher binding
        "ALT, SPACE, exec, vicinae toggle" # macOS-style spotlight

        # Specific vicinae commands
        "SUPER, A, exec, vicinae show applications" # Show apps directly
        "SUPER+SHIFT, V, exec, vicinae show clipboard:history" # Clipboard history
        "SUPER+SHIFT, F, exec, vicinae show files:search" # File search

        # Quick actions via vicinae
        "SUPER, slash, exec, vicinae" # Another common launcher key
      ];
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
