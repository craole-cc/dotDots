{
  # imports = [
  #   ./configuration.nix
  #   ./hardware-configuration.nix
  # ];
  paths.base = "/home/craole/.dots";
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
      "ata_piix"
      "mptspi"
      "uhci_hcd"
      "ehci_pci"
      "xhci_pci"
      "sd_mod"
      "sr_mod"
    ];
  };
  devices = {
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/8cdc275f-5dff-4945-bbbe-044276cddc76";
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/28AD-7711";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };
    };

    swapDevices = [ ];

    network = [
      "ens33"
    ];
  };
  desktop = "plasma";
  location = {
    latitude = 18.015;
    longitude = 77.49;
    timeZone = "America/Jamaica";
    defaultLocale = "en_US.UTF-8";
  };
  capabilities = [
    "ai"
    "audio"
    # "battery"
    "bluetooth"
    "video"
    "storage"
    "mouse"
    # "remote"
    # "touchpad"
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
  backupFileExtension = "backup";
  extraPkgConfig = { };
  extraPkgAttrs = { };

}
