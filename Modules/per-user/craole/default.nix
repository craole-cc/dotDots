{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
in {
  imports = [./modules ./templates];
  options.zfs-root.Home.craole.enable = mkOption {
    description = "enable craole options with desktop";
    type = types.bool;
    default = false;
  };
  config = {};
}
