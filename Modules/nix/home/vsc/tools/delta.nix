{
  config,
  lix,
  top,
  ...
}: let
  dom = "version-control";
  sub = "tools";
  mod = "delta";
  cfg = config.${top}.resolved.${dom}.${mod}.explicit;

  inherit (lix.modules.construction) mkConfig;
  inherit (lix.options.construction) mkEnableOption;
in
  mkConfig {
    inherit config top dom sub mod;
    options = {
      enable =
        mkEnableOption mod
        // {default = config.programs.git.enable;};
      git.enable =
        mkEnableOption mod
        // {default = config.programs.git.enable;};
      jujutsu.enable =
        mkEnableOption mod
        // {default = config.programs.jujutsu.enable;};
    };
    outputs = {
      programs.delta = {
        enable = cfg.enable;
        enableGitIntegration = cfg.git.enable;
        enableJujutsuIntegration = cfg.jujutsu.enable;
      };
    };
  }
