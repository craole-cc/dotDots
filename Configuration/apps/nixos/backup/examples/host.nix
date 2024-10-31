{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  config = {
    dots.hosts.nixos = {
      id = "105d9a39";
      machine = "laptop";
      cpu = "intel";
      platform = "x86_64-linux";
      context = [
        "development"
        "entertainment"
      ];
      users = [
        "user1"
        "user2"
      ];
      interface = {
        desktop.manager = "hyprland";
        login.autoLogin = true;
      };
    };

    boot = {
      initrd.availableKernelModules = [
        "xhci_pci"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
      ];
      kernelModules = [ "kvm-intel" ];
      kernelPackages = pkgs.linuxPackages_latest;
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
    };

    networking = {
      interfaces.wlp2s0.useDHCP = mkDefault true;
    };
  };
}
