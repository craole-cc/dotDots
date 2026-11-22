{
  lix,
  homePath,
  environmentFiles ? [],
  ...
}: let
  inherit (lix.filesystem.access) readFile;
  role = (import ../../model-policy.nix).executor;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  model = {
    provider = "openai-codex";
    default = role.model;
  };
  routing = import ../../routing {
    inherit lix homePath model environmentFiles;
    profile = "intern";
    offPeakModel = "deepseek-flash";
  };
in
  recursiveUpdate routing {
    terse.level = "lite";
    bot.title = "Intern";
    description = "Gather bounded evidence, inventories and assigned checks for a responsible owner.";
    auth.file = "${homePath}/auth.json";
    home.file = {
      "SOUL.md" = readFile ./SOUL.md;
      "AGENTS.md" = (readFile ../POLICY.md) + "\n" + (readFile ./AGENTS.md);
    };
    settings = {
      inherit model;
      agent = {
        max_turns = 30;
        reasoning_effort = role.effort;
        disabled_toolsets = ["delegation"];
      };
      skills.external_dirs = ["${homePath}/skills"];
    };
  }
