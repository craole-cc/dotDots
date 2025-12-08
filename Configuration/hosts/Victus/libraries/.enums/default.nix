{lix, ...}: let
  #~@ Import submodules
  mkVal = lix.lists.makeCaseInsensitiveListValidator;
  desktop = import ./desktop.nix {inherit mkVal;};
  development = import ./development.nix {inherit mkVal;};
  hardware = import ./hardware.nix {inherit mkVal;};
  shell = import ./shell.nix {inherit mkVal;};
  system = import ./system.nix {inherit mkVal;};
  user = import ./user.nix {inherit mkVal;};
in
  {}
  // desktop
  // development
  // hardware
  // shell
  // system
  // user
