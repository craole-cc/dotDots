{
  config,
  pkgs,
  lib,
  ...
}:
let
  _mod = "bat";

  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) nullOr attrs raw;
  inherit (lib.lists) any elem;
in
{
  options.DOTS.apps.${_mod} = with config.DOTS.apps."${_mod}"; {

    enable = mkEnableOption "${_mod}";

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
      default = {
        inherit
          enable
          package
          config
          themes
          syntaxes
          ;
      };
      type = attrs;
    };
  };
}
