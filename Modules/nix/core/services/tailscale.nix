{
  config,
  host,
  lib,
  top,
  lix,
  ...
}: let
  cfg = config.${top}.inputs.services.remote.tailscale;
  payload = {
    services.tailscale.enable = cfg.enable;
  };
  inherit (lix.modules.core.staging) mkStaged;
in {
  options.${top}.inputs.services.remote.tailscale = {
    enable = lib.mkOption {
      description = "Enable Tailscale remote access";
      default = host.access.remote.tailscale.enable or host.access.tailscale.enable or (lib.elem "vpn" (host.functionalities or []));
      type = lib.types.bool;
    };
  };

  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
