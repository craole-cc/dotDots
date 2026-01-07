let
  arch = "x86_64";
  os = "linux";
in {
  imports = [./hardware-configuration.nix];

  stateVersion = "25.11";
  system = "${arch}-${os}";
  class = "nixos";
  id = "cfd69003";

  paths = {
    dots = "/home/craole/.dots";
    wallpapers = "/home/craole/.dots/Assets/Images/wallpaper";
  };

  packages = {
    unstable = true;
    allowUnfree = true;
    kernel = "linuxPackages_cachyos-sched-ext";
  };

  specs = {
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

  modules = [
    "nvme"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];

  devices = {
    boot = {
    };

    file = {
      "/" = {
        device = "/dev/disk/by-uuid/1f5ca117-cd68-439b-8414-b3b39bc28d75";
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/C6C0-2B64";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };
    };

    swap = [];

    network = ["enp9s0" "wlp8s0"];

    display = {
      "HDMI-A-3" = {
        brand = "KTC";
        resolution = "2560x1440";
        refreshRate = 100;
        scale = 1;
        position = "1080x900";
        size = 27.0;
        priority = 0; #? Primary (lowest number = highest priority)
      };

      "DP-3" = {
        brand = "DELL";
        resolution = "1600x900";
        refreshRate = 60;
        scale = 1;
        position = "1080x0";
        size = 19.4;
        priority = 1;
      };

      "HDMI-A-2" = {
        brand = "ACER";
        resolution = "1920x1080";
        refreshRate = 100;
        scale = 1;
        position = "0x420";
        transform = 3;
        size = 24.5;
        priority = 2;
      };
    };
  };

  localization = {
    latitude = 18.015;
    longitude = 77.49;
    city = "Mandeville, Jamaica";
    locator = "geoclue2";
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
    "touchpad"
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
      enable = false; # TODO: Enable firewall after testing
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
      enable = true;
      autoLogin = true;
      role = "administrator";
    }
    {
      name = "cc";
      enable = true;
      autoLogin = false;
      role = "service";
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
