{
  config,
  lix,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config;
    dom = "shells";
    sub = "tools";
    mod = "atuin";
  };
  isEnabled = program: config.programs.${program}.enable;
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = user.applications.utilities.atuin.enable or false;
    };
    outputs.programs.atuin = {
      enable = true;
      daemon.enable = true;
      enableBashIntegration = isEnabled "bash";
      enableNushellIntegration = isEnabled "nushell";
      enableFishIntegration = isEnabled "fish";
      enableZshIntegration = isEnabled "zsh";
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        sync_address = "https://api.atuin.sh";
        search_mode = "prefix";
      };
    };
  }
