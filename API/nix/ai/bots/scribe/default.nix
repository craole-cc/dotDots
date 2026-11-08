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
    default = "gpt-6-luna";
  };
  routing = import ../../routing {
    inherit lix homePath model environmentFiles;
    profile = "scribe";
    offPeakModel = "deepseek-flash";
  };
in
  recursiveUpdate routing {
    bot.title = "Scribe";
    description = "Author scoped artifacts from an explicit responsible-owner brief.";
    auth.file = "${homePath}/auth.json";
    home.file = {
      "SOUL.md" = readFile ./SOUL.md;
      "AGENTS.md" = (readFile ../POLICY.md) + "\n" + (readFile ./AGENTS.md);
    };
    settings = {
      inherit model;
      agent = {
        reasoning_effort = "high";
        disabled_toolsets = ["delegation"];
      };
      skills.external_dirs = ["${homePath}/skills"];
    };
  }
