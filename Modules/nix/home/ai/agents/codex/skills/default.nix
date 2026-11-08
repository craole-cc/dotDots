{
  lix,
  pkgs,
  inputs,
  cfg,
  ...
}: let
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.options.construction) mkOption;
  inherit (lix.types.combinators) attrsOf either listOf;
  inherit (lix.types.primitives) lines path str;
  shared = import ../../../shared/skills {inherit lix pkgs inputs;};
in {
  options = {
    curated.skills = mkOption {
      type = listOf str;
      default = shared.curated.default;
      description = "Skills selected from the shared pinned OpenAI curated source.";
    };
    skills = mkOption {
      type = attrsOf (either lines path);
      default = {};
      description = "Extra Codex skills overlaying the shared curated and custom skills.";
    };
  };
  program.skills = (genAttrs cfg.curated.skills shared.curated.target) // shared.custom // cfg.skills;
}
