{
  lix,
  homePath,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
in {
  description = "Gather bounded evidence, inventories and assigned checks for a responsible owner.";
  auth.file = "${homePath}/auth.json";
  home.file = {
    "SOUL.md" = readFile ./SOUL.md;
    "AGENTS.md" = readFile ../POLICY.md;
  };
  settings = {
    model = {
      provider = "openai-codex";
      default = "gpt-6-luna";
    };
    agent = {
      max_turns = 30;
      reasoning_effort = "medium";
      disabled_toolsets = ["delegation"];
    };
    skills.external_dirs = ["${homePath}/skills"];
  };
}
