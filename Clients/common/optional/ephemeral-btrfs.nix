# This file contains an ephemeral btrfs root configuration
# TODO: perhaps partition using disko in the future
{ lib, config, ... }:
let
  hostname = config.networking.hostName;
  wipeScript = ''
    mkdir /tmp -p
    TEMP_MNTPOINT=$(mktemp -d)
    (
      mount -t btrfs -o subvol=/ /dev/disk/by-label/${hostname} "$TEMP_MNTPOINT"
      trap 'umount "$TEMP_MNTPOINT"' EXIT

      echo "Creating needed directories"
      mkdir -p "$TEMP_MNTPOINT"/persist/var/{log,lib/{nixos,systemd}}

      echo "Cleaning root subvolume"
      btrfs subvolume list -o "$TEMP_MNTPOINT/root" | cut -f9 -d ' ' |
      while read -r subvolume; do
        btrfs subvolume delete "$TEMP_MNTPOINT/$subvolume"
      done && btrfs subvolume delete "$TEMP_MNTPOINT/root"

      echo "Restoring blank subvolume"
      btrfs subvolume snapshot "$TEMP_MNTPOINT/root-blank" "$TEMP_MNTPOINT/root"
    )
  '';
  phase1Systemd = config.boot.initrd.systemd.enable;
in
{
  boot.initrd = {
    supportedFilesystems = [ "btrfs" ];
    postDeviceCommands = lib.mkIf (!phase1Systemd) (lib.mkBefore wipeScript);
    systemd.services.restore-root = lib.mkIf phase1Systemd {
      description = "Rollback btrfs rootfs";
      wantedBy = [ "initrd.target" ];
      requires = [
        "dev-disk-by\\x2dlabel-${hostname}.device"
      ];
      after = [
        "dev-disk-by\\x2dlabel-${hostname}.device"
        "systemd-cryptsetup@${hostname}.service"
      ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = wipeScript;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" ];
    };

    "/nix" = {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" "compress=zstd" ];
    };

    "/persist" = {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [ "subvol=persist" "compress=zstd" ];
      neededForBoot = true;
    };

    "/swap" = {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [ "subvol=swap" "noatime" ];
    };
  };

}
