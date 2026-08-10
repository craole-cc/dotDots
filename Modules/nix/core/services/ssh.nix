{
  config,
  host,
  lib,
  lix,
  top,
  ...
}: let
  cfg = config.${top}.inputs.services.remote.ssh;
  inherit (lix.modules.core._) mkStaged;

  payload = {
    services.openssh = {
      enable = cfg.enable;
      settings.PasswordAuthentication = !cfg.keyOnly;
      settings.KbdInteractiveAuthentication = !cfg.keyOnly;
    };
  };
in {
  options.${top}.inputs.services.remote.ssh = {
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
