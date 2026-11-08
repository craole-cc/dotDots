{
  lix,
  homePath,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
in {
  description = "Own technical decisions, integration, validation and defect resolution.";
  auth.file = "${homePath}/auth.json";
  home.file = {
    "SOUL.md" = readFile ./SOUL.md;
    "AGENTS.md" = (readFile ../POLICY.md) + "\n" + (readFile ./AGENTS.md);
  };
  settings = {
    model = {
      provider = "openai-codex";
      default = "gpt-6-luna";
    };
    agent = {
      max_turns = 90;
      reasoning_effort = "medium";
      disabled_toolsets = ["delegation"];
    };
    skills.external_dirs = ["${homePath}/skills"];
  };
}
