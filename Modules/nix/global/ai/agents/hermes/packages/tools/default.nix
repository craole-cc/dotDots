{
  pkgsFor,
  inputs,
  ...
}: let
  sources = {
    inherit (inputs) hermes-agent llm-agents;
  };

  tools =
    pkgsFor {
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
          exe = "hermes-tui";
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
    }
    // {default = tools.minimal;};
in {
  inherit sources tools;
}
