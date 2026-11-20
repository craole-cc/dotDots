{
  config,
  inputs,
  system,
  lix,
  user,
  ...
}: let
  inherit (lix.lists.predicates) isIn;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.primitives) package;

  dom = "ai";
  sub = "agents";
  mod = "pi";

  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;
in
  mkConfig {
    inherit context;

    options = {
      enable = mkEnable {
        inherit context;
        condition = isIn [mod] (selectedPackages user);
      };

      package = mkOption {
        type = package;
        default = inputs.llm-agents.packages.${system}.pi;
        description = "Pi agent harness package to expose in this user's profile.";
      };
    };

    outputs.home.packages = [cfg.package];
  }
