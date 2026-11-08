{
  lix,
  homePath,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
in {
  description = "Author scoped artifacts from an explicit responsible-owner brief.";
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
      reasoning_effort = "high";
      disabled_toolsets = ["delegation"];
    };
    skills.external_dirs = ["${homePath}/skills"];
  };
}
