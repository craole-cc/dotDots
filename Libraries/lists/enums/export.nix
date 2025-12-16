# Libraries/lists/enums.nix
{_, ...}: let
  imports = _.lists.enums;
  # inherit (hardware) functionalities cpuBrands cpuPowerModes gpuBrands;
  # inherit (tui) shells;
  # inherit (user) roles capabilities;

  dev = import ./development.nix {inherit _;};
  gui = import ./gui.nix {inherit _;};
  hardware = import ./hardware.nix {inherit _;};
  tui = import ./tui.nix {inherit _;};
  user = import ./user.nix {inherit _;};
  enums = {
    developmentLanguages = dev.languages;
    inherit (gui) bootLoaders displayProtocols displayManagers desktopEnvironments windowManagers waylandSupport;
  };
in
  enums // {_rootAliases = enums;}
