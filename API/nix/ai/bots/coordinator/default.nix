{
  lix,
  homePath,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
in {
  terse.level = "lite";
  bot.title = "Coordinator";
  description = "Own cross-task planning, dependencies, assignments, review routing and approval gates.";
  extra.plugins = [];
  auth.file = "${homePath}/auth.json";
  home.file = {
    "SOUL.md" = readFile ./SOUL.md;
    "AGENTS.md" = (readFile ../POLICY.md) + "\n" + (readFile ./AGENTS.md);
  };
  settings =
    (import ../../routing/routine.nix {inherit lix;})
    // {
      agent = {
        max_turns = 90;
        reasoning_effort = "high";
        disabled_toolsets = [];
      };
      plugins = {
        enabled = [];
        disabled = ["advanced-delegation" "disk-cleanup" "memory-wiki"];
      };
      skills.external_dirs = ["${homePath}/skills"];
    };
}
