{
  cfg,
  lix,
  pkgs,
  inputs ? {},
  resolve,
  ...
}: let
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.transformation) concatMapAttrs;
  inherit (lix.filesystem.access) readDir;
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.lists.transformation) filter;
  inherit (lix.modules.construction) mkIf mkLayer mkMerge mkOverride;
  inherit (lix.options.construction) mkFalse mkOption;
  inherit (lix.strings.construction) concatStringsSep;
  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) str;

  shared = import ../../../shared {inherit lix pkgs inputs;};
  resolved = resolve {};
  files = prefix: directory:
    concatMapAttrs (name: kind:
      if kind == "directory"
      then files "${prefix}/${name}" (directory + "/${name}")
      else {"${prefix}/${name}" = directory + "/${name}";})
    (readDir directory);
  custom = concatMapAttrs (name: text: {"skills/${name}/SKILL.md" = text;}) shared.skills.custom;
  curated =
    concatMapAttrs (name: directory: files "skills/${name}" directory)
    (genAttrs cfg.shared.skills.curated shared.skills.curated.target);
  allowed = filter (rule: rule.decision == "allow") shared.rules;
  command = rule: concatStringsSep " " rule.pattern;
  instructions = ''
    # Shared command policy

    These rules express command approval policy, not permission to start work
    or publish changes without the user's task authorization. Follow applicable
    repository instructions and relevant skills before acting.

    ${concatStringsSep "\n" (map (rule:
      if rule.decision == "prompt"
      then "- Ask for approval before running `${command rule}` or that command with additional arguments."
      else "- `${command rule}` and that command with additional arguments need no command approval prompt.")
    shared.rules)}

    Hermes's command allowlist enforces the allow entries. Prompt entries here
    are instructions; Codex's prefix-rule prompt mechanism is not available in
    Hermes. Keep Hermes's native approval checks enabled.

    Use the relevant installed skills. For repository changes read plan-first;
    for Nix edits read nix-style; for commits read commit-messages. Apply
    writing-style to prose and sh-utils to shell inspection. Use nix-inspect
    for configuration evaluation.
  '';
in {
  options.shared = {
    skills = {
      enable = mkFalse "Install the shared custom and selected curated skills for Hermes.";
      curated = mkOption {
        type = listOf str;
        default = shared.skills.curated.default;
        description = "Skills selected from the shared pinned curated source.";
      };
    };
    rules.enable = mkFalse "Apply shared command policy using Hermes's allowlist and AGENTS.md instructions.";
  };
  resolutions = mkMerge [
    {shared = mkLayer 1000 (resolved.shared or {});}
    (mkIf cfg.shared.skills.enable {home.file = mkLayer 1500 (curated // custom);})
    (mkIf cfg.shared.rules.enable {
      home.file."AGENTS.md" = mkOverride 1500 instructions;
      settings.command_allowlist = mkOverride 1500 (concatMap (rule: [(command rule) "${command rule} *"]) allowed);
    })
  ];
}
