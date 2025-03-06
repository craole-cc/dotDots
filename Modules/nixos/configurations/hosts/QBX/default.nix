{
  platform = "x86_64-linux";
  # id = "1d022da8";
  stateVersion = "24.11";
  base = "desktop";
  cpu = {
    brand = "amd";
    arch = "x86_64";
    mode = "performance";
  };
  gpu = {
    brand = "nvidia";
  };
  boot = {
    modules = [
      "xhci_pci"
      "ehci_pci"
      "ahci"
      "usb_storage"
      "sd_mod"
      "sr_mod"
      "sdhci_pci"
    ];
  };
  devices = {
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/054d14c9-33c7-4fd3-8092-c9efd260e677";
        fsType = "btrfs";
        options = [ "subvol=@" ];
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

    swapDevices = [ ];

    network = [
      "eno1"
      "wlp3s0"
    ];
  };
  desktop = "gnome";
  location = {
    latitude = 18.015;
    longitude = 77.49;
    timeZone = "America/Jamaica";
    defaultLocale = "en_US.UTF-8";
  };
  capabilities = [
    "ai"
    "audio"
    "battery"
    "bluetooth"
    "video"
    "storage"
    "mouse"
    "remote"
    "touchpad"
    "wired"
    "wireless"
  ];
  context = [
    "development"
    "media"
    "productivity"
  ];
  keyboard = {
    modifier = "SUPER_L";
    swapCapsEscape = false;
  };
  access = {
    ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMNDko91cBLITGetT4wRmV1ihq9c/L20sUSLPxbfI0vE root@victus";
    age = "age1j5cug724x386nygk8dhc38tujhzhp9nyzyelzl0yaz3ndgtq3qwqxtkfpv";
    firewall = {
      enable = true;
      tcp = {
        ranges = [
          {
            # Allowing a range for random port selection
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
            # Allowing a range for random port selection
            from = 49160;
            to = 65534;
          }
        ];
        ports = [ ];
      };
    };
    nameservers = [
      "1.1.1.1" # Cloudflare DNS
      "1.0.0.1"
    ];
  };
  people = [
    {
      name = "craole";
      admin = true;
      autoLogin = true;
    }
    {
      name = "cc";
      admin = true;
    }
    {
      name = "qyatt";
      # enable = false;
      admin = false;
    }
  ];
  ollama = {
    enable = true;
    models = [
      "codegemma"
      # "qwen2.5-coder:32b"
      # "mistral-nemo"
      # "yi-coder:9b"
    ];
  };
  preferredRepo = "unstable";
  allowUnfree = true;
  allowAliases = true;
  allowHomeManager = true;
  backupFileExtension = "BaC";
  extraPkgConfig = { };
  extraPkgAttrs = { };
}
