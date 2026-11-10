{lix, ...}: let
  inherit (lix.filesystem.access) readFile;
in {
  shared = {
    skills.enable = true;
    rules = {
      enable = true;
      instructions = (readFile ../POLICY.md) + "\n" + (readFile ./AGENTS.md);
    };
  };
  home.file."SOUL.md" = readFile ./SOUL.md;
  settings =
    (import ../../routing/routine.nix {inherit lix;})
    // {
      agent = {
        reasoning_effort = "medium";
        max_turns = 100;
        disabled_toolsets = ["delegation"];
      };
      plugins.disabled = ["advanced-delegation"];
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
        provider = "";
      };
    };
}
