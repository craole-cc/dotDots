{
  #TODO: use the flake inputs overlay
  config,
  lib,
  inputs,
  system,
  ...
}:

let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) oneOf;
  cfg = config.programs.zen-browser;
  version = "twilight";
in
{
  options.programs.zen-browser = {
    enable = mkEnableOption "Zen Browser";
    version = mkOption {
      default = "twilight";
      description = "The version of Zen Browser to install.";
      type = oneOf [
        "beta"
        "twilight"
        "default"
        "twilight-official"
      ];
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.zen-browser.packages."${system}"."${cfg.version}" ];
  };
}
