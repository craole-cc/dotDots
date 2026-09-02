{
  config,
  host,
  lix,
  pkgs,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "programs";
    mod = "nix-ld";
  };
  inherit (context) cfg mod;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) literalExpression mkEnable;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        description = "nix-ld for prebuilt dynamically linked development tools";
        condition = host.capabilities.development;
        defaultText = literalExpression "host.capabilities.development";
      };
    };
    outputs = {
      programs.${mod}.enable = cfg.enable;
      environment.systemPackages = [pkgs.nix-ld];
    };
  }
