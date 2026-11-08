{lix, ...}: let
  inherit (lix.filesystem.access) readFile;
in {
  shared = {
    skills.enable = true;
    rules.enable = true;
  };
  home.file."SOUL.md" = (readFile ./SOUL.md) + "\n" + (readFile ../POLICY.md);
  settings = {
    agent = {
      reasoning_effort = "low";
      max_turns = 100;
      disabled_toolsets = ["delegation"];
    };
    model = {
      provider = "openai-codex";
      default = "gpt-6-luna";
    };
    memory = {
      memory_enabled = true;
      user_profile_enabled = true;
      provider = "";
    };
  };
}
