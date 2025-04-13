{ config, lib, ... }:
let
  dom = "programs";
  mod = "bat";
  cfg = config."${dom}.${mod}";
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
in
{
  options."${dom}.${mod}" = {
    enable = mkEnableOption "${mod}";
    user = mkOption { default = null; };
    email = mkOption { default = null; };
  };
  config."${dom}.${mod}" = mkIf cfg.enable {
    enable = cfg.enable;
    userName = cfg.user;
    userEmail = cfg.email;
    lfs.enable = true;
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      url = {
        "https://github.com/" = {
          insteadOf = [
            "gh:"
            "github:"
          ];
        };
      };
    };
    includes = [
      # { path = "$RC_git"; }
      # { path = "~/path/to/config.inc"; }
      # {
      #   path = "~/path/to/conditional.inc";
      #   condition = "gitdir:~/src/dir";
      # }
    ];
  };
}
