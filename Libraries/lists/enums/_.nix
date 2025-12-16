# Libraries/lists/enums.nix
{_, ...}: let
  # Import all enum modules
  dev = _.lists.enums.development;
  # dev = import ./development.nix {inherit _;};
  gui = import ./gui.nix {inherit _;};
  hardware = import ./hardware.nix {inherit _;};
  tui = import ./tui.nix {inherit _;};
  user = import ./user.nix {inherit _;};
in {
  # Export everything flat at root
  inherit (dev) languages;
  inherit (gui) bootLoaders displayProtocols displayManagers desktopEnvironments windowManagers waylandSupport;
  inherit (hardware) functionalities cpuBrands cpuPowerModes gpuBrands;
  inherit (tui) shells;
  inherit (user) roles capabilities;

  # Also export categorized
  development = dev;
  gui = gui;
  hardware = hardware;
  tui = tui;
  user = user;

  _rootAliases = {
    # Flat access via root
    enums = {
      # All enums accessible here
      developmentLanguages = dev.languages;
      bootLoaders = gui.bootLoaders;
      # ... etc
      userRoles = user.roles;
      userCapabilities = user.capabilities;
    };
  };
}
