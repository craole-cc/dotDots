args: let
  environment = import ./environment args;
  inherit
    (
      (args.pkgsFor {
        exclude = ["hermes-desktop"];
        sources = {
          hermes-agent = "llm-agents";
        };
      })
    )
    packages
    ;
in {
  inherit (environment) description env shellHook;
  inherit packages;
}
