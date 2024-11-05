{
  config,
  lib,
  pkgs,
  ...
}:
let
  base = "hosts";
  mod = "preci";
in
{
  DOTS.${base}.${mod} = {
    id = "8f792eed";
    base = "laptop";
    stateVersion = "24.05";
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
          "ehci_pci"
          "ahci"
          "usb_storage"
          "sd_mod"
          "sr_mod"
          "sdhci_pci"
        ];
        # modules = [ "kvm-intel" ];
        # packages = pkgs.linuxPackages_latest;
      };
    };
    mount = {
      fileSystems = {
        "/" = {
          device = "/dev/disk/by-uuid/5fe83d0f-15a3-4abf-abb2-2ba02cc9195d";
          fsType = "ext4";
        };
        "/boot" = {
          device = "/dev/disk/by-uuid/542E-33C1";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };
      };

      swap = [
        { device = "/dev/disk/by-uuid/d1aa80d2-ba1f-412f-9d81-5c5f5c6a839d"; }
      ];
    };
    devices = {
      luks = {
        "luks-d6bafe54-e55b-49b8-ab7c-18380939f56f" = {
          device = "/dev/disk/by-uuid/d6bafe54-e55b-49b8-ab7c-18380939f56f";
        };
        "luks-540965a0-c573-42f9-8d14-2ae37c3715e6" = {
          device = "/dev/disk/by-uuid/540965a0-c573-42f9-8d14-2ae37c3715e6";
        };
      };

      network = [
        "eno1"
        "wlp3s0"
      ];
    };
  };
}
