{lib, ...}: let
  inherit (lib.lists) concatMap flatten;
  inherit (lib.attrsets) mapAttrsToList;

  workspaces = map toString (lib.range 0 9) ++ map (n: "F${toString n}") (lib.range 1 12);

  directions = {
    left = "l";
    right = "r";
    up = "u";
    down = "d";
    h = "l";
    l = "r";
    k = "u";
    j = "d";
  };

  mkWorkspaceVariant = app: workspace: key: size: modifier: {
    bind = "$MOD ${modifier}, ${key}, togglespecialworkspace, ${workspace}";
    exec = "[workspace special:${workspace} silent] $${app}";
    rules = [
      "workspace special:${workspace}, class:^($${app})$"
      "size 100% ${size}, workspace:^(${workspace})$"
      "move 0% 0%, workspace:^(${workspace})$"
      "float, workspace:^(${workspace})$"
      "noborder, workspace:^(${workspace})$"
    ];
  };

  mkSpecialWorkspace = app: {
    key,
    primary,
    secondary,
    size,
  }: [
    (mkWorkspaceVariant app primary key size "")
    (mkWorkspaceVariant "${app}Alt" secondary key size "SHIFT")
  ];

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

  allVariants = flatten (mapAttrsToList mkSpecialWorkspace specialWorkspaces);
  mkDirectionalBinds = modifier: action:
    mapAttrsToList (key: dir: "${modifier},${key},${action},${dir}") directions;
in {
  exec-once = map (v: v.exec) allVariants;
  windowrulev2 = concatMap (v: v.rules) allVariants;
  bind = flatten [
    #~@ Special workspaces
    (map (v: v.bind) allVariants)

    #~@ Regular workspaces
    (map (n: "$MOD,${n},workspace,name:${n}") workspaces)
    (map (n: "$MOD SHIFT,${n},movetoworkspacesilent,name:${n}") workspaces)

    #~@ Directional bindings
    (mkDirectionalBinds "$MOD" "movefocus")
    (mkDirectionalBinds "$MOD SHIFT" "swapwindow")
    (mkDirectionalBinds "$MOD CONTROL" "movewindoworgroup")
    (mkDirectionalBinds "$MOD ALT" "focusmonitor")
    (mkDirectionalBinds "$MOD ALT SHIFT" "movecurrentworkspacetomonitor")
  ];
}
