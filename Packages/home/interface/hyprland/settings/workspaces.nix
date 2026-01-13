{
  lib,
  cmd,
  mod,
  ...
}: let
  inherit (lib.lists) concatMap flatten range;
  inherit (lib.attrsets) mapAttrsToList;

  workspaces =
    map toString (range 0 9)
    ++ map (n: "F${toString n}") (range 1 12);

  directions = let
    left = "l";
    right = "r";
    up = "u";
    down = "d";
  in {
    inherit left right up down;
    h = left;
    l = right;
    k = up;
    j = down;
  };

  mkWorkspaceVariant = {
    command,
    workspace,
    key,
    size,
    extraMod ? "",
  }: {
    bind = "${mod} ${extraMod}, ${key}, togglespecialworkspace, ${workspace}";
    exec = "[workspace special:${workspace} silent] ${command}";
    rules = [
      "workspace special:${workspace}, class:^(${command})$"
      "size 100% ${size}, workspace:^(${workspace})$"
      "move 0% 0%, workspace:^(${workspace})$"
      "float, workspace:^(${workspace})$"
      "noborder, workspace:^(${workspace})$"
    ];
  };

  mkWorkspace = name: {
    key,
    primary,
    secondary,
    size,
  }: [
    (mkWorkspaceVariant {
      inherit key size;
      workspace = name;
      command = primary;
    })
    (mkWorkspaceVariant {
      inherit key size;
      workspace = "${name}Alt";
      command = secondary;
      extraMod = "SHIFT";
    })
  ];

  specialWorkspaces = {
    terminal = {
      key = "GRAVE";
      primary = cmd.terminal.primary;
      secondary = cmd.terminal.secondary;
      size = "30%";
    };
    editor = {
      key = "C";
      primary = cmd.editor.primary;
      secondary = cmd.editor.secondary;
      size = "70%";
    };
    browser = {
      key = "B";
      primary = cmd.browser.primary;
      secondary = cmd.browser.secondary;
      size = "80%";
    };
  };

  allVariants = flatten (mapAttrsToList mkWorkspace specialWorkspaces);
  mkDirectionalBinds = modifier: action:
    mapAttrsToList (key: dir: "${modifier},${key},${action},${dir}") directions;
in {
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
  exec-once = map (v: v.exec) allVariants;
  windowrulev2 = concatMap (v: v.rules) allVariants;
}
