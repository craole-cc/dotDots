args: let
  environment = import ./environment;
in {
  packages =
    removeAttrs
    (args.pkgsFor {
      sources = {
        hermes-agent = "llm-agents";
      };
    }).packages
    ["hermes-desktop"];
}
