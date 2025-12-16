{_, ...}: let
  e = _.lists.enums;
  enums = {
    developmentLanguages = e.development.languages;
    userRoles = e.user.roles;
    userCapabilities = e.user.capabilities;
    hostCapabilities = e.hardware.functionalities;
    inherit (e.gui) bootLoaders displayProtocols displayManagers desktopEnvironments windowManagers waylandSupport;
    inherit (e.hardware) cpuBrands cpuPowerModes gpuBrands;
    inherit (e.tui) shells;
  };
in
  enums // {_rootAliases = {inherit enums;};}
