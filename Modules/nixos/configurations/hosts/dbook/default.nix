{
  system = "x86_64-linux";
  id = "f7c2e3b1"; # TODO: Change this
  stateVersion = "24.05";
  base = "laptop";
  desktop = "xfce";
  capabilities = [
    "audio"
    "battery"
    "bluetooth"
    "video"
    "storage"
    "mouse"
    "touchpad"
    "wireless"
  ];
  context = [
    "development"
    "media"
    "productivity"
  ];
  cpu = {
    brand = "intel";
    arch = "x86_64-linux";
    mode = "ondemand";
  };
  gpu = {
    brand = "intel";
  };
  keyboard = {
    modifier = "SUPER_L";
    swapCapsEscape = true;
  };
  access = {
    ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMNDko91cBLITGetT4wRmV1ihq9c/L20sUSLPxbfI0vE root@victus";
    age = "age1j5cug724x386nygk8dhc38tujhzhp9nyzyelzl0yaz3ndgtq3qwqxtkfpv";
    firewall = {
      enable = true;
      tcp = {
        ranges = [
          {
            from = 49160;
            to = 65534;
          } # Allowing a range for random port selection
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
          } # Allowing a range for random port selection
        ];
        ports = [ ];
      };
    };
  };
  people = [
    {
      name = "craole";
      autoLogin = true;
    }
  ];
  boot = {
    modules = [
      "xhci_pci"
      "usb_storage"
      "sd_mod"
      "sdhci_pci"
    ];
  };
  devices = {
    luks = {
      "luks-ef5cc76c-aa34-460b-beb8-a2ea4f99889d".device =
        "/dev/disk/by-uuid/ef5cc76c-aa34-460b-beb8-a2ea4f99889d";
      "luks-858f4df3-a2dd-4a10-bf57-01694195250e".device =
        "/dev/disk/by-uuid/858f4df3-a2dd-4a10-bf57-01694195250e";
    };

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/4f7188d1-48ec-475d-87bb-f9547cbb253b";
        fsType = "ext4";
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/F4C7-66A5";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };
    };

    swapDevices = [
      { device = "/dev/disk/by-uuid/cdb83eba-7128-46ba-b194-d834925e162a"; }
    ];

    network = [ "wlp2s0" ];
  };
}
