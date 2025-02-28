{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  config = {
    dot.hosts.delle = {
      machine = "laptop";
      cpu = "intel";
      # context = [
      #   "development"
      #   # "entertainment"
      #   "remote"
      # ];

      extraConfig = {
        boot = {
          initrd.availableKernelModules = [
            "xhci_pci"
            "ehci_pci"
            "ahci"
            "usbhid"
            "usb_storage"
            "sd_mod"
            "sr_mod"
            "sdhci_pci"
          ];
          kernelModules = [ "kvm-intel" ];
          kernelPackages = pkgs.linuxPackages_latest;
        };

        fileSystems = {
          "/" = {
            device = "/dev/disk/by-uuid/e887045d-f7a8-4064-b463-71544ad82a2d";
            fsType = "btrfs";
            options = [ "subvol=@" ];
          };

          "/boot" = {
            device = "/dev/disk/by-uuid/0C4E-25E1";
            fsType = "vfat";
          };
        };

        swapDevices = [ { device = "/dev/disk/by-uuid/2eff8f3f-3920-4aec-ac15-7fe659123ba5"; } ];

        networking = {
          useDHCP = mkDefault true;
          interfaces = {
            eno1.useDHCP = mkDefault true;
            wlp2s0.useDHCP = mkDefault true;
          };
        };
      };
    };
  };
}
