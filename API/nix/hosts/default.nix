{
  imports = [];
  description = "Default nixos host configuration";
  stateVersion = "26.05";
  system = "x86_64-linux";
  class = "nixos";
  id = null;

  paths = {
    dots = "/etc/nixos";
  };

  packages = {
    unstable = true;
    allowUnfree = true;
    kernel = "linuxPackages_cachyos-lto";
  };

  caches = {
    nyx = {
      sub = "https://geo-mirror.chaotic.cx/";
      key = "nyx.chaotic.cx-1:CNZOSlPJO5F0utqsPzkZbHkkD7YzNDWHGG6PqS30wMc=";
    };
  };

  specs = {
    machine = null;
    cpu = {};
    gpu = {};
  };

  modules = [];

  devices = {
    boot = {};
    file = {};
    swap = [];
    network = [];
    display = {};
  };

  localization = {};
  functionalities = [];
  access = {};
  network.backend = "networkmanager";
  principals = [];
  interface = {};
  capabilities = {};
  hardened = false;
  storage = {};
}
