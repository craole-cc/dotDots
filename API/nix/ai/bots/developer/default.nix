{
  lix,
  homePath,
  environmentFiles ? [],
  ...
}: let
  inherit (lix.filesystem.access) readFile;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  model = {
    provider = "openai-codex";
    default = "gpt-6.1-sol";
  };
  routing = import ../../routing {
    inherit lix homePath model environmentFiles;
    profile = "developer";
    offPeakModel = "deepseek-flash";
  };
in
  recursiveUpdate routing {
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
        reasoning_effort = "low";
        disabled_toolsets = ["delegation"];
      };
      skills.external_dirs = ["${homePath}/skills"];
    };
  }
