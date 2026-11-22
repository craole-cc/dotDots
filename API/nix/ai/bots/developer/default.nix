{
  lix,
  homePath,
  environmentFiles ? [],
  ...
}: let
  inherit (lix.filesystem.access) readFile;
  role = (import ../../model-policy.nix).worker;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  model = {
    provider = "openai-codex";
    default = role.model;
  };
  routing = import ../../routing {
    inherit lix homePath model environmentFiles;
    profile = "developer";
    offPeakModel = "deepseek-flash";
  };
in
  recursiveUpdate routing {
    bot.title = "Developer";
    description = "Own technical decisions, integration, validation and defect resolution.";
    auth.file = "${homePath}/auth.json";
    home.file = {
      "SOUL.md" = readFile ./SOUL.md;
      "AGENTS.md" = (readFile ../POLICY.md) + "\n" + (readFile ./AGENTS.md);
    };
    settings = {
      inherit model;
      agent = {
        max_turns = 90;
        reasoning_effort = role.effort;
        reasoning_overrides = {
          "deepseek-flash" = "medium";
          ${role.model} = role.effort;
        };
        disabled_toolsets = ["delegation"];
      };
      skills.external_dirs = ["${homePath}/skills"];
    };
  }
