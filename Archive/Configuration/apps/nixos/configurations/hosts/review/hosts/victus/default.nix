let
  base = "hosts";
  mod = "preci";
in
{
  DOTS.${base}.${mod} = {
    id = "444CC9B3";
    machine = "laptop";
    cpu = "amd";
    gpu = "nvidia";
    platform = "x86_64-linux";
    interface = {
      desktop.manager = "hyprland";
      login.autoLogin = true;
    };
    # context = [ "everything" ];
    extraConfig = {

      boot = {
        initrd.availableKernelModules = [
          "xhci_pci"
          "usb_storage"
          "sd_mod"
          "sdhci_pci"
        ];
        kernelModules = [ "kvm-intel" ];
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

      devices = {
        network = [ "wlp2s0" ];
      };
    };
  };

}
