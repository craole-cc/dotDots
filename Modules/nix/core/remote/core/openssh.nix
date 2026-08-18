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
    sub = "core";
    mod = "openssh";
  };
  inherit (context) cfg;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkOption {
        description = "Enable SSH remote access";
        default = host.access.remote.ssh.enable or (host.access.ssh or null) != null;
        type = bool;
      };
      keyOnly = mkOption {
        description = "Require key-based SSH authentication";
        default = host.access.remote.ssh.keyOnly or true;
        type = bool;
      };
    };
    outputs.services.openssh = {
      inherit (cfg) enable;
      settings = {
        PasswordAuthentication = !cfg.keyOnly;
        KbdInteractiveAuthentication = !cfg.keyOnly;
      };
    };
  }
