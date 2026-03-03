{
  lib,
  keyboard,
  apps,
  ...
}: let
  inherit (lib.lists) flatten range;
  inherit (keyboard) mod;
  cat = lib.lists.concatMap;
  mat = lib.attrsets.mapAttrsToList;

  #> Split workspaces to handle numbers and F-keys properly
  numWorkspaces = map toString (range 0 9);
  fWorkspaces = map (n: "F${toString n}") (range 1 12);

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
    cmd =
      if workdir != null
      then
        if (class == "foot" || class == "feet" || class == "com.mitchellh.ghostty")
        then ''${command} --working-directory="${workdir}"''
        else ''cd ${workdir} && ${command}''
      else command;

    #? Edge needs explicit move because it ignores workspace specs
    isEdge = class == "microsoft-edge";

    moveScript = ''for i in {1..10}; do sleep 0.3; hyprctl dispatch movetoworkspacesilent 'special:${workspace},class:^(${class})$' 2>/dev/null | grep -q 'ok' && break; done'';

    #> Format modifier string to prevent syntax errors
    modString =
      if extraMod != ""
      then "${mod} ${extraMod}"
      else "${mod}";
  in {
    bind = "${modString},${key},togglespecialworkspace,${workspace}";
    exec =
      if isEdge
      then ''sh -c "${cmd} & ${moveScript}"''
      else "[workspace special:${workspace} silent] ${cmd}";
    rule = [
      "workspace special:${workspace} silent, class:^(${class})$"
      "float, class:^(${class})$"
      "noborder, class:^(${class})$"
      "size 100% ${size}, class:^(${class})$"
      "move 0% 0%, class:^(${class})$"
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
    browser = {
      inherit (browser) primary secondary;
      key = "B";
    };
    editor = {
      inherit (editor) primary secondary;
      key = "C";
    };
    explorer = {
      inherit (explorer) primary secondary;
      key = "E";
      workdir = "$HOME";
    };
    terminal = {
      inherit (terminal) primary secondary;
      key = "GRAVE";
      workdir = "$DOTS";
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

    #~@ Regular Numbered Workspaces (Maps 0 to 10, drops the "name:" prefix)
    (map (n: let
      ws =
        if n == "0"
        then "10"
        else n;
    in "${mod},${n},workspace,${ws}")
    numWorkspaces)
    (map (n: let
      ws =
        if n == "0"
        then "10"
        else n;
    in "${mod} SHIFT,${n},movetoworkspacesilent,${ws}")
    numWorkspaces)

    #~@ F-Key Workspaces (Keeps the "name:" prefix)
    (map (n: "${mod},${n},workspace,name:${n}") fWorkspaces)
    (map (n: "${mod} SHIFT,${n},movetoworkspacesilent,name:${n}") fWorkspaces)

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
