{
  config,
  pkgs,
  lib,
  ...
}:
let
  _mod = "git";

  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) nullOr attrs str;
  inherit (lib.lists) any elem;
in
{
  options.DOTS.apps.${_mod} = with config.DOTS.apps."${_mod}"; {

    enable = mkEnableOption "${_mod}" // {
      default = true;
    };

    package = mkPackageOption pkgs "gitFull" { };

    name = mkOption {
      description = "Git username";
      default = null;
      type = nullOr str;
    };

    email = mkOption {
      description = "Git enail";
      default = null;
      type = nullOr str;
    };

    sshKey = mkOption {
      description = "Git ssh key";
      default = null;
      type = nullOr str;
    };

    aliases = mkOption { default = { }; };
    attributes = mkOption { default = [ ]; };
    delta = mkOption { default = { }; };
    diff-so-fancy = mkOption { default = { }; };
    difftastic = mkOption { default = { }; };
    extraConfig = mkOption { default = { }; };
    hooks = mkOption { default = { }; };
    ignores = mkOption { default = [ ]; };
    includes = mkOption { default = [ ]; };
    iniContent = mkOption { default = { }; };
    lfs.enable = mkOption { default = enable; };
    signing = null;
    userEmail = mkOption { default = email; };
    userName = mkOption { default = name; };

    export = mkOption {
      default = {
        inherit
          aliases
          attributes
          delta
          diff-so-fancy
          difftastic
          enable
          extraConfig
          hooks
          ignores
          includes
          iniContent
          lfs
          package
          signing
          userName
          userEmail
          ;
      };
      type = attrs;
    };
  };
}
