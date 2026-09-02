let
  arch = "aarch64";
  os = "linux";
in {
  stateVersion = "25.05";
  system = "${arch}-${os}";
  class = "home-manager";
  id = "9ab9ae6f";

  paths = {
    roots.repo = "/home/craole-cc/Projects/craole-cc/dotDots";
  };

  specs = {
    machine = "cloud"; # OCI free-tier ARM instance

    cpu = {
      inherit arch;
      brand = "ampere";
      cores = 2;
    };
  };

  devices = {
    network = ["enp0s6"];

    # No storage devices.boot/file/swap: Nix doesn't manage this host's
    # filesystem or bootloader, that's owned by Ubuntu/cloud-init.
  };

  localization = {
    timeZone = "America/Jamaica";
    defaultLocale = "en_US.UTF-8";
  };

  functionalities = [
    "network"
    "storage"
    "virtualization"
    "vpn"
    "wired"
  ];

  access = {
    # ssh = ""; # add if you want a recorded pubkey, e.g. for provisioning notes

    remote = {
      ssh = {
        enable = true;
        keyOnly = true;
      };
      tailscale.enable = true;
    };
  };

  network.backend = "systemd-networkd"; # or "networkd"/native ubuntu netplan; adjust if you know otherwise

  principals = [
    {
      name = "craole";
      enable = true;
      autoLogin = false;
      role = "administrator";
    }
  ];
}
