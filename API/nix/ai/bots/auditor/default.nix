{
  lix,
  homePath,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
  role = (import ../../model-policy.nix).planner;
in {
  bot.title = "Auditor";
  description = "Independently review owner-completed packages against scope and evidence.";
  auth.file = "${homePath}/auth.json";
  home.file = {
    "SOUL.md" = readFile ./SOUL.md;
    "AGENTS.md" = (readFile ../POLICY.md) + "\n" + (readFile ./AGENTS.md);
  };
  settings = {
    model = {
      provider = "openai-codex";
      default = role.model;
    };
    agent = {
      max_turns = 90;
      reasoning_effort = role.effort;
      disabled_toolsets = ["delegation"];
    };
    skills.external_dirs = ["${homePath}/skills"];
  };
}
