let
  arch = "x86_64";
  os = "linux";
in {
  imports = [./hardware-configuration.nix];

  stateVersion = "25.11";
  system = "${arch}-${os}";
  class = "nixos";
  id = "cfd69003";
  name = "Preci";
  description = "Dell Precision M2800";

  paths.roots.repo = "/home/craole/.dots";

  packages.kernel = "linuxPackages_latest";

  modules = [
    "xhci_pci"
    "ehci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "sr_mod"
    "sdhci_pci"
  ];

  specs = {
    machine = "laptop";
    cpu = {
      inherit arch;
      brand = "intel";
    };
  };

  devices = {
    storage = {
      boot.efiSysMountPoint = "/boot";
      mounts = {
        "/" = {
          device = "/dev/disk/by-uuid/05382bd2-cc99-4717-8343-0c6076d81441";
          fsType = "ext4";
        };
        "/boot" = {
          device = "/dev/disk/by-uuid/1FC3-D0C5";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };
      };
      swap = [{device = "/dev/disk/by-uuid/7cd5b10d-efe9-4279-833c-6482cb6c1474";}];
    };
  };

  localization = {
    latitude = 18.015;
    longitude = -77.49;
    city = "Mandeville, Jamaica";
    timeZone = "America/Jamaica";
    defaultLocale = "en_US.UTF-8";
  };

  functionalities = [
    "audio"
    "battery"
    "bluetooth"
    "dualboot-windows"
    "efi"
    "gpu"
    "keyboard"
    "network"
    "nvme"
    "secureboot"
    "storage"
    "touchpad"
    "tpm"
    "video"
    "virtualization"
    "vpn"
    "webcam"
    "wired"
    "wireless"
  ];

  interface = {
    bootLoader = "systemd-boot";
    bootLoaderTimeout = 1;
  };
}
