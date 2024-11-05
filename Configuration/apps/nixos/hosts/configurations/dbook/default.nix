{
  config,
  lib,
  pkgs,
  ...
}:
let
  base = "hosts";
  mod = "dbook";
in
{
  DOTS.${base}.${mod} = {
    id = "105D9A39";
    base = "chromebook";
    processor = {
      cpu = "intel";
      arch = "x86_64-linux";
      gpu = "intel";
    };
    people = [
      {
        name = "craole";
        isElevated = true;
      }
    ];
    boot = {
      kernel = {
        initrd = [
          "xhci_pci"
          "usb_storage"
          "sd_mod"
          "sdhci_pci"
        ];
      };
    };

    mount = {
      fileSystem = {
        "/" = {
          device = "/dev/disk/by-uuid/4bf4df16-e0b4-4210-8e2a-1272ef20b7d8";
          fsType = "ext4";
        };

        "/boot" = {
          device = "/dev/disk/by-uuid/2551-B8D5";
          fsType = "vfat";
        };

        "/dots" = {
          device = "/dev/disk/by-uuid/20263af3-1807-4c94-bdbe-51637ca810e1";
          fsType = "ext4";
        };
      };

      swap = [ ];
    };

    devices = {
      network = [ wlp2s0 ];
    };
  };
}
