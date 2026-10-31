# Legend:  #>  command to get the value    #?  explanation
let
  arch = "x86_64"; #> uname -m
  os = "linux"; #> uname -s | tr A-Z a-z
  admin = "craole"; #? Primary admin user
in {
  imports = [./hardware-configuration.nix ./ai];

  stateVersion = "25.05"; #? Release first installed; don't bump on upgrades
  class = "nixos";
  system = "${arch}-${os}"; #> nix eval --impure --expr builtins.currentSystem
  type = "laptop"; #> cat /sys/class/dmi/id/chassis_type  #? (8/9/10/14 = laptop, 3/4/6/7 = desktop, 23 = server)
  id = "d2c1db8e"; #> head -c8 /etc/machine-id
  description = "Victus by HP Gaming 15-fb1013dx"; #? Free text; model number is on the underside label
  vendor = "HP"; #> cat /sys/class/dmi/id/sys_vendor
  product = "Victus by HP Gaming Laptop 15-fb1xxx"; #> cat /sys/class/dmi/id/product_name
  sku = "845A2UA#ABA"; #> cat /sys/class/dmi/id/product_sku

  cpu = {
    inherit arch;
    brand = "amd"; #> lscpu | grep 'Vendor ID'  #? (AuthenticAMD -> amd, GenuineIntel -> intel)
    name = "Ryzen 5 7535HS"; #> lscpu | grep 'Model name'
    family = 25; #> lscpu | grep 'CPU family'
    model = 68; #> lscpu | grep -E '^\s*Model:'
    microarch = "znver3"; #> gcc -march=native -Q --help=target | grep -E '^\s*-march=\s'
    x86_64_level = "v3"; #> /lib64/ld-linux-x86-64.so.2 --help | awk '/supported/ { sub(/.*-v/, "v", $1); print $1; exit }'
    powerMode = "performance"; #? "performance" | "powersave" | "schedutil" ...
    cores = 6; #> lscpu | grep 'Core(s) per socket' #? physical
    threads = 12; #> nproc #? logical
  };

  gpu = {
    mode = "hybrid"; #? "offload" | "sync" | "reverse-sync" | "primary-nvidia" ...
  };

  paths = {
    roots.repo = "/home/${admin}/.dots";
    stems.repo = {
      # wallpapers = "/home/${admin}/.dots/Assets/Images/wallpaper";
    };
  };

  # Podman 5.8.6 reproduces SQLite state-save failures even with a fresh,
  # Hindsight-only graphroot on Victus. Run Hindsight directly with pg0 and
  # keep the existing Podman state/volume untouched for later migration.
  shells = {
    ai = {
      # Victus runs the persistent local 9Router and Headroom services. Keep
      # OmniRoute available as an explicit diagnostic/compatibility preset, but
      # make `nix develop .#Victus-ai` match the normal runtime path.
      defaultPreset = "hermes-hindsight-headroom-9router";
      hindsight.runtime = "native";
    };
  };

  caches = {
    nyx = {
      sub = "https://nyx-cache.chaotic.cx/";
      key = "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk=";
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
    gpu = [
      # First entry = primary (the GPU driving the display).
      #> lspci | grep -Ei 'vga|3d|display'
      #? busId: lspci prints hex "06:00.0"; NixOS wants decimal "PCI:6:0:0" (0a -> 10, 0e -> 14)
      {
        brand = "amd";
        busId = "PCI:6:0:0";
        model = "Radeon 680M";
      }
      {
        brand = "nvidia";
        busId = "PCI:1:0:0";
        model = "RTX 2050";
      }
    ];
    storage = {
      boot = {
        "luks-03a38b8f-5279-4c0f-9172-a7878fbcc92d" = {
          device = "/dev/disk/by-uuid/03a38b8f-5279-4c0f-9172-a7878fbcc92d";
        };
      };

      mounts = {
        "/" = {
          device = "/dev/disk/by-uuid/6494d9f3-9b6b-43ee-b0c9-6abeec96bf38";
          fsType = "ext4";
        };
        "/boot" = {
          device = "/dev/disk/by-uuid/3C12-4AC5";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };
      };

      swap = [
        {device = "/dev/disk/by-uuid/d9e04286-b70c-4c8a-8691-a9a9cbcf57fe";}
      ];
    };

    network = [
      "eno1"
      "wlo1"
    ];

    display = {
      "eDP-1" = {
        brand = "AUO";
        resolution = "1920x1080";
        refreshRate = 144;
        scale = 1;
        position = "0x0";
        size = 15.6;
        priority = 0;
      };

      "HDMI-A-1" = {
        brand = "ACER";
        resolution = "1920x1080";
        refreshRate = 100;
        scale = 1;
        position = "0x1080";
        # transform = 3;
        size = 24.5;
        priority = 2;
      };
    };
  };

  locale = {
    latitude = 18.015;
    longitude = -77.49;
    city = "Mandeville, Jamaica";
    # locator = "geoclue2";
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
    # "touchpad" # Currently not functional
    "tpm"
    "video"
    "virtualization"
    "vpn"
    "webcam"
    "wired"
    "wireless"
  ];

  access = {
    ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuAgYKymJKvky9sAhU0wjHPHbGt+Hg0KLOTIYjoZ9tw root@nixos";
    # age = "age1j5cug724x386nygk8dhc38tujhzhp9nyzyelzl0yaz3ndgtq3qwqxtkfpv";

    remote = {
      ssh = {
        enable = true;
        keyOnly = true;
      };
      tailscale = {
        enable = true;
        firewall = {
          tcp.ranges = [
            {
              from = 1714;
              to = 1764;
            }
          ]; #? KDE Connect
          udp.ranges = [
            {
              from = 1714;
              to = 1764;
            }
          ]; #? KDE Connect
        };
      };
      guacamole = {
        enable = true;
        desktopUser = admin;
        username = admin;
        passwordHash = "6a3ec540d97df7547b694a1d8ec5b332";
      };
      caddy.enable = false;
    };
    firewall = {
      # enable = true;
      tcp = {
        ranges = [];
        ports = [
          22
          80
          443
          1678
          1876
        ];
      };
      udp = {
        ranges = [];
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

  interface = {
    boot = {
      loader = "limine";
      # loader = "systemd-boot";
      timeout = 1;
    };
    desktops = [
      "plasma"
    ];
    theme = {};
    fonts = {};
    keyboard = {};
  };

  principals = [
    {
      name = admin;
      uid = 1000;
      enable = true;
      autoLogin = true;
      role = "administrator";
      packages.communication = ["thunderbird" "khal"];
      interface.dms.settings.calendarBackend = "dankcal";
      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINID8HtFjIBwVad7rhVzOAyouDQxotr+xsE/4PyhZEqR theoracle"
      ];
    }
    {
      name = "cc";
      enable = false;
      autoLogin = false;
      role = "service";
    }
    {
      name = "qyatt";
      enable = false;
      autoLogin = false;
      role = "guest";
    }
  ];

  packages = {
    ai-agent = ["codex" "ollama"];
    bar = [];
    browser = [];
    editor = ["nano"];
    explorer = ["yazi"];
    shell = ["bash"];
    coding = ["nix"];
    extra = [];
    media = ["mpv" "ffmpeg" "imv"];
    ide = [];
    kernel = "cachyos";
    launcher = [];
    prompt = ["starship"];
    terminal = ["ghostty"];
  };
}
