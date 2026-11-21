{
  config,
  inputs,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.transformation) concatMapAttrs;
  inherit (lix.filesystem.predicates) pathExists;
  inherit (lix.modules.construction) mkConfig mkContext mkIf mkMerge;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.schema.construction) mkSchema;
  inherit (lix.strings.predicates) hasPrefix;
  inherit (lix.types.predicates) isPath isString;

  context = mkContext {
    inherit config;
    dom = "ai";
    sub = "agents";
    mod = "shared";
  };
  catalog = (mkSchema {}).ai;
  skills = catalog.skills {inherit lix pkgs inputs;};
  policy = catalog.policy {inherit lix;};
  sources = (genAttrs skills.curated.default skills.curated.target) // skills.custom;
  piEnabled = config._.resolved.ai.agents.pi.defined.enable or false;
  deepseekEnabled = config._.resolved.ai.agents.deepseek.defined.enable or false;

  #? Link complete bundles, including scripts/references; wrap inline skills.
  files = prefix:
    concatMapAttrs (name: value:
      if (isPath value || (isString value && hasPrefix "/" value)) && pathExists (toString value + "/SKILL.md")
      then {"${prefix}/${name}".source = value;}
      else {
        "${prefix}/${name}/SKILL.md" =
          if isPath value
          then {source = value;}
          else {text = value;};
      })
    sources;
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      condition = piEnabled || deepseekEnabled;
      description = "Install the API AI catalog's skills and workflow policy for enabled Pi and DeepSeek agents.";
    };
    outputs.home.file = mkMerge [
      (mkIf piEnabled (
        files ".pi/agent/skills"
        // {
          ".pi/agent/AGENTS.md".text =
            policy.instructions {runtime = "Pi";}
            + ''

              Pi's grep tool uses rg, and its find tool uses fd. Prefer those
              native tools for inspection; when using bash, follow sh-utils.
            '';
        }
      ))
      (mkIf deepseekEnabled (
        files ".dsh/skills"
        // {".dsh/AGENTS.md".text = policy.instructions {runtime = "DeepSeek Harness";};}
      ))
    ];
  }
