{
  lix,
  homeDirectory,
  ...
}: let
  models = rec {
    default = gpt;
    gpt = {
      flash = {
        provider = "openai-codex";
        default = "gpt-6-luna";
      };
      smart = {
        provider = "openai-codex";
        default = "gpt-6.1-sol";
      };
    };
    deepseek = {
      flash = {
        provider = "deepseek";
        default = "deepseek-flash";
      };
      smart = {
        provider = "deepseek";
        default = "deepseek-v4-pro";
      };
    };
  };

  memory = {
    memory_enabled = true;
    user_profile_enabled = true;
    provider = "";
  };
  homePath = "${homeDirectory}/.hermes";
  profiles = import ./roster.nix {inherit lix homeDirectory models memory homePath;};
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.filesystem.access) readDir;
  inherit (lix.filesystem.predicates) pathExists;
  inherit (lix.lists.selection) filter;
  inherit (lix.strings.predicates) hasSuffix;
  keys = "${homeDirectory}/Private/hermes";
  entries =
    if pathExists keys
    then readDir keys
    else {};
in {
  inherit profiles;
  settings = {
    inherit memory;
    model = models.default.smart;
  };
  environment.files =
    (filter pathExists ["${homeDirectory}/Private/hermes.env"])
    ++ map (name: "${keys}/${name}") (filter (name: entries.${name} == "regular" && hasSuffix ".env" name) (attrNames entries));
  kanban = {
    enable = true;
    orchestrator = "planner";
    defaultAssignee = "planner";
    decomposition.model = {
      inherit (models.default.smart) provider;
      model = models.default.smart.default;
    };
  };
}
