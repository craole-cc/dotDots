{
  config,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "programs";
    mod = "direnv";
  };
  inherit (context) cfg mod;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkOption mkTrue mkType;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkTrue mod;
      silent = mkTrue "silent mode";
      dotenv = mkTrue "load .env files";
      format = mkOption {
        description = "log format string";
        default = "-";
        type = mkType "str";
      };
      filter = mkOption {
        description = "log filter regex";
        default = "^$";
        type = mkType "str";
      };
    };
    outputs = {
      programs.${mod} = {
        inherit (cfg) enable silent;
        settings.global = {
          log_format = cfg.format;
          log_filter = cfg.filter;
          load_dotenv = cfg.dotenv;
        };
      };
    };
  }
