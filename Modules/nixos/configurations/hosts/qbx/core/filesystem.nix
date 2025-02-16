{
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/054d14c9-33c7-4fd3-8092-c9efd260e677";
      fsType = "btrfs";
      options = ["subvol=@"];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/C6C0-2B64";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [];
}
