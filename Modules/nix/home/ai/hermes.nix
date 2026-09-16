{
  config,
  lix,
  inputs,
  host,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.lists.predicates) isIn;

  context = mkContext {
    inherit config;
    dom = "ai";
    sub = "agents";
    mod = "hermes";
  };
  # inherit (context) ctx mod;
  # isAllowed = isIn mod (host.functionalities or []);
  isAllowed = true;
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = isAllowed;
    };
    outputs.home.packages = with inputs."hermes-agent".packages.${pkgs.system}; [
      hermes-desktop
      hermes
    ];
  }
