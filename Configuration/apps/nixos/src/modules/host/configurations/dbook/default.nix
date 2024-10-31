{ config, pkgs, ... }:
let
  #| Top-level Imports
  inherit (pkgs) lib;
in
{
  config.DOTS.Hosts.dbook = {
    machine = "chromebook";
    processor = {
      cpu = "intel";
      arch = "x86_64-linux";
      mode = "performance";
      gpu = "intel";
    };
    people = [
      {
        name = "craole";
        isElevated = true;
      }
      {
        name = "qyatt";
        isElevated = false;
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
        modules = [ "kvm-intel" ];
        packages = pkgs.linuxPackages_latest;
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

    networking = {
      id = "105D9A39";
      interfaces.wlp2s0.useDHCP = true;
    };
  };
}
