{
  config,
  lib,
  ...
}:
let
  dom = "dots";
  mod = "paths";
  cfg = config.${dom}.${mod};

  inherit (lib.options) mkOption;
  inherit (lib.types) str either path;
in
{
  options.${dom}.${mod} = {
    DOTS = {
      flake = mkOption {
        description = "The path to the dotfiles flake";
        default = "/home/craole/.dots";
        type = either str path;
      };
      mods = mkOption {
        description = "The path to the modules";
        default = cfg.DOTS.flake + "/Modules/nixos";
      };
      hosts = mkOption {
        description = "The path to the host modules";
        default = cfg.DOTS.mods + "/configurations/hosts";
        type = either str path;
      };
    };
    QBXL = {
      flake = mkOption {
        description = "The path to the QBXL flake";
        default = cfg.DOTS.hosts + "/QBXL";
        type = either str path;
      };
    };
  };
}
