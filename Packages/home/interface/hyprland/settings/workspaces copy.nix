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
    size ? "100%",
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
    exec = "[workspace special:${workspace} silent] ${cmd}";
    rules = [
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
  }: {
    inherit key;
    workspaceName = name;
    workspaceNameAlt = "${name}Alt";
    variants = [
      (mkWorkspaceVariant {
        inherit (primary) command class;
        inherit size workdir;
        workspace = name;
      })
      (mkWorkspaceVariant {
        inherit (secondary) command class;
        inherit size workdir;
        workspace = "${name}Alt";
      })
    ];
  };

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

  workspaceData = mat mkWorkspace specialWorkspaces;
  allVariants = flatten (map (w: w.variants) workspaceData);

  mkDirectionalBinds = {
    modifier ? mod,
    action,
  }:
    mat (key: dir: "${modifier},${key},${action},${dir}") directions;
in {
  bind = flatten [
    #~@ Special workspaces
    (map (w: "${mod}, ${w.key}, togglespecialworkspace, ${w.workspaceName}") workspaceData)
    (map (w: "${mod} SHIFT, ${w.key}, togglespecialworkspace, ${w.workspaceNameAlt}") workspaceData)

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

  #> Launch apps once at startup
  exec-once = map (v: v.exec) allVariants;

  #> Apply workspace rules
  windowrulev2 = cat (v: v.rules) allVariants;
}
