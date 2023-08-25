{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.zfs-root.Home.craole.modules.virt;
  inherit (lib) mkDefault mkOption types mkIf;
in {
  options.zfs-root.Home.craole.modules.virt.enable = mkOption {
    type = types.bool;
    default = config.zfs-root.Home.craole.enable;
  };
  config = mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;
      };
    };
    environment.systemPackages =
      builtins.attrValues {inherit (pkgs) virt-manager;};
  };
}
