{
  config,
  pkgs,
  lib,
  ...
}:
let
  _mod = "dunst";

  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) nullOr attrs raw;
  inherit (lib.lists) any elem;
in
{
  options.DOTS.apps.${_mod} = with config.DOTS.apps."${_mod}"; {

    enable = mkEnableOption "${_mod}";

    package = mkPackageOption pkgs "${_mod}" { };

    export = mkOption {
      default = with _cfg; if enable then { inherit enable package; } else { };
      type = attrs;
    };
  };
}
