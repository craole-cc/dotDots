{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.zfs-root.per-user.craole.modules.tablet;
  inherit (lib) mkDefault mkOption types mkIf;
in {
  options.zfs-root.per-user.craole.modules.tablet.enable = mkOption {
    type = types.bool;
    default = config.zfs-root.per-user.craole.enable;
  };
  config = mkIf cfg.enable {
    environment.systemPackages =
      builtins.attrValues {inherit (pkgs) xournalpp;};
  };
}
