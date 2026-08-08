{
  config,
  host,
  lib,
  top,
  ...
}: let
  cfg = config.${top}.services.remote.ssh;
in {
  options.${top}.services.remote.ssh = {
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

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = cfg.enable;
      settings.PasswordAuthentication = !cfg.keyOnly;
      settings.KbdInteractiveAuthentication = !cfg.keyOnly;
    };
  };
}