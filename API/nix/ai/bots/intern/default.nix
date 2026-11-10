{
  lix,
  homePath,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
in {
  terse.level = "lite";
  bot.title = "Intern";
  description = "Gather bounded evidence, inventories and assigned checks for a responsible owner.";
  auth.file = "${homePath}/auth.json";
  home.file = {
    "SOUL.md" = readFile ./SOUL.md;
    "AGENTS.md" = (readFile ../POLICY.md) + "\n" + (readFile ./AGENTS.md);
  };
  settings =
    (import ../../routing/routine.nix {inherit lix;})
    // {
      agent = {
        max_turns = 30;
        reasoning_effort = "medium";
        disabled_toolsets = ["delegation"];
      };
      skills.external_dirs = ["${homePath}/skills"];
    };
}
