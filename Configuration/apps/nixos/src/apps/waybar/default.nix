{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:
let
  _mod = "waybar";
in
{

  options = _args: {
    "${_mod}" =
      let
        _cfg = _args.user;
        _opt = _cfg.applications."${_mod}";
        inherit (lib.options) mkOption mkEnableOption mkPackageOption;
      in
      {

        enable = mkEnableOption "${_mod}" // {
          default = !_cfg.isMinimal;
        };

        package = mkPackageOption pkgs "${_mod}" { };

        export = mkOption { default = with _opt; if enable then { inherit enable package; } else { }; };
      };
  };
}
