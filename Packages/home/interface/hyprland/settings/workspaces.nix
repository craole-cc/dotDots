{
  # workspace = {
  #   "special:terminal" = {
  #     gaps_out = 0;
  #     gaps_in = 0;
  #     border_size = 0;
  #     rounding = 0;
  #     animate = false;
  #   };
  #   "special:development" = {
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
    # Terminal to quake-terminal
    "workspace special:terminal, class:^(foot)$"
    "float, workspace:^(terminal)$"
    "size 100% 30%, workspace:^(terminal)$"
    "move 0% 0%, workspace:^(terminal)$"
    "noborder, workspace:^(terminal)$"

    # VSCode to quake-development
    "workspace special:development, class:^(code)$"
    "float, workspace:^(development)$"
    "size 100% 60%, workspace:^(development)$"
    "move 0% 0%, workspace:^(development)$"
    "noborder, workspace:^(development)$"
  ];
}
