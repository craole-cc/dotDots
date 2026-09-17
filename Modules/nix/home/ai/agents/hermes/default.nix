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
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config dom sub mod;
  };

  ai = user.applications.ai or {};
  isSelected = isIn [
    "hermes"
    "hermes-agent"
    "hermes-desktop"
  ] [
    (ai.primary or null)
    (ai.secondary or null)
    (ai.tertiary or null)
  ];
in
  mkConfig {
    inherit context;

    options.enable = mkEnable {
      inherit context;
      condition = isSelected;
    };

    outputs = {
      services.hermes-agent = {
        enable = true;
        gateway.enable = true;
        extraDependencyGroups = ["messaging"];
      };

      programs.hermes-agent = {
        enable = true;
        desktop.enable = true;
      };
    };
  }
{}
