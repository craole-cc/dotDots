{
  config,
  host,
  lib,
  top,
  lix,
  ...
}: let
  cfg = config.${top}.inputs.services.remote.caddy;
  payload = {
    services.caddy.enable = cfg.enable;
  };
  inherit (lix.modules.core.staging) mkStaged;
in {
  options.${top}.inputs.services.remote.caddy.enable = lib.mkOption {
    description = "Enable Caddy reverse-proxy remote access";
    default = host.access.remote.caddy.enable or false;
    type = lib.types.bool;
  };

  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
