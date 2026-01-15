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
    inherit left right up down;
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
    workdir ? null,
  }: let
    #> Build terminal command with working directory
    isFoot = class == "foot";
    isGhostty = class == "com.mitchellh.ghostty";
    cmd =
      if (isFoot || isGhostty) && workdir != null
      then ''${command} --working-directory="${workdir}"''
      else if workdir != null
      then ''cd "${workdir}" && ${command}''
      else command;
  in {
    bind = "${mod} ${extraMod}, ${key}, exec, [workspace special:${workspace} silent] ${cmd}";
    rule = [
      "workspace special:${workspace} silent, class:^(${class})$"
      "float, class:^(${class})$, workspace:special:${workspace}"
      "noborder, class:^(${class})$, workspace:special:${workspace}"
      "size 100% ${size}, class:^(${class})$, workspace:special:${workspace}"
      "move 0% 0%, class:^(${class})$, workspace:special:${workspace}"
    ];
  };

  mkWorkspace = name: {
    key,
    primary,
    secondary,
    size ? "100%",
    workdir ? null,
  }: [
    (mkWorkspaceVariant {
      inherit (primary) command class;
      inherit key size workdir;
      workspace = name;
    })
    (mkWorkspaceVariant {
      inherit (secondary) command class;
      inherit key size workdir;
      workspace = "${name}Alt";
      extraMod = "SHIFT";
    })
  ];

  specialWorkspaces = with apps; {
    terminal = {
      inherit (terminal) primary secondary;
      key = "GRAVE";
      size = "30%";
      workdir = "$DOTS";
    };
    browser = {
      inherit (browser) primary secondary;
      key = "B";
      size = "80%";
    };
    editor = {
      inherit (editor) primary secondary;
      key = "C";
      size = "70%";
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
    #~@ Special workspaces - toggle visibility
    (map (w: "${mod}, ${w.key}, togglespecialworkspace, ${w.workspace}")
      (flatten (mat (name: ws: [
          {
            inherit (ws) key;
            workspace = name;
          }
        ])
        specialWorkspaces)))
    (map (w: "${mod} SHIFT, ${w.key}, togglespecialworkspace, ${w.workspace}Alt")
      (flatten (mat (name: ws: [
          {
            inherit (ws) key;
            workspace = name;
          }
        ])
        specialWorkspaces)))

    #~@ Launch commands with workspace assignment
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

  windowrulev2 = cat (v: v.rule) allVariants;
}
