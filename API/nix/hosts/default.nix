{
  imports = [];
  description = null;
  stateVersion = null;
  system = "x86_64-linux";
  class = "nixos";
  id = null;

  paths = {
    dots = null;
  };

  packages = {
    unstable = false;
    allowUnfree = false;
    kernel = null;
  };

  caches = {};
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
  network = {
    backend = "networkmanager";
  };
  principals = [];
  interface = {};
  capabilities = {};
  hardened = false;
  storage = {};
}
