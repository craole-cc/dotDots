{lib, ...}: let
  cat = lib.lists.concatMap;
  mat = lib.attrsets.mapAttrsToList;

  workspaces = [
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

  directions = rec {
    left = "l";
    right = "r";
    up = "u";
    down = "d";
    h = left;
    l = right;
    k = up;
    j = down;
  };

  # Helper to create special workspace configs
  mkSpecialWorkspace = app: config: {
    primary = {
      bind = "$MOD, ${config.key}, togglespecialworkspace, ${config.primary}";
      exec = "[workspace special:${config.primary} silent] $${app}";
      rules = [
        "workspace special:${config.primary}, class:^($${app})$"
        "size 100% ${config.size}, workspace:^(${config.primary})$"
        "move 0% 0%, workspace:^(${config.primary})$"
        "float, workspace:^(${config.primary})$"
        "noborder, workspace:^(${config.primary})$"
      ];
    };
    secondary = {
      bind = "$MOD SHIFT, ${config.key}, togglespecialworkspace, ${config.secondary}";
      exec = "[workspace special:${config.secondary} silent] $${app}Alt";
      rules = [
        "workspace special:${config.secondary}, class:^($${app}Alt)$"
        "size 100% ${config.size}, workspace:^(${config.secondary})$"
        "move 0% 0%, workspace:^(${config.secondary})$"
        "float, workspace:^(${config.secondary})$"
        "noborder, workspace:^(${config.secondary})$"
      ];
    };
  };

  specialWorkspaces = {
    terminal = {
      key = "GRAVE";
      primary = "terminal";
      secondary = "terminalAlt";
      size = "30%";
    };
    editor = {
      key = "C";
      primary = "editor";
      secondary = "editorAlt";
      size = "70%";
    };
    browser = {
      key = "B";
      primary = "browser";
      secondary = "browserAlt";
      size = "80%";
    };
  };

  #~@ Generate all special workspace configs
  specialConfigs = mat mkSpecialWorkspace specialWorkspaces;
in {
  bind =
    #~@ Special workspaces
    (cat (c: [c.primary.bind c.secondary.bind]) specialConfigs)
    #~@ Regular workspace switching
    ++ (map (n: "$MOD,${n},workspace,name:${n}") workspaces)
    ++ (map (n: "$MOD SHIFT,${n},movetoworkspacesilent,name:${n}") workspaces)
    #~@ Directional bindings
    ++ (mat (key: dir: "$MOD,${key},movefocus,${dir}") directions)
    ++ (mat (key: dir: "$MOD SHIFT,${key},swapwindow,${dir}") directions)
    ++ (mat (key: dir: "$MOD CONTROL,${key},movewindoworgroup,${dir}") directions)
    ++ (mat (key: dir: "$MOD ALT,${key},focusmonitor,${dir}") directions)
    ++ (mat (key: dir: "$MOD ALT SHIFT,${key},movecurrentworkspacetomonitor,${dir}") directions);

  exec-once =
    (map (c: c.primary.exec) specialConfigs)
    ++ (map (c: c.secondary.exec) specialConfigs);

  windowrulev2 =
    (cat (c: c.primary.rules) specialConfigs)
    ++ (cat (c: c.secondary.rules) specialConfigs);
}
