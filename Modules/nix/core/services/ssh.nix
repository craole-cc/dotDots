{
  config,
  host,
  lib,
  lix,
  top,
  ...
}: let
  cfg = config.${top}.resolved.services.remote.ssh;

  payload = {
    services.openssh = {
      inherit (cfg) enable;
      settings.PasswordAuthentication = !cfg.keyOnly;
      settings.KbdInteractiveAuthentication = !cfg.keyOnly;
    };
  };
  inherit (lix.modules.core.staging) mkStaged;
in {
  options.${top}.resolved.services.remote.ssh = {
    enable = lib.mkOption {
      description = "Enable SSH remote access";
      default = host.access.remote.ssh.enable or (host.access.ssh or null) != null;
      type = lib.types.bool;
    };
    keyOnly = lib.mkOption {
      description = "Require key-based SSH authentication";
      default = host.access.remote.ssh.keyOnly or true;
      type = lib.types.bool;
    };
  };

  config = lib.mkMerge (mkStaged {
    condition = cfg.enable;
    inherit top payload;
  });
}
