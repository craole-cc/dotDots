{
  pkgsFor,
  pkgs,
  lix,
  inputs, # <- add this; same normalized inputs set already flowing into pkgsFor
  ...
}: let
  inherit (lix.attrsets.access) attrValues;

  sources = {
    inherit (inputs) hermes-agent llm-agents;
  };

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

  scripts = import ./scripts {inherit lix pkgs;};
  tools = utils // scripts // {default = utils.minimal;};
  # profiles =
  #   import ./profiles (middleware // {inherit (pkgs) writeScriptBin;});
in {
  inherit tools sources;
  packages =
    utils.packages
    # ++ (attrValues profiles)
    ++ scripts.packages;
}
