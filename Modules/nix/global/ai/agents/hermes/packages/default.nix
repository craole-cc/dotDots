{
  pkgsFor,
  pkgs,
  lix,
  ...
}: let
  inherit (lix.attrsets.access) attrValues;

  utils = pkgsFor {
    sources = {
      desktop = {
        input = "hermes-agent";
        description = "Official Desktop Interface";
      };
      minimal = {
        input = "hermes-agent";
        description = "Official Command Line Interface";
      };
      tui = {
        input = "hermes-agent";
        description = "Official Terminal Interface";
      };
      hermes-hud = {
        input = "llm-agents";
        description = "Community-maintained Terminal Interface";
      };
      hermes-one = {
        input = "llm-agents";
        description = "Community-maintained Desktop Interface";
      };
    };
  };

  # profiles =
  #   import ./profiles (middleware // {inherit (pkgs) writeScriptBin;});

  scripts = import ./scripts {inherit lix pkgs;};
  tools = utils // scripts // {default = utils.minimal;};
in
  tools
  // {
    inherit tools;
    packages =
      utils.packages
      # ++ (attrValues profiles)
      ++ scripts.packages;
  }
