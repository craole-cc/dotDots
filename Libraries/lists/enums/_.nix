{_, ...}: let
  e = _.lists.enums;
  enums = {
    developmentLanguages = e.development.languages;
    inherit (e.gui) bootLoaders displayProtocols displayManagers desktopEnvironments windowManagers waylandSupport;
    inherit (e.hardware) functionalities cpuBrands cpuPowerModes gpuBrands;
    inherit (e.tui) shells;
    inherit (e.user) roles capabilities;
  };
in
  enums // {_rootAliases = {inherit enums;};}
