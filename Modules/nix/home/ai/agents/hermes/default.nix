{
  config,
  lix,
  user,
  ...
}: let
  dom = "ai";
  sub = "agents";
  mod = "hermes";

  inherit (lix.lists.predicates) isIn;
  inherit (lix.lists.transformation) filter;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.primitives) anything;

  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;

  selectedApplications = let
    ai = user.applications.ai or {};
  in
    map (key: ai.${key}) (
      filter (key: ai ? ${key})
      ["primary" "secondary" "tertiary"]
    )
    ++ (user.applications.allowed or []);
in
  mkConfig {
    inherit context;

    options = {
      enable = mkEnable {
        inherit context;
        condition =
          isIn [
            "hermes"
            "hermes-agent"
            "hermes-desktop"
          ]
          selectedApplications;
      };

      # These are forwarded without narrowing the upstream Hermes interface.
      # `service` accepts settings, environmentFiles, mcpServers, backend,
      # documents, plugins, restart policy, and every future option under
      # services.hermes-agent.  Keep secrets in environmentFiles, not settings.
      service = mkOption {
        type = anything;
        default = {
          gateway.enable = true;
          extraDependencyGroups = ["messaging"];
        };
      };

      # This is the programs.hermes-agent shape: package and desktop options
      # may be overridden independently of the user service.
      program = mkOption {
        type = anything;
        default.desktop.enable = true;
      };
    };

    outputs = {
      services.hermes-agent = cfg.service // {enable = true;};
      programs.hermes-agent = cfg.program // {enable = true;};
    };
  }
