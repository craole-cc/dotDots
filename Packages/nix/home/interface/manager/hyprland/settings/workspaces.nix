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
    #> Force class to 'feet' if it says 'foot' so the window rules match your actual terminal
    actualClass =
      if class == "foot"
      then "feet"
      else class;

    #> Wrap TUI apps like yazi inside the primary terminal so they don't crash in the background
    actualCommand =
      if actualClass == "yazi"
      then "${apps.terminal.primary.command} ${command}"
      else command;

    cmd =
      if workdir != null
      then
        if (actualClass == "feet" || actualClass == "com.mitchellh.ghostty")
        then ''${actualCommand} --working-directory="${workdir}"''
        else ''cd ${workdir} && ${actualCommand}''
      else actualCommand;

    #? Edge needs explicit move because it ignores workspace specs
    isEdge = actualClass == "microsoft-edge";

    #? Single-line move script
    moveScript = ''for i in {1..10}; do sleep 0.3; hyprctl dispatch movetoworkspacesilent 'special:${workspace},class:^(${actualClass})$' 2>/dev/null | grep -q 'ok' && break; done'';

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
      "match:class ^(${actualClass})$, workspace special:${workspace} silent"
      "match:class ^(${actualClass})$, float 1"
      "match:class ^(${class})$, border_size 0"
      "match:class ^(${actualClass})$, size 100% ${size}"
      "match:class ^(${actualClass})$, move 0% 0%"
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

    #~@ Regular Numbered Workspaces
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

    #~@ F-Key Workspaces
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
  windowrule = cat (v: v.rule) allVariants;
}
