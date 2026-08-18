{
  config,
  lix,
  ...
}: let
  inherit (config.programs) git;

  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.combinators) nullOr;
  inherit (lix.types.primitives) str;

  context = mkContext {
    inherit config;
    dom = "version-control";
    sub = "core";
    mod = "jujutsu";
  };
  inherit (context) cfg;
in
  mkConfig {
    inherit context;

    options = {
      enable = mkEnable {inherit context;};

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
        # inherit (cfg) enable;
        settings.user = {
          name = cfg.user.name;
          email = cfg.user.email;
        };
      };
    };
  }
