{
  config,
  host,
  lib,
  top,
  ...
}: let
  cfg = config.${top}.inputs.services.remote.caddy;
in {
  options.${top}.inputs.services.remote.caddy.enable = lib.mkOption {
    description = "Enable Caddy reverse-proxy remote access";
    default = host.access.remote.caddy.enable or false;
    type = lib.types.bool;
  };

  config.services.caddy.enable = cfg.enable;
}