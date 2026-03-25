{
  config,
  lix,
  top,
  ...
}: let
  dom = "programs";
  mod = "direnv";
  cfg = config.${top}.${dom}.${mod};
  inherit (lix.options) mkTrue mkOption mkIf toOptionType;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkTrue mod;
    silent = mkTrue "silent mode";
    loadDotenv = mkTrue "load .env files";
    format = mkOption {
      type = toOptionType "str";
      default = "-";
      description = "log format string";
    };
    filter = mkOption {
      type = toOptionType "str";
      default = "^$";
      description = "log filter regex";
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
