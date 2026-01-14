{args, ...}: let
  inherit (args) lib mod apps;
  inherit (lib.lists) flatten range;
  cat = lib.lists.concatMap;
  mat = lib.attrsets.mapAttrsToList;

  workspaces = map toString (range 0 9) ++ map (n: "F${toString n}") (range 1 12);

  directions = let
    left = "l";
    right = "r";
    up = "u";
    down = "d";
  in {
    inherit
      left
      right
      up
      down
      ;
    h = left;
    l = right;
    k = up;
    j = down;
  };

  mkWorkspaceVariant = {
    command,
    class,
    workspace,
    key,
    size ? "100%",
    extraMod ? "",
  }: let
    # Edge ignores workspace specs, so we launch it then move it
    isEdge = class == "microsoft-edge";
    execCommand =
      if isEdge
      then ''${command} & sleep 1.5 && hyprctl dispatch movetoworkspacesilent "special:${workspace},class:^(${class})$"''
      else "[workspace special:${workspace} silent] ${command}";
  in {
    bind = "${mod} ${extraMod}, ${key}, togglespecialworkspace, ${workspace}";
    exec = execCommand;
    rule = [
      "workspace special:${workspace} silent, class:^(${class})$"
      "float, class:^(${class})$"
      "noborder, class:^(${class})$"
      "size 100% ${size}, class:^(${class})$"
      "move 0% 0%, class:^(${class})$"
      "workspace special:${workspace}, initialClass:^(${class})$"
    ];
  };

  mkWorkspace = name: {
    key,
    primary,
    secondary,
    size ? "100%",
  }: [
    (mkWorkspaceVariant {
      inherit (primary) command class;
      inherit key size;
      workspace = name;
    })
    (mkWorkspaceVariant {
      inherit (secondary) command class;
      inherit key size;
      workspace = "${name}Alt";
      extraMod = "SHIFT";
    })
  ];

  specialWorkspaces = with apps; {
    browser = {
      inherit (browser) primary secondary;
      key = "B";
    };
    editor = {
      inherit (editor) primary secondary;
      key = "C";
    };
    terminal = {
      inherit (terminal) primary secondary;
      key = "GRAVE";
    };
  };

  allVariants = flatten (mat mkWorkspace specialWorkspaces);
  mkDirectionalBinds = {
    modifier ? mod,
    action,
  }:
    mat (key: dir: "${modifier},${key},${action},${dir}") directions;
in {
  bind = flatten [
    #~@ Special workspaces
    (map (v: v.bind) allVariants)

    #~@ Regular workspaces
    (map (n: "${mod},${n},workspace,name:${n}") workspaces)
    (map (n: "${mod} SHIFT,${n},movetoworkspacesilent,name:${n}") workspaces)

    #~@ Directional bindings
    (mkDirectionalBinds {action = "movefocus";})
    (mkDirectionalBinds {
      modifier = "${mod} SHIFT";
      action = "swapwindow";
    })
    (mkDirectionalBinds {
      modifier = "${mod} CTRL";
      action = "movewindoworgroup";
    })
    (mkDirectionalBinds {
      modifier = "${mod} ALT";
      action = "focusmonitor";
    })
    (mkDirectionalBinds {
      modifier = "${mod} ALT SHIFT";
      action = "movecurrentworkspacetomonitor";
    })
  ];
  exec-once = map (v: v.exec) allVariants;
  windowrulev2 = cat (v: v.rule) allVariants;
}
