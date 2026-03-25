{
  config,
  lix,
  top,
  ...
}: let
  dom = "programs";
  mod = "direnv";
  cfg = config.${top}.${dom}.${mod};
  inherit (lix.types.options) mkTrue mkOption mkIf mkType;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkTrue mod;
    silent = mkTrue "silent mode";
    loadDotenv = mkTrue "load .env files";
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

  config = mkIf cfg.enable {
    programs.${mod} = {
      enable = true;
      silent = cfg.silent;
      settings.global = {
        log_format = cfg.format;
        log_filter = cfg.filter;
        load_dotenv = cfg.loadDotenv;
      };
    };
  };
}
