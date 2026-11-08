{
  lix,
  homePath,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
in {
  description = "Independently review owner-completed packages against scope and evidence.";
  auth.file = "${homePath}/auth.json";
  home.file = {
    "SOUL.md" = readFile ./SOUL.md;
    "AGENTS.md" = readFile ../POLICY.md;
  };
  settings = {
    model = {
      provider = "openai-codex";
      default = "gpt-6.1-sol";
    };
    agent = {
      max_turns = 90;
      reasoning_effort = "high";
      disabled_toolsets = ["delegation"];
    };
    skills.external_dirs = ["${homePath}/skills"];
  };
}
