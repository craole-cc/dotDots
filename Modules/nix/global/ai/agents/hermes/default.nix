args: let
  environment = import ./environment args;
  packages =
    (args.pkgsFor {
      exclude = ["hermes-desktop"];
      sources = {
        hermes-agent = "llm-agents";
      };
    }).packages;
in {
  inherit (environment) description env shellHook;
  inherit packages;
}
