{ config, lib, ... }:
{
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "usb_storage"
        "sd_mod"
        "sr_mod"
        "sdhci_pci"
      ];
      kernelModules = [ ];
      luks.devices = {
        "luks-d6bafe54-e55b-49b8-ab7c-18380939f56f" = {
          device = "/dev/disk/by-uuid/d6bafe54-e55b-49b8-ab7c-18380939f56f";
        };
        "luks-540965a0-c573-42f9-8d14-2ae37c3715e6" = {
          device = "/dev/disk/by-uuid/540965a0-c573-42f9-8d14-2ae37c3715e6";
        };
      };
    };

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

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

  swapDevices = [
    { device = "/dev/disk/by-uuid/d1aa80d2-ba1f-412f-9d81-5c5f5c6a839d"; }
  ];

  networking = {
    hostId = "2d8e6e4e";
    hostName = "preci";
    interfaces = {
      eno1.useDHCP = lib.mkDefault true;
      wlp3s0.useDHCP = lib.mkDefault true;
    };

    firewall = {
      enable = false;
      # allowedTCPPorts = [ ... ];
      # allowedUDPPorts = [ ... ];
    };
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
  };

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
