{
  config,
  lix,
  top,
  ...
}: let
  dom = "version-control";
  sub = "core";
  mod = "jujutsu";
  cfg = config.${top}.resolved.${dom}.${mod}.explicit;
  inherit (config.programs) git;

  inherit (lix.modules.construction) mkConfig;
  inherit (lix.options.construction) mkEnableOption mkOption;
  inherit (lix.types.combinators) nullOr;
  inherit (lix.types.primitives) str;
in
  mkConfig {
    inherit config top dom sub mod;

    options = {
      enable = mkEnableOption mod // {default = true;};

      user = {
        name = mkOption {
          type = nullOr str;
          default = git.settings.user.name or null;
          description = "Jujutsu user name";
        };
        email = mkOption {
          type = nullOr str;
          default = git.settings.user.email or null;
          description = "Jujutsu user email address";
        };
      };
    };

    outputs = {
      programs.jujutsu = {
        enable = cfg.enable;
        settings = {
          user = {
            name = cfg.user.name;
            email = cfg.user.email;
          };
        };
      };
    };
  }
