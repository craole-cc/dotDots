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
    # wallpapers = "/home/craole/.dots/Assets/Images/wallpaper";
  };

  packages = {
    unstable = true;
    allowUnfree = true;
    kernel = "linuxPackages_cachyos-lto";
  };

  caches = {
    nyx = {
      sub = "https://geo-mirror.chaotic.cx/";
      key = "nyx.chaotic.cx-1:CNZOSlPJO5F0utqsPzkZbHkkD7YzNDWHGG6PqS30wMc=";
    };
  };

  specs = {
    machine = "desktop";

    cpu = {
      inherit arch;
      brand = "amd"; # TODO: Change this to allow multiple
      powerMode = "performance";
      cores = 12;
    };

    gpu = {
      # Monitors are wired to the NVIDIA card (card0, PCI:1:0:0).
      # AMD iGPU (card1, PCI:12:0:0) drives the optional 3rd monitor via motherboard.
      # reverseSync: AMD is the Wayland render node; NVIDIA outputs are PRIME-linked to it.
      primary = {
        brand = "amd";
        busId = "PCI:12:0:0"; # 0c:00.0 → 12 decimal
        model = "Granite Ridge Radeon Graphics";
      };
      secondary = {
        brand = "nvidia";
        busId = "PCI:1:0:0"; # 01:00.0 - confirmed by lspci
        model = "GTX 1050 Ti"; # EVGA GP107, subsystem 3842:6253
      };
      mode = "reverse-sync"; # AMD renders; NVIDIA outputs sync through PRIME
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
    boot = {};

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
      "/mnt/Storage" = {
        device = "/dev/disk/by-uuid/01DBCFFA6ABD5C10";
        fsType = "ntfs3";
        options = [
          "uid=1000"
          "gid=1000"
          "umask=022"
          "prealloc"
          "nofail"
          "x-systemd.automount"
          "x-systemd.idle-timeout=60"
        ];
      };
    };

    swap = [];

    network = [
      "enp9s0"
      "wlp8s0"
    ];

    display = {
      "HDMI-A-3" = {
        brand = "KTC";
        resolution = "2560x1440";
        refreshRate = 100;
        scale = 1;
        # Centered below DP-3: (2560 - 1600) / 2 = 480 → x=480; y=900 (below 900px tall DP-3)
        position = "480x900";
        size = 27.0;
        priority = 0; # Primary
      };

      "DP-3" = {
        brand = "DELL";
        resolution = "1600x900";
        refreshRate = 60;
        scale = 1;
        # Centered above HDMI-A-3: (2560 - 1600) / 2 = 480
        position = "480x0";
        size = 19.4;
        priority = 1;
      };

      # Optional 3rd monitor - motherboard HDMI (AMD iGPU, card1-HDMI-A-2)
      # "HDMI-A-2" = {
      #   brand = "ACER";
      #   resolution = "1920x1080";
      #   refreshRate = 100;
      #   scale = 1;
      #   position = "0x420";
      #   transform = 3; # 270° rotation
      #   size = 24.5;
      #   priority = 2;
      # };
    };
  };

  localization = {
    latitude = 18.015;
    longitude = -77.49;
    city = "Mandeville, Jamaica";
    locator = "geoclue2";
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

  access = {
    ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMNDko91cBLITGetT4wRmV1ihq9c/L20sUSLPxbfI0vE root@victus";
    age = "age1j5cug724x386nygk8dhc38tujhzhp9nyzyelzl0yaz3ndgtq3qwqxtkfpv";

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

    vpn = {
      configFile = "/etc/openvpn/protonvpn-us.ovpn";
      #? Apps routed through the VPN namespace
      apps = [
        "freetube"
        "chromium"
      ];
    };
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
    # displayManager = "regreet";
    # desktopEnvironment = null;
    windowManager = "hyprland";
    # displayProtocol = "wayland";
    keyboard = {
      modifier = "SUPER";
      swapCapsEscape = false;
    };
  };
}
