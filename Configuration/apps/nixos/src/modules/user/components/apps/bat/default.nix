{ ARGS, ... }:
let
  inherit (ARGS) pkgs lib USER;

  _mod = "bat";
  _top = USER.apps;
  _cfg = _top."${_mod}";

  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) nullOr attrs raw;
  inherit (lib.lists) any elem;

  inherit (USER) context;
in
{
  enable = mkEnableOption "${_mod}" // {
    default = any (
      x:
      elem x [
        "development"
        "minimal"
      ]
    ) context;
  };

  package = mkPackageOption pkgs "${_mod}" { };

  config = mkOption {
    default = {
      pager = "less -FR";
    };
    type = attrs;
  };

  themes = mkOption {
    default = { };
    type = attrs;
  };

  syntaxes = mkOption {
    default = { };
    type = attrs;
  };

  export = mkOption {
    default =
      with _cfg;
      if enable then
        {
          inherit
            enable
            package
            config
            themes
            syntaxes
            ;
        }
      else
        { };
    type = attrs;
  };
}
