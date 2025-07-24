# {
#   #TODO: use the flake inputs overlay
#   config,
#   lib,
#   inputs,
#   system,
#   ...
# }:
# let
#   inherit (lib.options) mkEnableOption mkOption;
#   inherit (lib.modules) mkIf;
#   inherit (lib.types) enum;
#   cfg = config.programs.zen-browser;
# in
# {
#   options.programs.zen-browser = {
#     enable = mkEnableOption "Zen Browser";
#     version = mkOption {
#       default = "twilight";
#       description = "The version of Zen Browser to install.";
#       type = enum [
#         "beta"
#         "twilight"
#         "default"
#         "twilight-official"
#       ];
#     };
#   };
#   config = mkIf cfg.enable {
#     home.packages = [ inputs.zen-browser.packages."${system}"."${cfg.version}" ];
#   };
# }
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) enum;
  cfg = config.programs.zen-browser;
in {
  options.programs.zen-browser = {
    enable = mkEnableOption "Zen Browser";
    version = mkOption {
      type = enum ["beta" "twilight" "default" "twilight-official"];
      default = "twilight";
      description = "The version of Zen Browser to install.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.inputs.zen-browser.${cfg.version}];
  };
}
