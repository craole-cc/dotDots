{ ARGS, ... }:
let
  inherit (ARGS) pkgs lib USER;

  _mod = "dunst";
  _top = USER.apps;
  _cfg = _top."${_mod}";

  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) nullOr attrs str;
  inherit (lib.lists) any elem;
in
{
  enable = mkEnableOption "Git" // {
    default =
      let
        isRequired = with USER; context != null && any (_name: elem _name [ "development" ]) context;
        isRequested = userName != null && userEmail != null;
      in
      isRequested || isRequired;
  };

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
  lfs.enable = mkOption { default = _cfg.enable; };
  package = mkPackageOption pkgs "gitFull" { };
  signing = null;
  userEmail = mkOption { default = _cfg.email; };
  userName = mkOption { default = _cfg.name; };

  export = mkOption {
    default =
      with _cfg;
      if enable then
        {
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
        }
      else
        { };
    type = attrs;
  };
}
