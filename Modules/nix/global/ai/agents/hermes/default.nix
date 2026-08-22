args: let
  utils = args.pkgsFor {
    sources = {
      desktop = "hermes-agent";
      hermes-hud = "llm-agents";
      hermes-one = "llm-agents";
      minimal = "hermes-agent";
      tui = "hermes-agent";
    };
  };
  environment = import ./environment (args // utils);
  hooks = import ./hooks (args // environment // utils);
in {
  inherit (environment) description env;
  inherit (hooks) shellHook;
  packages = utils.packages ++ hooks.packages;
}
