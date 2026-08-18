{
  config,
  host,
  lix,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (lix.options.construction) mkOption;
  inherit (lix.types.primitives) bool;
  inherit (lix.lists.predicates) isIn;

  context = mkContext {
    inherit config;
    dom = "remote";
    sub = "core";
    mod = "tailscale";
  };
  inherit (context) cfg;
in
  mkConfig {
    inherit context;
    options.enable = mkOption {
      description = "Enable Tailscale remote access";
      default =
        host.access.remote.tailscale.enable
        or host.access.tailscale.enable
        or (isIn "vpn" (host.functionalities or []));
      type = bool;
    };
    outputs.services.tailscale.enable = cfg.enable;
  }
