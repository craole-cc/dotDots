{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:
let
  _mod = "microsoft-edge";
in
{

  options = _args: {
    "${_mod}" =
      let
        _cfg = _args.user;
        _opt = _cfg.applications."${_mod}";
        inherit (lib.options) mkOption mkEnableOption mkPackageOption;
        inherit (lib.strings) hasPrefix;
        inherit (_cfg.applications.browser) primary secondary;
        isPrimary = hasPrefix _mod primary.name;
        isSecondary = hasPrefix _mod secondary.name;
      in
      {

        enable = mkEnableOption "${_mod}" // {
          default = isPrimary || isSecondary;
        };

        package = mkOption {
          description = "Package name";
          default =
            if isPrimary then
              primary.package
            else if isSecondary then
              secondary.package
            else
              pkgs.${_mod};
          type = lib.types.package;
        };

        export = mkOption { default = with _opt; if enable then { inherit enable package; } else { }; };
      };
  };
}
