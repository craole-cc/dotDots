{
  lix,
  homePath,
  ...
}: let
  inherit (lix.filesystem.access) readFile;
in {
  terse.level = "lite";
  bot.title = "Scribe";
  description = "Author scoped artifacts from an explicit responsible-owner brief.";
  auth.file = "${homePath}/auth.json";
  home.file = {
    "SOUL.md" = readFile ./SOUL.md;
    "AGENTS.md" = (readFile ../POLICY.md) + "\n" + (readFile ./AGENTS.md);
  };
  settings =
    (import ../../routing/routine.nix {inherit lix;})
    // {
      agent = {
        reasoning_effort = "low";
        reasoning_overrides = {
          "deepseek-flash" = "low";
        };
        disabled_toolsets = ["delegation"];
      };
      skills.external_dirs = ["${homePath}/skills"];
    };
}
