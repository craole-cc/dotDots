{
  lix,
  homePath,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
  role = (import ../../model-policy.nix).worker;
in {
  bot.title = "Assistant";
  description = "Own authorized personal operations, correspondence and commitments.";
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
      reasoning_effort = role.effort;
      disabled_toolsets = ["delegation"];
    };
    skills.external_dirs = ["${homePath}/skills"];
  };
}
