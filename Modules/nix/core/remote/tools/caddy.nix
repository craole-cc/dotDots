{
  config,
  host,
  lix,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (lix.options.construction) mkOption;
  inherit (lix.types.primitives) bool;

  context = mkContext {
    inherit config;
    dom = "remote";
    sub = "tools";
    mod = "caddy";
  };
  inherit (context) cfg;
in
  mkConfig {
    inherit context;
    options.enable = mkOption {
      description = "Enable Caddy reverse-proxy remote access";
      default = host.access.remote.caddy.enable or false;
      type = bool;
    };
    outputs.services.caddy.enable = cfg.enable;
  }
