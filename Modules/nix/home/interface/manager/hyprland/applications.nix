{
  apps,
  lix,
  scratchpads,
}: let
  inherit (lix.attrsets.transformation) mapAttrsToList;
  inherit (lix.lists.access) elemAt length;
  inherit (lix.lists.selection) filter;
  inherit (lix.strings.construction) concatStringsSep splitString toJSON;
  inherit (lix.types.predicates) isAttrs;

  # The keyboard AI alias selects the canonical ai-agent package group.
  # Editor and IDE shortcuts use their own declared package groups.
  packageGroup = category:
    {
      ai = "ai-agent";
    }.${
      category
    } or category;
  primaryTerminal = apps.legacy.terminal.primary or null;
  wrapCommand = entry: command:
    if (entry.needsTerminal or false) && isAttrs primaryTerminal
    then "${primaryTerminal.command} ${primaryTerminal.wrap.execFlag or "-e"} ${command}"
    else command;
  workspaceName = category: application: let
    legacy = ["primary" "secondary" "tertiary"];
    suffix =
      if application <= length legacy
      then elemAt legacy (application - 1)
      else toString application;
  in "${category}-${suffix}";

  scratchpadBind = category: scratchpad: binding: let
    entries = apps.scratchpads.${packageGroup category} or [];
    inherit (binding) application;
    entry =
      if application > 0 && application <= length entries
      then elemAt entries (application - 1)
      else null;
    key =
      if (binding.key or null) != null
      then binding.key
      else scratchpad.key or null;
    mod = binding.mod or null;
    configured = binding.command or null;
    command =
      if configured != null
      then configured
      else if entry != null
      then wrapCommand entry (entry.launch.scratchpad or entry.command)
      else null;
    workspace = workspaceName category (
      if entry != null
      then entry.scratchpadSlot
      else application
    );
    description = binding.description or "Toggle ${category} ${toString application}";
    chord = concatStringsSep " + " ((filter (part: part != "") (splitString " " mod)) ++ [key]);
  in
    if key == null || mod == null || command == null || command == ""
    then ""
    else ''
      hl.workspace_rule({ workspace = ${toJSON "special:${workspace}"}, on_created_empty = ${toJSON command} })
      hl.unbind(${toJSON chord})
      hl.bind(${toJSON chord}, hl.dsp.workspace.toggle_special(${toJSON workspace}), { description = ${toJSON description} })
    '';
in
  concatStringsSep "" (mapAttrsToList (
      category: scratchpad:
        concatStringsSep "" (mapAttrsToList (_: scratchpadBind category scratchpad) (scratchpad.entries or {}))
    )
    scratchpads)
