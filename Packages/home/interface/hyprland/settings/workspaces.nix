{
  # workspace = {
  #   "special:quake-term" = {
  #     gaps_out = 0;
  #     gaps_in = 0;
  #     border_size = 0;
  #     rounding = 0;
  #     animate = false;
  #   };
  #   "special:quake-dev" = {
  #     gaps_out = 0;
  #     gaps_in = 0;
  #     border_size = 0;
  #     rounding = 0;
  #     animate = false;
  #   };
  # };

  bind = [
    "SUPER, grave, togglespecialworkspace, terminal"
    "SUPER SHIFT, grave, togglespecialworkspace, development"
  ];

  windowrulev2 = [
    "float, workspace:^(quake-term)$"
    "size 100% 30%, workspace:^(quake-term)$"
    "move 0% 0%, workspace:^(quake-term)$"
    "noborder, workspace:^(quake-term)$"
    "float, workspace:^(quake-dev)$"
    "size 100% 60%, workspace:^(quake-dev)$"
    "move 0% 0%, workspace:^(quake-dev)$"
    "noborder, workspace:^(quake-dev)$"
  ];
}
