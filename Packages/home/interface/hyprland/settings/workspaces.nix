let
  browser = "zen-twilight";
  editor = "code";
  terminal = "foot";
in {
  bind = [
    "SUPER, grave, togglespecialworkspace, terminal"
    "SUPER SHIFT, grave, togglespecialworkspace, editor"
    "SUPER CTRL, GRAVE, togglespecialworkspace, browser"
  ];

  exec-once = [
    "[workspace special:terminal silent] ${terminal}"
    "[workspace special:editor silent] ${editor}"
    "[workspace special:browser silent] ${browser}"
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
    "size 100% 70%, workspace:^(editor)$"
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
