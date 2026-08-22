args: let
  utils = args.pkgsFor {
    sources = {
      hermes-one = "llm-agents";
      hermes-hud = "llm-agents";
      desktop = "hermes-agent";
      messaging = "hermes-agent";
      minimal = "hermes-agent";
      tui = "hermes-agent";
    };
  };
  environment = import ./environment (args // utils);
  hooks = import ./hooks (args // environment // utils);
in {
  inherit (environment) description env;
  inherit (hooks) shellHook;
  inherit (utils) packages;
}
