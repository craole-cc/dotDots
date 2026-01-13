{lib, ...}: let
  inherit (lib.attrsets) attrValues;
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
  mkSpecialWorkspace = name: cmd: size: {
    bind = "$MOD, ${name.key}, togglespecialworkspace, ${name.primary}";
    bindShift = "$MOD SHIFT, ${name.key}, togglespecialworkspace, ${name.secondary}";
    exec = "[workspace special:${name.primary} silent] ${cmd}";
    rules = [
      "workspace special:${name.primary}, class:^(${cmd})$"
      "size 100% ${size}, workspace:^(${name.primary})$"
      "move 0% 0%, workspace:^(${name.primary})$"
      "float, workspace:^(${name.primary})$"
      "noborder, workspace:^(${name.primary})$"
    ];
  };

  specialWorkspaces = {
    terminal = {
      key = "GRAVE";
      primary = "terminal";
      secondary = "terminalAlt";
      size = "100%";
    };
    editor = {
      key = "C";
      primary = "editor";
      secondary = "editorAlt";
      size = "100%";
    };
    browser = {
      key = "B";
      primary = "browser";
      secondary = "browserAlt";
      size = "100%";
    };
  };

  #~@ Generate all special workspace configs
  specialConfigs =
    mat (
      app: config:
        mkSpecialWorkspace config "$${app}"
    )
    specialWorkspaces;
in {
  bind =
    #~@ Special workspaces
    (cat (c: [c.bind c.bindShift]) specialConfigs)
    #~@ Regular workspace switching
    ++ (map (n: "$MOD,${n},workspace,name:${n}") workspaces)
    ++ (map (n: "$MOD SHIFT,${n},movetoworkspacesilent,name:${n}") workspaces)
    #~@ Directional bindings
    ++ (mat (key: dir: "$MOD,${key},movefocus,${dir}") directions)
    ++ (mat (key: dir: "$MOD SHIFT,${key},swapwindow,${dir}") directions)
    ++ (mat (key: dir: "$MOD CONTROL,${key},movewindoworgroup,${dir}")
      directions)
    ++ (mat (key: dir: "$MOD ALT,${key},focusmonitor,${dir}") directions)
    ++ (mat (key: dir: "$MOD ALT SHIFT,${key},movecurrentworkspacetomonitor,${dir}")
      directions);

  exec-once =
    map (c: c.exec) specialConfigs
    ++ (map (c: c.exec) (map (cfg: mkSpecialWorkspace cfg "$${app}Alt")
        (attrValues specialWorkspaces)));

  windowrulev2 =
    cat (c: c.rules) specialConfigs
    ++ (cat (c: c.rules) (map (cfg: mkSpecialWorkspace cfg "$${app}Alt")
        (attrValues specialWorkspaces)));
}
