{
  config,
  host,
  lix,
  ...
}: let
  dom = "ai";
  sub = "agents";
  mod = "hermes-agent";

  inherit (lix.lists.predicates) isIn;
  inherit (lix.lists.transformation) filter;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {inherit config dom sub mod;};
in
  mkConfig {
    inherit context;

    # This records whether the host's primary user selected Hermes.  Hermes is
    # still configured and run by its Home Manager module, so this core module
    # deliberately does not reference services.hermes-agent.
    options.enable = mkEnable {
      inherit context;
      condition =
        isIn [
          "hermes"
          "hermes-agent"
          "hermes-desktop"
        ]
        (let
          domain = (host.users.data.primary or {}).applications.${dom} or {};
        in
          map (module: domain.${module}) (
            filter (module: domain ? ${module})
            ["primary" "secondary" "tertiary"]
          ));
    };

    outputs = {};
  }
