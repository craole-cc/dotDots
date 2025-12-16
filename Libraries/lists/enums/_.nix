# Libraries/lists/enums.nix
{_, ...}: let
  # Import all enum modules
  e = _.lists.enums;
  # # dev = import ./development.nix {inherit _;};
  # gui = import ./gui.nix {inherit _;};
  # hardware = import ./hardware.nix {inherit _;};
  # tui = import ./tui.nix {inherit _;};
  # user = import ./user.nix {inherit _;};
  enums = {
    developmentLanguages = e.development.languages;
    inherit (e.gui) bootLoaders displayProtocols displayManagers desktopEnvironments windowManagers waylandSupport;
    inherit (e.hardware) functionalities cpuBrands cpuPowerModes gpuBrands;
    inherit (e.tui) shells;
    inherit (e.user) roles capabilities;
  };
in
  enums
# in {
#   # Export everything flat at root
#   inherit developmentLanguages;
#   # Also export categorized
#   # development = dev;
#   # gui = gui;
#   # hardware = hardware;
#   # tui = tui;
#   # user = user;
#   _rootAliases = {
#     # Flat access via root
#     enums = {
#       # All enums accessible here
#       inherit developmentLanguages;
#       bootLoaders = e.gui.bootLoaders;
#       # ... etc
#       userRoles = e.user.roles;
#       userCapabilities = e.user.capabilities;
#     };
#   };
# }
