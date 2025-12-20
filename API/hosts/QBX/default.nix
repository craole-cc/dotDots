let
  arch = "x86_64";
  os = "linux";
in {
  imports = [./hardware.nix];

  stateVersion = "25.11";
  platform = "${arch}-${os}";
  id = "cfd69003";

  paths = {
    dots = "/home/craole/.dots";
  };

  packages = {
    allowUnfree = true;
    kernel = "linuxPackages_latest";
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

  users = {
    craole = {
      enable = true;
      role = "administrator";
      autoLogin = true;
    };
    cc = {
      enable = false;
      role = "service";
    };
    qyatt = {
      enable = false;
      autoLogin = false;
      role = "guest";
    };
  };

  interface = {
    bootLoader = "systemd-boot";
    bootLoaderTimeout = 1;
    desktopEnvironment = "gnome";
  };

  niri = {
    enable = true;
    settings = {
      layout = {
        gaps = 20;
        border.width = 3;
        border.active.color = "#89b4fa";
        border.inactive.color = "#45475a";
      };

      binds = {
        "Mod+Return".action = "spawn footclient";
        "Mod+Shift+Return".action = "spawn footclient";
        "Mod+D".action = "spawn fuzzel";
        "Mod+Q".action = "close-window";
        "Mod+1".action = "focus-workspace 1";
        "Mod+2".action = "focus-workspace 2";
      };
    };
  };
}
