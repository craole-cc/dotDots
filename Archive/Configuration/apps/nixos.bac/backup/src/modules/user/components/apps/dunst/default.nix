{ ARGS, ... }:
let
  inherit (ARGS) pkgs lib USER;

  _mod = "dunst";
  _top = USER.apps;
  _cfg = _top."${_mod}";

  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) attrs;
  inherit (lib.lists) any elem;

  inherit (USER) isMinimal;
in
{
  enable = mkEnableOption "${_mod}" // {
    default = !isMinimal;
  };

  package = mkPackageOption pkgs "${_mod}" { };

  export = mkOption {
    default = with _cfg; if enable then { inherit enable package; } else { };
    type = attrs;
  };
}
