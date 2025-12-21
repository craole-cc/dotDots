let
  base = {
    relative = "../../..";
    absolute = "/home/craole/Configuration";
  };
  arch = "x86_64";
  os = "linux";
in {
  imports = [./hardware-configuration.nix];
  modules = [
    "nvme"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];

  stateVersion = "25.05";
  paths = {
    inherit base;
    # binaries = {
    #   relative = base.relative + bin;
    #   absolute = base.absolute + bin;
    # };
  };

  packages = {
    allowUnfree = true;
    # kernel = "linuxPackages_latest";
  };

  specs = {
    platform = "${arch}-${os}";
    machine = "laptop";

    cpu = {
      inherit arch;
      brand = "amd"; # TODO: Change this to allow multiple
      powerMode = "performance";
      cores = 12;
    };

    gpu = {
      # TODO: Change this to not use named attrsets
      primary = {
        brand = "amd";
        busId = "PCI:6:0:0"; # 06:00.0
        model = "Radeon 660M";
      };
      secondary = {
        brand = "nvidia";
        busId = "PCI:1:0:0"; # 01:00.0
        model = "RTX 2050";
      };
      mode = "hybrid"; # or "offload", "sync", "primary-nvidia", etc.
    };
  };

  devices = {
    boot = {
      "luks-03a38b8f-5279-4c0f-9172-a7878fbcc92d" = {
        device = "/dev/disk/by-uuid/03a38b8f-5279-4c0f-9172-a7878fbcc92d";
      };
    };

    file = {
      "/" = {
        device = "/dev/disk/by-uuid/6494d9f3-9b6b-43ee-b0c9-6abeec96bf38";
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/3C12-4AC5";
        fsType = "vfat";
        options = ["fmask=0077" "dmask=0077"];
      };
    };

    swap = [];

    network = ["eno1" "wlo1"];

    display = [
      {
        name = "HDMI-A-1";
        resolution = "1920x1080";
        refreshRate = 75;
        scale = 1;
        position = "0x0";
      }
      {
        name = "eDP-1";
        resolution = "1920x1080";
        refreshRate = 144.15;
        scale = 1;
        position = "auto";
      }
    ];
  };
  localization = {
    latitude = 18.015;
    longitude = 77.49;
    timeZone = "America/Jamaica";
    defaultLocale = "en_US.UTF-8";
  };
  functionalities = [
    "keyboard"
    "storage"
    "network"
    "video"
    "virtualization"
    "audio"
    "bluetooth"
    # "touchpad" # Currently not functional
    "wired"
    "wireless"
    "dualboot-windows"
    "efi"
    "secureboot"
    "tpm"
    "battery"
    "webcam"
    "gpu"
    "nvme"
  ];
  access = {
    # ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMNDko91cBLITGetT4wRmV1ihq9c/L20sUSLPxbfI0vE root@victus";
    # age = "age1j5cug724x386nygk8dhc38tujhzhp9nyzyelzl0yaz3ndgtq3qwqxtkfpv";
    firewall = {
      # enable = true;
      tcp = {
        ranges = [
          {
            from = 49160;
            to = 65534;
          }
        ];
        ports = [
          22
          80
          443
          1678
          1876
        ];
      };
      udp = {
        ranges = [
          {
            from = 49160;
            to = 65534;
          }
        ];
        ports = [];
      };
    };
    nameservers = [
      "1.1.1.1" # Cloudflare DNS
      "1.0.0.1"
    ];
  };

  principals = [
    {
      name = "craole";
      enable = false;
      autoLogin = false;
      # role = "administrator";
    }
    {
      name = "cc";
      enable = false;
      autoLogin = false;
      # role = "admin";
    }
    {
      name = "qyatt";
      enable = false;
      autoLogin = false;
      role = "guest";
    }
  ];

  interface = {
    bootLoader = "systemd-boot";
    bootLoaderTimeout = 1;
    loginManager = "sddm";
    desktopEnvironment = "plasma";
    windowManager = "hyprland";
    displayProtocol = "wayland";
    keyboard = {
      modifier = "SUPER";
      swapCapsEscape = false;
    };
  };
}
