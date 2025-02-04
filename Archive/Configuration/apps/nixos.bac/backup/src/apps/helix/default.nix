{
  config,
  pkgs,
  lib,
  ...
}:
let
  _mod = "helix";

  # inherit (lib.types) nullOr attrs raw;
  # inherit (lib.lists) any elem;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
in
{
  options.DOTS.apps.${_mod} = with config.DOTS.apps."${_mod}"; {

    enable = mkEnableOption "Helix Text Editor";

    package = mkPackageOption pkgs "${_mod}" { };

    editor = {
      primary = mkEnableOption "Set as the primary editor" // {
        default = true;
      };

      secondary = mkEnableOption "Set as the secondary editor";
    };

    defaultEditor = mkEnableOption "set as the default editor" // {
      default = isPrimary;
    };

    bindings = mkOption { default = import ./bindings.nix; };
    languages = mkOption { default = import ./languages.nix; };
    settings = mkOption { default = import ./settings.nix; };
    theme = mkOption { default = import ./theme.nix; };

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
}
