{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      luks.devices = {
        "luks-ef5cc76c-aa34-460b-beb8-a2ea4f99889d".device = "/dev/disk/by-uuid/ef5cc76c-aa34-460b-beb8-a2ea4f99889d";
        "luks-858f4df3-a2dd-4a10-bf57-01694195250e".device = "/dev/disk/by-uuid/858f4df3-a2dd-4a10-bf57-01694195250e";
      };
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
      device = "/dev/disk/by-uuid/4f7188d1-48ec-475d-87bb-f9547cbb253b";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/F4C7-66A5";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/cdb83eba-7128-46ba-b194-d834925e162a"; }
  ];

  networking = {
    hostId = "0ab86678";
    hostName = "dbook";
    networkmanager.enable = true;
    interfaces.wlp2s0.useDHCP = lib.mkDefault true;
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    bluetooth = {
      enable = true;
      settings.General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
    pulseaudio.enable = false;
  };

  powerManagement = {
    cpuFreqGovernor = lib.mkDefault "performance";
  };

  system = {
    stateVersion = "24.05";
  };
}
