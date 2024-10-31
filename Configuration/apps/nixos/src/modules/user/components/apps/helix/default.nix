{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:
let
  _mod = "helix";
in
{

  options = _args: {
    "${_mod}" =
      let
        _cfg = _args.user;
        _opt = _cfg.applications."${_mod}";
        inherit (lib.options) mkOption mkEnableOption mkPackageOption;
        inherit (lib.lists) any elem;
        inherit (lib.types) nullOr str;
      in
      {

        enable = mkEnableOption "Helix Text Editor" // {
          default =
            _cfg.context != null
            && any (
              _name:
              elem _name [
                "minimal"
                "development"
              ]
            ) _cfg.context;
        };

        defaultEditor = mkEnableOption "set as the default editor" // {
          default = _opt.enable;
        };

        bindings = mkOption { default = import ./bindings.nix; };
        languages = mkOption { default = import ./languages.nix; };
        settings = mkOption { default = import ./settings.nix; };
        theme = mkOption { default = import ./theme.nix { inherit (_args) user; }; };

        export = mkOption {
          default =
            with _opt;
            if enable then
              {
                inherit enable defaultEditor languages;
                settings = {
                  editor = settings;
                  keys = bindings;
                };
              }
            else
              { };
        };
      };
  };
}
