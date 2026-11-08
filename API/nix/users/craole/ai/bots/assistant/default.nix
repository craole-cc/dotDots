{
  lix,
  homePath,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
in {
  description = "Own authorized personal operations, correspondence and commitments.";
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
      reasoning_effort = "medium";
      disabled_toolsets = ["delegation"];
    };
    skills.external_dirs = ["${homePath}/skills"];
  };
}
