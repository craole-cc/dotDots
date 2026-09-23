let
  arch = "x86_64";
  os = "linux";
in {
  stateVersion = "26.05";
  system = "${arch}-${os}";
  class = "nixos";
  name = "Preci";
  id = "91ba73c7";
  description = "Dell Precision M2800";

  specs = {
    machine = "laptop";
    cpu = {
      inherit arch;
      brand = "intel";
    };
  };

  paths = {
    roots = {
      src = "/home/craole-cc/Projects/dotDots";
      run = "/etc/nixos";
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
    boot = {
      loader = {
        manager = "grub";
        device = "/dev/sda";
        timeout = 1;
      };
    };
    desktops = [
      "plasma"
      # "hyprland"
      "niri"
      # "mango"
      # "cosmic"
    ];
  };

  packages = {
    kernel = "linuxPackages_latest";
  };

  principals = [
    {
      name = "craole-cc";
      enable = true;
      autoLogin = true;
      role = "administrator";
      email = "134658831+craole-cc@users.noreply.github.com";
      description = "Craig 'Craole' Cole";
      defaultLocale = "en_GB.UTF-8";
      keyboard = {
        layout = "us";
        variant = "";
      };
      desktop = "plasma";
      launchers = ["vicinae"];
      shells = [
        "bash"
        "nushell"
        "powershell"
        "zsh"
      ];
    }
  ];
}
