# Libraries/lists/enums.nix
{_, ...}: let
  imports = _.lists.enums;
  # inherit (hardware) functionalities cpuBrands cpuPowerModes gpuBrands;
  # inherit (tui) shells;
  # inherit (user) roles capabilities;
  exports = {
    developmentLanguages = imports.dev.languages;
    inherit (imports) bootLoaders displayProtocols displayManagers desktopEnvironments windowManagers waylandSupport;
  };
in {
  _rootAliases = {
    enums = exports;
  };
}
