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
  inherit (lix.filesystem.predicates) pathExists;
  inherit (lix.strings.predicates) hasPrefix;
  inherit (lix.strings.transformation) unsafeDiscardStringContext;
  inherit (lix.types.predicates) isPath isString;
  inherit (lix.modules.construction) mkIf mkLayer mkMerge mkOverride;
  inherit (lix.options.construction) mkFalse mkOption;
  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) lines str;

  inherit (lix.schema.construction) mkSchema;
  catalog = (mkSchema {}).ai;
  shared = {
    skills = catalog.skills {inherit lix pkgs inputs;};
  };
  policy = catalog.policy {inherit lix;};
  resolved = resolve {};
  files = prefix: directory:
    concatMapAttrs (name: kind:
      if kind == "directory"
      then files "${prefix}/${name}" (directory + "/${name}")
      # Convert generated store strings to paths so Hermes copies binary assets too.
      # Path conversion rejects string context; the resulting source path is tracked
      # again when the upstream document derivation interpolates it for copying.
      else {"${prefix}/${name}" = /. + unsafeDiscardStringContext (toString directory + "/${name}");})
    (readDir directory);
  custom = concatMapAttrs (name: value:
    if (isPath value || (isString value && hasPrefix "/" value)) && pathExists (toString value + "/SKILL.md")
    then files "skills/${name}" (toString value)
    else {"skills/${name}/SKILL.md" = value;})
  shared.skills.custom;
  curated =
    concatMapAttrs (name: directory: files "skills/${name}" directory)
    (genAttrs cfg.shared.skills.curated shared.skills.curated.target);
  instructions = policy.instructions {
    runtime = "Hermes";
    enforcement = ''
      Hermes's command allowlist enforces the allow entries. Prompt entries here
      are instructions; Codex's prefix-rule prompt mechanism is not available in
      Hermes. Keep Hermes's native approval checks enabled.
    '';
  };
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
    rules = {
      enable = mkFalse "Apply shared command policy using Hermes's allowlist and AGENTS.md instructions.";
      instructions = mkOption {
        type = lines;
        default = "";
        description = "Bot-specific instructions appended to the shared command policy in AGENTS.md.";
      };
    };
  };
  resolutions = mkMerge [
    {shared = mkLayer 1000 (resolved.shared or {});}
    (mkIf cfg.shared.skills.enable {home.file = mkLayer 1500 (curated // custom);})
    (mkIf cfg.shared.rules.enable {
      home.file."AGENTS.md" = mkOverride 1500 (instructions + "\n" + cfg.shared.rules.instructions);
      settings.command_allowlist = mkOverride 1500 policy.allowlist;
    })
  ];
}
