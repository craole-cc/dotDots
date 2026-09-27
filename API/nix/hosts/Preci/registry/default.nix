{
  stateVersion = "26.05";
  system = "x86_64-linux";
  class = "nixos";
  name = "Preci";
  id = "91ba73c7";
  description = "Dell Precision M2800";

  specs = {
    machine = "laptop";
    cpu = {
      arch = "x86_64";
      brand = "intel";
    };
  };

  paths = {
    roots = let
      src = "/home/craole-cc/Projects/dotDots";
      run = src + "/API/nix/hosts/Preci";
    in {inherit src run;};
  };

  localization = {
    latitude = 18.015;
    longitude = -77.49;
    city = "Mandeville, Jamaica";
    timeZone = "America/Jamaica";
    defaultLocale = "en_US.UTF-8";
  };

  functionalities = {
    audio = {};
    battery = {};
    bluetooth = {};
    efi = {};
    gpu = {};
    keyboard = {};
    network = {};
    secureboot = {};
    storage = {};
    touchpad = {};
    tpm = {};
    video = {};
    virtualization = {};
    vpn = {};
    webcam = {};
    wired = {};
    wireless = {};
  };

  interface = {
    boot.loader = {
      manager = "grub";
      device = "/dev/sda";
      timeout = 1;
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
        "helix"
        "brave"
        "freetube"
        "ghostty"
        "qimgv"
        "mpv"
        "yazi"
        "starship"
      ]
      ++ launchers;
  };

  principals = [
    (
      {
        name = "craole";
        role = "administrator";
        enable = true;
        autoLogin = false;
      }
      # // (import ./craole.nix) #TODO: This should not be declared here. We should have search for the name in the API/nix/users/${name} and append those values to this. This is the local
    )
  ];
}
