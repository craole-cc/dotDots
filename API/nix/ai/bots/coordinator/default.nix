{
  lix,
  homePath,
  delegationProfiles ? [],
  ...
}: let
  inherit (lix.filesystem.access) readFile;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.lists.predicates) any;
  plugins = import ../../plugins {inherit lix;};
in {
  bot.title = "Coordinator";
  description = "Own cross-task planning, dependencies, assignments, review routing and approval gates.";
  extra.plugins = [plugins.advanced-delegation];
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
      max_turns = 90;
      reasoning_effort = "high";
      disabled_toolsets = [];
    };
    plugins.enabled = ["advanced-delegation"];
    delegation = {
      backend = "profile_routes";
      backends.profile_routes =
        {
          profiles = delegationProfiles;
        }
        // optionalAttrs (any (profile: profile.name == "intern") delegationProfiles) {
          default = "intern";
        };
    };
    skills.external_dirs = ["${homePath}/skills"];
  };
}
