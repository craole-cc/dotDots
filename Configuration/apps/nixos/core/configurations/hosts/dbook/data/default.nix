{
  id = "0ab86678";
  base = [
    "laptop"
    "chromebook"
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
    swapCapsEscape = false;
  };
  access = {
    ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMNDko91cBLITGetT4wRmV1ihq9c/L20sUSLPxbfI0vE root@victus";
    age = "age1j5cug724x386nygk8dhc38tujhzhp9nyzyelzl0yaz3ndgtq3qwqxtkfpv";
    ports = {
      tcp = [ ];
      udp = [ ];
    };
  };
  people = [
    {
      name = "craole";
      isElevated = true;
    }
    {
      name = "qyatt";
      isElevated = false;
    }
  ];
  boot = {
    kernel = {
      initrd = [
        "xhci_pci"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
      ];
    };
  };
  devices = {
    luks = {
      "luks-ef5cc76c-aa34-460b-beb8-a2ea4f99889d".device = "/dev/disk/by-uuid/ef5cc76c-aa34-460b-beb8-a2ea4f99889d";
      "luks-858f4df3-a2dd-4a10-bf57-01694195250e".device = "/dev/disk/by-uuid/858f4df3-a2dd-4a10-bf57-01694195250e";
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
    swap = [
      { device = "/dev/disk/by-uuid/cdb83eba-7128-46ba-b194-d834925e162a"; }
    ];
    network = [ "wlp2s0" ];
  };
  stateVersion = "24.05";
}
