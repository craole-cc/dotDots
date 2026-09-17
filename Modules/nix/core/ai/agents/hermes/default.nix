{
  config,
  host,
  lix,
  ...
}: let
  dom = "ai";
  sub = "agents";
  mod = "hermes";

  inherit (lix.lists.predicates) isIn;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config dom sub mod;
  };

  ai = (host.users.data.primary or {}).applications.ai or {};
  selectedApplications = [
    (ai.primary or null)
    (ai.secondary or null)
    (ai.tertiary or null)
  ];
in
  mkConfig {
    inherit context;

    # This records whether the host's primary user selected Hermes.  Hermes is
    # still configured and run by its Home Manager module, so this core module
    # deliberately does not reference services.hermes-agent.
    options.enable = mkEnable {
      inherit context;
      condition = isIn [
        "hermes"
        "hermes-agent"
        "hermes-desktop"
      ] selectedApplications;
    };

    outputs = {};
  }
