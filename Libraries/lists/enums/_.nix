{_, ...}: let
  e = _.lists.enums;
  inherit (_.std.attrsets) getAttr hasAttr;

  /**
      Enum aggregator - provides flat access to all enums.

      # Access Patterns
  ```nix
      # Via namespace
      _.lists.enums._.languages.values

      # Via root alias (recommended)
      _.enums.developmentLanguages.values
      _.enums.developmentLanguages.validator.check "rust"

      # Convenient list-only access
      _.devLanguagesList
  ```

      # Available Enums
      - Development: languages
      - GUI: bootLoaders, displayProtocols, displayManagers, desktopEnvironments, windowManagers, waylandSupport
      - Hardware: functionalities, cpuBrands, cpuPowerModes, gpuBrands
      - TUI: shells
      - User: roles, capabilities
  */
  enums = {
    inherit
      (e.gui)
      bootLoaders
      displayProtocols
      displayManagers
      desktopEnvironments
      windowManagers
      waylandSupport
      ;
    inherit (e.hardware) cpuBrands cpuPowerModes gpuBrands;
    inherit (e.tui) shells;
    developmentLanguages = e.development.languages;
    userRoles = e.user.roles;
    userCapabilities = e.user.capabilities;
    hostFunctionalities = e.hardware.functionalities;
  };
in
  enums
  // {
    _rootAliases = {inherit enums;};
    _tests = let
      inherit (_.testing.unit) mkTest runTests;
    in
      runTests {
        exportsAllEnums = mkTest true (
          hasAttr "languages" enums
          && hasAttr "bootLoaders" enums
          && hasAttr "roles" enums
        );

        enumsHaveValidators = mkTest true (
          hasAttr "validator" enums.languages
          && hasAttr "validator" enums.roles
        );

        # rootAliasWorks = mkTest enums (getAttr "enums" (_rootAliases or {}));
      };
  }
