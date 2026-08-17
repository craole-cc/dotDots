{
  config,
  lix,
  top,
  ...
}: let
  dom = "version-control";
  sub = "clients";
  mod = "gitui";
  cfg = config.${top}.resolved.${dom}.${mod}.explicit;

  inherit (lix.modules.construction) mkConfig;
  inherit (lix.options.construction) mkEnableOption;
in
  mkConfig {
    inherit config top dom sub mod;

    options = {
      enable = mkEnableOption mod // {default = true;};
    };

    outputs = {
      programs.gitui = {
        enable = cfg.enable;
      };
    };
  }
