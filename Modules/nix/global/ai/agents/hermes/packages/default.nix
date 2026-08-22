{
  pkgsFor,
  pkgs,
  lix,
  ...
}: let
  inherit (lix.attrsets.access) attrValues;

  core = pkgsFor {
    sources = {
      desktop = {
        input = "hermes-agent";
        description = "Official Desktop Interface";
      };
      minimal = {
        input = "hermes-agent";
        description = "Official Agent CLI";
      };
      tui = {
        input = "hermes-agent";
        description = "Official Terminal Interface";
      };
      hermes-hud = {
        input = "llm-agents";
        description = "Community status / memory monitor TUI";
      };
      hermes-one = {
        input = "llm-agents";
        description = "Community desktop (Hermes One)";
      };
    };
  };

  # profiles =
  #   optionalAttrs
  #   (helpers != null && runtimes != null)
  #   (import ./profiles.nix args);
  profiles = {};

  scripts = import ./scripts/default.nix {inherit lix pkgs;};
in
  core
  // scripts
  // {
    packages =
      core.packages
      ++ scripts.packages
      ++ (attrValues profiles);
  }
