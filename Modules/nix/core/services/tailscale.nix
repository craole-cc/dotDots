{
  config,
  host,
  lib,
  top,
  ...
}: let
  cfg = config.${top}.inputs.services.remote.tailscale;
in {
  options.${top}.inputs.services.remote.tailscale = {
    enable = lib.mkOption {
    description = "Enable Tailscale remote access";
    default = host.access.remote.tailscale.enable or host.access.tailscale.enable or (lib.elem "vpn" (host.functionalities or []));
    type = lib.types.bool;
    };
  };

  config.services.tailscale.enable = cfg.enable;
}
