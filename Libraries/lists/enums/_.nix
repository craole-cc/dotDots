{_, ...}: let
  e = _.lists.enums;

  /**
      Flat enum aggregator - provides both direct and namespaced access.

      # Access Patterns
  ```nix
      _.lists.desktopEnvironments           # Direct (flat)
      _.lists._.desktopEnvironments         # Namespaced
      _.enums.desktopEnvironments           # Root alias
  ```
  */
  enums = {
    inherit (e.gui) bootLoaders displayProtocols displayManagers desktopEnvironments windowManagers waylandSupport;
    inherit (e.hardware) cpuBrands cpuPowerModes gpuBrands;
    inherit (e.tui) shells;
    developmentLanguages = e.development.languages;
    userRoles = e.user.roles;
    userCapabilities = e.user.capabilities;
    hostFunctionalities = e.hardware.functionalities;
  };
in
  enums // {_rootAliases = {inherit enums;};}
