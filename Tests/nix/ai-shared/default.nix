{flake}: let
  inherit (flake.lib) lix;
  inherit (flake) inputs;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.lists.predicates) elem all;
  inherit (lix.strings.predicates) hasInfix;
  pkgs = import inputs.nixPackages {system = "x86_64-linux";};
  catalog = (lix.schema.construction.mkSchema {}).ai;
  shared = {
    skills = catalog.skills {inherit lix pkgs inputs;};
    inherit (catalog) rules;
  };
  policy = catalog.policy {inherit lix;};
  agentFiles = piEnabled: deepseekEnabled:
    (pkgs.lib.evalModules {
      specialArgs = {inherit lix pkgs inputs;};
      modules = [
        ../../../Modules/nix/home/ai/agents/shared
        ({lib, ...}: {
          options = {
            _.resolved.ai.agents = {
              pi.defined.enable = lib.mkOption {
                type = lib.types.bool;
                default = piEnabled;
              };
              deepseek.defined.enable = lib.mkOption {
                type = lib.types.bool;
                default = deepseekEnabled;
              };
            };
            _.outputs = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = {};
            };
            home.file = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = {};
            };
          };
        })
      ];
    }).config.home.file;
  piFiles = agentFiles true false;
  deepseekFiles = agentFiles false true;
  bothFiles = agentFiles true true;
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
  inherit (import ../../../Modules/nix/home/ai {inherit lix;}) imports;
in {
  apiCatalog =
    lix.types.predicates.isFunction catalog.bots
    && lix.types.predicates.isFunction catalog.skills
    && catalog.rules == import ../../../API/nix/ai/rules;
  customSkills = attrNames shared.skills.custom == ["commit-messages" "hermes-agent-docs" "knowledge" "nix-inspect" "nix-style" "plan-first" "sh-utils" "writing-style"];
  codexCustomSkills = all (name: codexSkills.program.skills ? ${name}) (attrNames shared.skills.custom);
  codexSkillOverride = codexSkills.program.skills.nix-style == "User override";
  codexCuratedSource = codexSkills.program.skills.gh-fix-ci == shared.skills.curated.target "gh-fix-ci";
  codexRuleRendering =
    hasInfix ''decision = "prompt")'' codexRules.options.rules.default.common
    && hasInfix ''["git","reset","--hard"]'' codexRules.options.rules.default.common;
  codexRuleOverride = codexRules.program.rules.custom == "User rules";
  sharedNotImportedAsModule = !(elem ../../../API/nix/ai/default.nix imports);
  piCustomSkills = all (name:
    piFiles ? ${".pi/agent/skills/${name}/SKILL.md"}
    || piFiles ? ${".pi/agent/skills/${name}"}) (attrNames shared.skills.custom);
  deepseekCustomSkills = all (name:
    deepseekFiles ? ${".dsh/skills/${name}/SKILL.md"}
    || deepseekFiles ? ${".dsh/skills/${name}"}) (attrNames shared.skills.custom);
  sharedInlineContent =
    piFiles.".pi/agent/skills/sh-utils/SKILL.md".text
    == shared.skills.custom.sh-utils
    && deepseekFiles.".dsh/skills/sh-utils/SKILL.md".text == shared.skills.custom.sh-utils;
  sharedCuratedBundles =
    piFiles.".pi/agent/skills/gh-fix-ci".source
    == shared.skills.curated.target "gh-fix-ci"
    && deepseekFiles.".dsh/skills/gh-address-comments".source == shared.skills.curated.target "gh-address-comments";
  sharedDocumentationBundle =
    piFiles.".pi/agent/skills/hermes-agent-docs".source
    == shared.skills.custom.hermes-agent-docs
    && deepseekFiles.".dsh/skills/hermes-agent-docs".source == shared.skills.custom.hermes-agent-docs;
  agentPolicy = all (instructions:
    hasInfix "git reset --hard" instructions
    && hasInfix "not native prefix-rule enforcement" instructions
    && hasInfix "read plan-first" instructions) [
    piFiles.".pi/agent/AGENTS.md".text
    deepseekFiles.".dsh/AGENTS.md".text
  ];
  enabledAgentOnly =
    !(piFiles ? ".dsh/AGENTS.md")
    && !(deepseekFiles ? ".pi/agent/AGENTS.md")
    && bothFiles ? ".pi/agent/AGENTS.md"
    && bothFiles ? ".dsh/AGENTS.md"
    && agentFiles false false == {};
  allowlistDoesNotAllowPromptRules =
    elem "git status *" policy.allowlist
    && !(elem "git reset --hard" policy.allowlist)
    && !(elem "git reset --hard *" policy.allowlist);
}
