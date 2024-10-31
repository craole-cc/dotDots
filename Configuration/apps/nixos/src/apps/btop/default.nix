{
  config,
  pkgs,
  lib,
  ...
}:
let
  _mod = "btop";

  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) nullOr attrs raw;
  inherit (lib.lists) any elem;
in
{
  options.DOTS.apps.${_mod} = with config.DOTS.apps."${_mod}"; {

    enable = mkEnableOption "${_mod}";

    package = mkPackageOption pkgs "${_mod}" { };

    export = mkOption {
      default = {
        inherit enable package;
      };
      type = attrs;
    };
  };
}
