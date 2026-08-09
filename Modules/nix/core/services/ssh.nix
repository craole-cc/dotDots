{
  config,
  host,
  lib,
  top,
  ...
}: let
  cfg = config.${top}.inputs.services.remote.ssh;
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

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
    services.openssh = {
      enable = cfg.enable;
      settings.PasswordAuthentication = !cfg.keyOnly;
      settings.KbdInteractiveAuthentication = !cfg.keyOnly;
    };
  })
    {
      ${top}.output = lib.mkIf cfg.enable {
    services.openssh = {
      enable = cfg.enable;
      settings.PasswordAuthentication = !cfg.keyOnly;
      settings.KbdInteractiveAuthentication = !cfg.keyOnly;
    };
  };
    }
  ];
}