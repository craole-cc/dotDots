{apps, ...}: let
  browser = apps.browser.primary.command;
  browserAlt = apps.browser.secondary.command;
  editor = apps.editor.primary.command;
  editorAlt = apps.editor.secondary.command;
  terminal = apps.terminal.primary.command;
  terminalAlt = apps.terminal.secondary.command;
in {
  bind = [
    "$MOD CTRL, grave, togglespecialworkspace, terminal"
    "$MOD CTRL SHIFT, grave, togglespecialworkspace, terminalAlt"
    "$MOD CTRL, C, togglespecialworkspace, editor"
    "$MOD CTRL SHIFT, C, togglespecialworkspace, editorAlt"
    "$MOD CTRL, B, togglespecialworkspace, browser"
    "$MOD CTRL SHIFT, B, togglespecialworkspace, browserAlt"
  ];

  exec-once = [
    "[workspace special:terminal silent] ${terminal}"
    "[workspace special:terminalAlt silent] ${terminalAlt}"
    "[workspace special:editor silent] ${editor}"
    "[workspace special:editorAlt silent] ${editorAlt}"
    "[workspace special:browser silent] ${browser}"
    "[workspace special:browserAlt silent] ${browserAlt}"
  ];

  windowrulev2 = [
    #~@ Terminal
    "workspace special:terminal, class:^(${terminal})$"
    "size 100% 30%, workspace:^(terminal)$"
    "move 0% 0%, workspace:^(terminal)$"
    "float, workspace:^(terminal)$"
    "noborder, workspace:^(terminal)$"
    "workspace special:terminalAlt, class:^(${terminalAlt})$"
    "size 100% 30%, workspace:^(terminalAlt)$"
    "move 0% 0%, workspace:^(terminalAlt)$"
    "float, workspace:^(terminalAlt)$"
    "noborder, workspace:^(terminalAlt)$"

    #~@ Editor
    "workspace special:editor, class:^(${editor})$"
    "size 100% 70%, workspace:^(editor)$"
    "move 0% 0%, workspace:^(editor)$"
    "float, workspace:^(editor)$"
    "noborder, workspace:^(editor)$"
    "workspace special:editorAlt, class:^(${editorAlt})$"
    "size 100% 70%, workspace:^(editorAlt)$"
    "move 0% 0%, workspace:^(editorAlt)$"
    "float, workspace:^(editorAlt)$"
    "noborder, workspace:^(editorAlt)$"

    #~@ Browser
    "workspace special:browser, class:^(${browser})$"
    "size 100% 80%, workspace:^(browser)$"
    "move 0% 0%, workspace:^(browser)$"
    "float, workspace:^(browser)$"
    "noborder, workspace:^(browser)$"
    "workspace special:browserAlt, class:^(${browserAlt})$"
    "size 100% 80%, workspace:^(browserAlt)$"
    "move 0% 0%, workspace:^(browserAlt)$"
    "float, workspace:^(browserAlt)$"
    "noborder, workspace:^(browserAlt)$"
  ];
}
