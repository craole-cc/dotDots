{
  config,
  lib,
  modulesPath,
  ...
}: let
  inherit (lib.modules) mkDefault;
in {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      luks.devices."luks-03a38b8f-5279-4c0f-9172-a7878fbcc92d".device = "/dev/disk/by-uuid/03a38b8f-5279-4c0f-9172-a7878fbcc92d";
      kernelModules = [];
    };
    kernelModules = ["kvm-amd"];
    extraModulePackages = [];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/6494d9f3-9b6b-43ee-b0c9-6abeec96bf38";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/3C12-4AC5";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [];

  networking = {
    networkmanager.enable = true;
    interfaces = {
      eno1.useDHCP = mkDefault true;
      wlo1.useDHCP = mkDefault true;
    };
  };

  nixpkgs.hostPlatform = mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
}
