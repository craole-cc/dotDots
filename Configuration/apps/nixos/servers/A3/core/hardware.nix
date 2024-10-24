{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  fileSystems = {
    "/boot/efi" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
    };

    "/" = {
      device = "/dev/disk/by-uuid/1b7438a3-8b36-4344-b767-4a254240657d";
      fsType = "ext4";
    };

    "/data" = {
      device = "/dev/disk/by-label/DATA";
      fsType = "ext4";
      # options = [
      #   "defaults"
      #   "uid=1000,gid=1000"
      #   "nofail"
      # ];
    };

    # "/home/craole/Shared" = {
    #   device = "/dev/disk/by-label/STORE";
    #   fsType = "exfat";
    #   options = [
    #     "defaults"
    #     "uid=$(id -u)"
    #     "gid=$(id -g)"
    #     "dmask=027"
    #     "fmask=137"
    #     "nofail"
    #   ];
    # };

    # "/home/craole/Shared" = {
    #   "/shared" = {
    #     device = "/dev/disk/by-label/STORE";
    #     fsType = "exfat";
    #     options = [
    #       "defaults"
    #       "uid=1000,gid=100,dmask=027,fmask=137"
    #       # "uid=1000,gid=1000,dmask=027,fmask=137"
    #       "nofail"
    #     ];
    #   };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = ["kvm-amd"];
    initrd = {
      availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
      kernelModules = [];
      luks.devices."luks-20c6c296-a0a7-4d38-b656-fa8534db75ad".device = "/dev/disk/by-uuid/20c6c296-a0a7-4d38-b656-fa8534db75ad";
      secrets = {"/crypto_keyfile.bin" = null;};
    };
    extraModulePackages = [];
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
      systemd-boot.enable = true;
      # grub = {
      #   enable = true;
      #   version = 2;
      #   devices = [ "nodev" ];
      #   efiSupport = true;
      #   useOSProber = true; # Find all boot options
      #   configurationLimit = 2;
      #   enableCryptodisk = true;
      #   theme = pkgs.nixos-grub2-theme;
      # };
      timeout = 1; # Grub auto select time
    };
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
