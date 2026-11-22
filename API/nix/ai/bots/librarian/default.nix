{
  lix,
  homePath,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
  role = (import ../../model-policy.nix).executor;
in {
  bot.title = "Librarian";
  description = "Own knowledge provenance, organization, reconciliation and authorized filing.";
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
