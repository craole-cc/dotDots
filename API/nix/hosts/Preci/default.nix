let
  arch = "x86_64";
  os = "linux";
in {
  imports = [./hardware-configuration];

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
    "efi" #? Check
    "gpu"
    "keyboard"
    "network"
    "secureboot" #? No, check
    "storage"
    "touchpad"
    "tpm" #? What's this?
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
    desktops = ["plasma"];
  };

  packages = rec {
    kernel = "linuxPackages_latest";
    shells = ["bash"];
    coding = ["common"];
    launchers = ["vicinae"];
    common =
      [
        "helix" #? Editor
        "brave" #? Browser
        "freetube" #? YouTube Player
        "ghostty" #? Terminal Emulator
        "qimgv" #? Image Viewer
        "mpv" #? Media Player
        "yazi" #? File Explorer
        "starship" #? Shell Prompt
      ]
      ++ launchers;
  };

  principals = [
    ({
        name = "craole";
        role = "administrator";
        enable = true;
        autoLogin = false;
      }
      // import ./users/craole)
  ];
}
