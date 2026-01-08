let
  browser = "zen-twilight";
  editor = "code";
  terminal = "footclient";
in {
  workspace = {
    "special:terminal".gaps_out = 0;
    "special:terminal".gaps_in = 0;
    "special:terminal".border_size = 0;
    "special:terminal".rounding = 0;
    "special:terminal".animate = false;

    "special:editor".gaps_out = 0;
    "special:editor".gaps_in = 0;
    "special:editor".border_size = 0;
    "special:editor".rounding = 0;
    "special:editor".animate = false;

    # Browser quake
    "special:browser".gaps_out = 0;
    "special:browser".gaps_in = 0;
    "special:browser".border_size = 0;
    "special:browser".rounding = 0;
    "special:browser".animate = false;
  };

  bind = [
    "SUPER, grave, togglespecialworkspace, terminal"
    "SUPER SHIFT, grave, togglespecialworkspace, editor"
    "SUPER CTRL, GRAVE, togglespecialworkspace, browser"
  ];

  windowrulev2 = [
    #~@ Terminal
    "workspace special:terminal, class:^(${terminal})$"
    "size 100% 30%, workspace:^(terminal)$"
    "move 0% 0%, workspace:^(terminal)$"
    "float, workspace:^(terminal)$"
    "noborder, workspace:^(terminal)$"

    #~@ Editor
    "workspace special:editor, class:^(${editor})$"
    "size 100% 70%, workspace:^(editor)$" # Taller for editor
    "move 0% 0%, workspace:^(editor)$"
    "float, workspace:^(editor)$"
    "noborder, workspace:^(editor)$"

    #~@ Browser
    "workspace special:browser, class:^(${browser})$"
    "size 100% 80%, workspace:^(browser)$"
    "move 0% 0%, workspace:^(browser)$"
    "float, workspace:^(browser)$"
    "noborder, workspace:^(browser)$"
  ];
}
