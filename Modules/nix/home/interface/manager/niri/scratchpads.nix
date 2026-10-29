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
  inherit (lib.strings) escapeShellArgs replaceStrings;
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
        || group == "browserSend"
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
      if group == "browserSend"
      then "browser"
      else if group == "ghosttyQuickTerminal"
      then "terminal"
      else group;
    application =
      if group == "ghosttyQuickTerminal"
      then 1
      else (binding.application or 1);
    entries = apps.scratchpads.${packageGroup category} or [];
    entry =
      if application > 0 && application <= builtins.length entries
      then elemAt entries (application - 1)
      else null;
    appId =
      if entry == null
      then null
      else if (entry.needsTerminal or false) && primaryTerminal != null
      then primaryTerminal.class or null
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
    workspace = mkWorkspace category (
      if entry != null
      then entry.scratchpadSlot
      else application
    );
    script = pkgs.writeShellApplication {
      name = "dotdots-niri-scratchpad-${category}-${toString application}";
      runtimeInputs = [pkgs.bash pkgs.coreutils pkgs.jq pkgs.util-linux niriPackage];
      text = ''
        app_id=${escapeShell appId}
        launch=${escapeShell launch}
        workspace=${escapeShell workspace}
        session=''${NIRI_SOCKET:?NIRI_SOCKET is required}
        state_dir="''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is required}/dotdots-niri-scratchpads/''${session##*/}"
        mkdir -p "$state_dir"
        state_file="$state_dir/$workspace.window"
        exec 9>"$state_file.lock"
        flock -n 9 || exit 0
        remember_window() {
          for saved in "$state_dir"/*.window; do
            [ -f "$saved" ] || continue
            if [ "$saved" != "$state_file" ] && [ "$(cat "$saved")" = "$window_id" ]; then
              rm -f -- "$saved"
            fi
          done
          printf '%s\n' "$window_id" > "$state_file"
        }
        windows=$(niri msg --json windows)
        if [ "''${1:-}" = "--send" ]; then
          window_id=$(printf '%s' "$windows" | jq -r '[.[] | select(.is_focused)][0].id // empty')
          [ -n "$window_id" ] || exit 0
          remember_window
          niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$workspace"
          exit 0
        fi
        workspaces=$(niri msg --json workspaces)
        target_workspace_id=$(printf '%s' "$workspaces" | jq -r --arg name "$workspace" '[.[] | select(.name == $name)][0].id // empty')
        window_id=$(printf '%s' "$windows" | jq -r --arg workspace_id "$target_workspace_id" '[.[] | select((.workspace_id | tostring) == $workspace_id)][0].id // empty')

        if [ -n "$window_id" ]; then
          remember_window
          active_workspace_id=$(printf '%s' "$workspaces" | jq -r '[.[] | select(.is_active)][0].id // empty')
          if [ "$active_workspace_id" = "$target_workspace_id" ]; then
            niri msg action focus-workspace-previous
          else
            niri msg action focus-workspace "$workspace"
            niri msg action focus-window --id "$window_id"
          fi
          exit 0
        fi

        if [ -f "$state_file" ]; then
          owned_id=$(cat "$state_file")
          window_id=$(printf '%s' "$windows" | jq -r --arg id "$owned_id" '[.[] | select((.id | tostring) == $id)][0].id // empty')
          if [ -n "$window_id" ]; then
            niri msg action move-window-to-workspace --window-id "$window_id" "$workspace"
            niri msg action focus-workspace "$workspace"
            niri msg action focus-window --id "$window_id"
            exit 0
          fi
          rm -f -- "$state_file"
        fi

        # Serialise launches so normal/private windows with one app ID cannot
        # be claimed by two scratchpads at once.
        exec 8>"$state_dir/launch.lock"
        flock -w 15 8 || exit 1
        windows=$(niri msg --json windows)
        previous_ids=$(printf '%s' "$windows" | jq '[.[].id]')
        bash -lc "$launch" 8>&- 9>&- &
        attempts_remaining=50
        while [ "$attempts_remaining" -gt 0 ]; do
          windows=$(niri msg --json windows)
          window_id=$(printf '%s' "$windows" | jq -r --arg app_id "$app_id" --argjson previous "$previous_ids" '[.[] | select(.app_id == $app_id) | select(.id as $id | $previous | index($id) == null)][0].id // empty')
          if [ -n "$window_id" ]; then
            remember_window
            niri msg action move-window-to-workspace --window-id "$window_id" "$workspace"
            niri msg action focus-workspace "$workspace"
            niri msg action focus-window --id "$window_id"
            exit 0
          fi
          attempts_remaining=$((attempts_remaining - 1))
          sleep 0.1
        done
        printf 'Scratchpad: no new window appeared for %s (%s)\n' "$workspace" "$app_id" >&2
        exit 1
      '';
    };
  in
    if
      ! (binding.enable or true)
      || ! (
        (binding.kind or "exec")
        == "scratchpad"
        || group == "browserSend"
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
            action = actions.spawn-sh ("${script}/bin/${script.name}"
              + (
                if group == "browserSend"
                then " --send"
                else ""
              ));
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
in {
  binds = listToAttrs (map (record: record.bind) validRecords);
  workspaces = listToAttrs (map mkWorkspaceEntry validRecords);
  # Placement belongs to the launch script; one app can occupy several slots.
  window-rules = [];
  packages = map (record: record.script) validRecords;
}
