{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.zfs-root.Home.craole.modules.tablet;
  inherit (lib) mkDefault mkOption types mkIf;
in {
  options.zfs-root.Home.craole.modules.tablet.enable = mkOption {
    type = types.bool;
    default = config.zfs-root.Home.craole.enable;
  };
  config = mkIf cfg.enable {
    environment.systemPackages =
      builtins.attrValues {inherit (pkgs) xournalpp;};
  };
}
