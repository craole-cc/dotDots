{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = [ ];
  };

  fileSystems = {
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

  swapDevices = [ ];

  networking = {
    useDHCP = lib.mkDefault true;
    interfaces.wlp2s0.useDHCP = lib.mkDefault true;
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    bluetooth.enable = true;
  };

  sound.enable = true;
}
