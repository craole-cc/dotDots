# Home Manager hyprland.settings
{
  workspace = {
    "special:quake-term" = {
      gaps_out = 0;
      gaps_in = 0;
      border_size = 0;
      rounding = 0;
      animate = false;
      on-created-empty = "[float; move 0% 0%; size 100% 30%] foot";
    };
    "special:quake-dev" = {
      gaps_out = 0;
      gaps_in = 0;
      border_size = 0;
      rounding = 0;
      animate = false;
      on-created-empty = "[float; move 0% 0%; size 100% 60%] code";
    };
  };

  # Simple toggle keybinds (no launch logic)
  bind = [
    "SUPER, grave, togglespecialworkspace, quake-term"
    "SUPER SHIFT, grave, togglespecialworkspace, quake-dev"
  ];

  # Window rules (still needed for persistent styling)
  windowrulev2 = [
    "move 0% 0%, workspace:^(quake-term)$"
    "size 100% 30%, workspace:^(quake-term)$"
    "float, workspace:^(quake-term)$"
    "noborder, workspace:^(quake-term)$"

    "move 0% 0%, workspace:^(quake-dev)$"
    "size 100% 60%, workspace:^(quake-dev)$"
    "float, workspace:^(quake-dev)$"
    "noborder, workspace:^(quake-dev)$"
  ];
}
