{
  config,
  lix,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config;
    dom = "version-control";
    sub = "tools";
    mod = "delta";
  };
  inherit (context) cfg;
in
  mkConfig {
    inherit context;
    options = {
      enable =
        mkEnable {inherit context;}
        // {default = config.programs.git.enable;};
      git.enable =
        mkEnable {description = "Enable Delta's Git integration";}
        // {default = config.programs.git.enable;};
      jujutsu.enable =
        mkEnable {description = "Enable Delta's Jujutsu integration";}
        // {default = config.programs.jujutsu.enable;};
    };
    outputs = {
      programs.delta = {
        inherit (cfg) enable;
        enableGitIntegration = cfg.git.enable;
        enableJujutsuIntegration = cfg.jujutsu.enable;
      };
    };
  }
