{
  actions,
  apps,
  keyboard,
  lib,
  pkgs,
  niriPackage,
}: let
  inherit (lib.attrsets) listToAttrs mapAttrsToList;
  inherit (lib.lists) elemAt toList;
  inherit (lib.strings) escapeRegex escapeShellArgs replaceStrings;
  inherit (lib) filterAttrs;

  packageGroup = category:
    {
      agent = "ai-agent";
      ai = "ai-agent";
    }.${
      category
    } or category;
  primaryTerminal = apps.legacy.terminal.primary or null;
  scratchpadBindings =
    filterAttrs (
      group: bindings:
        (lib.lists.any (binding: (binding.kind or "exec") == "scratchpad") (toList bindings))
        || (group
          == "ghosttyQuickTerminal"
          && lib.lists.any (binding: (binding.kind or "exec") == "global") (toList bindings))
    )
    keyboard.bindings;

  escapeShell = value: escapeShellArgs [value];
  mkWorkspace = category: application: "dotdots-${category}-${toString application}";
  mkChord = binding: let
    modifiers =
      map
      (modifier:
        replaceStrings
        ["SUPER" "SHIFT" "CTRL" "CONTROL" "ALT"]
        ["Mod" "Shift" "Ctrl" "Ctrl" "Alt"]
        modifier)
      (lib.strings.splitString " " (binding.mod or ""));
    key =
      {
        RETURN = "Return";
        SPACE = "Space";
        SUPER_L = "Super_L";
        ALT_L = "Alt_L";
        ALT_R = "Alt_R";
        TAB = "Tab";
        PRINT = "Print";
        grave = "Grave";
        PAGE_DOWN = "Page_Down";
        PAGE_UP = "Page_Up";
      }.${
        binding.key
      } or binding.key;
  in
    lib.strings.concatStringsSep "+" (lib.lists.filter (part: part != "") (modifiers ++ [key]));

  mkRecord = group: binding: let
    category =
      if group == "ghosttyQuickTerminal"
      then "terminal"
      else group;
    application =
      if group == "ghosttyQuickTerminal"
      then 1
      else (binding.application or 1);
    entries = apps.${packageGroup category} or [];
    entry =
      if application > 0 && application <= builtins.length entries
      then elemAt entries (application - 1)
      else null;
    appId =
      if entry == null
      then null
      else (entry.class or null);
    launch =
      if (binding.command or null) != null
      then binding.command
      else if entry == null
      then null
      else if entry.needsTerminal or false
      then
        if primaryTerminal == null
        then null
        else "${primaryTerminal.command} ${primaryTerminal.wrap.execFlag or "-e"} ${entry.launch.scratchpad or entry.command}"
      else entry.launch.scratchpad or entry.command;
    workspace = mkWorkspace category application;
    script = pkgs.writeShellApplication {
      name = "dotdots-niri-scratchpad-${category}-${toString application}";
      runtimeInputs = [pkgs.bash pkgs.coreutils pkgs.jq niriPackage];
      text = ''
        app_id=${escapeShell appId}
        launch=${escapeShell launch}
        windows=$(niri msg --json windows)
        window_id=$(printf '%s' "$windows" | jq -r --arg app_id "$app_id" '[.[] | select(.app_id == $app_id)][0].id // empty')

        if [ -n "$window_id" ]; then
          window_workspace_id=$(printf '%s' "$windows" | jq -r --arg app_id "$app_id" '[.[] | select(.app_id == $app_id)][0].workspace_id // empty')
          workspaces=$(niri msg --json workspaces)
          active_workspace_id=$(printf '%s' "$workspaces" | jq -r '[.[] | select(.is_active)][0].id // empty')
          if [ "$active_workspace_id" = "$window_workspace_id" ]; then
            niri msg action focus-workspace-previous
          else
            target_workspace=$(printf '%s' "$workspaces" | jq -r --argjson id "$window_workspace_id" '[.[] | select(.id == $id)][0].idx // empty')
            [ -n "$target_workspace" ] && niri msg action focus-workspace "$target_workspace"
          fi
          exit
        fi

        bash -lc "$launch" &
        attempts_remaining=50
        while [ "$attempts_remaining" -gt 0 ]; do
          windows=$(niri msg --json windows)
          window_id=$(printf '%s' "$windows" | jq -r --arg app_id "$app_id" '[.[] | select(.app_id == $app_id)][0].id // empty')
          if [ -n "$window_id" ]; then
            window_workspace_id=$(printf '%s' "$windows" | jq -r --arg app_id "$app_id" '[.[] | select(.app_id == $app_id)][0].workspace_id // empty')
            workspaces=$(niri msg --json workspaces)
            target_workspace=$(printf '%s' "$workspaces" | jq -r --argjson id "$window_workspace_id" '[.[] | select(.id == $id)][0].idx // empty')
            [ -n "$target_workspace" ] && niri msg action focus-workspace "$target_workspace"
            exit
          fi
          attempts_remaining=$((attempts_remaining - 1))
          sleep 0.1
        done
      '';
    };
  in
    if
      ! (binding.enable or true)
      || ! (
        (binding.kind or "exec")
        == "scratchpad"
        || (group == "ghosttyQuickTerminal" && (binding.kind or "exec") == "global")
      )
      || (binding.key or null) == null
      || (binding.mod or null) == null
      || entry == null
      || appId == null
      || launch == null
      || launch == ""
    then null
    else {
      group = category;
      inherit appId application binding category launch script workspace;
      bind = {
        name = mkChord binding;
        value =
          {
            action = actions.spawn-sh "${script}/bin/${script.name}";
            hotkey-overlay.title = binding.description or "Toggle ${category} ${toString application}";
            repeat = binding.repeating or false;
          }
          // (
            if binding.locked or false
            then {allow-when-locked = true;}
            else {}
          );
      };
    };

  records = lib.lists.concatMap (
    group:
      map (binding: mkRecord group binding) (toList scratchpadBindings.${group})
  ) (builtins.attrNames scratchpadBindings);
  validRecords = lib.lists.filter (record: record != null) records;
  mkWorkspaceEntry = record: {
    name = record.workspace;
    value = {};
  };
  mkWindowRule = record: {
    matches = [{app-id = "^${escapeRegex record.appId}$";}];
    open-on-workspace = record.workspace;
  };
in {
  binds = listToAttrs (map (record: record.bind) validRecords);
  workspaces = listToAttrs (map mkWorkspaceEntry validRecords);
  window-rules = map mkWindowRule validRecords;
  packages = map (record: record.script) validRecords;
}
