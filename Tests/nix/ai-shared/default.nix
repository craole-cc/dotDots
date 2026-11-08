{flake}: let
  inherit (flake.lib) lix;
  inherit (flake) inputs;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.lists.predicates) elem all;
  inherit (lix.strings.predicates) hasInfix;
  pkgs = import inputs.nixPackages {system = "x86_64-linux";};
  shared = import ../../../Modules/nix/home/ai/shared {inherit lix pkgs inputs;};
  codexSkills = import ../../../Modules/nix/home/ai/agents/codex/skills {
    inherit lix pkgs inputs;
    cfg = {
      curated.skills = shared.skills.curated.default;
      skills.nix-style = "User override";
    };
  };
  codexRules = import ../../../Modules/nix/home/ai/agents/codex/rules {
    inherit lix;
    cfg.rules.custom = "User rules";
  };
  imports = (import ../../../Modules/nix/home/ai {inherit lix;}).imports;
in {
  customSkills = attrNames shared.skills.custom == ["commit-messages" "nix-inspect" "nix-style" "plan-first" "sh-utils" "writing-style"];
  codexCustomSkills = all (name: codexSkills.program.skills ? ${name}) (attrNames shared.skills.custom);
  codexSkillOverride = codexSkills.program.skills.nix-style == "User override";
  codexCuratedSource = codexSkills.program.skills.gh-fix-ci == shared.skills.curated.target "gh-fix-ci";
  codexRuleRendering =
    hasInfix ''decision = "prompt")'' codexRules.options.rules.default.common
    && hasInfix ''["git","reset","--hard"]'' codexRules.options.rules.default.common;
  codexRuleOverride = codexRules.program.rules.custom == "User rules";
  sharedNotImportedAsModule = !(elem ../../../Modules/nix/home/ai/shared/default.nix imports);
}
