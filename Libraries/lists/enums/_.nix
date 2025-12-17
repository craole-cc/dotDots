{
  _,
  lib,
  ...
}: let
  e = _.lists.enums;
  inherit (_.trivial.tests) mkTest runTests;
  inherit (lib.attrsets) attrNames hasAttrByPath;
  inherit (lib.lists) isList length;

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
    _tests = runTests {
      #? Test structure exists
      hasValues = mkTest true (hasAttrByPath ["enums" "developmentLanguages" "values"] _);
      hasValidator = mkTest true (hasAttrByPath ["enums" "developmentLanguages" "validator"] _);
      hasRootAlias = mkTest true (hasAttrByPath ["enums" "developmentLanguages"] _);

      #? Test actual functionality
      validatorWorks = mkTest true (_.enums.developmentLanguages.validator.check "rust");
      valuesIsList = mkTest true (isList (_.enums.developmentLanguages.values or null));

      #? Test multiple enums exist
      hasAllCategories = mkTest true (
        true
        && hasAttrByPath ["enums" "developmentLanguages"] _
        && hasAttrByPath ["enums" "hostFunctionalities"] _
        && hasAttrByPath ["enums" "userRoles"] _
        && hasAttrByPath ["enums" "bootLoaders"] _
        && hasAttrByPath ["enums" "shells"] _
      );

      # Test enum count
      hasExpectedEnumCount = mkTest 14 (length (attrNames enums));
    };
  }
