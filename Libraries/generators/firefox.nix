{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs isAttrs;
  inherit (lib.lists) elem;
  inherit (lib.strings) hasInfix substring stringLength;
  inherit (_) isEmpty isNotEmpty getNestedAttrByPaths getPackage;

  /**
  Create a Firefox extension download URL.
  */
  mkExtensionUrl = id: "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";

  /**
  Create a Firefox extension policy entry.
  */
  mkExtensionEntry = {
    id,
    pinned ? false,
  }: let
    base = {
      install_url = mkExtensionUrl id;
      installation_mode = "force_installed";
    };
  in
    if pinned
    then base // {default_area = "navbar";}
    else base;

  /**
  Create Firefox extension settings from a simplified format.
  */
  mkExtensionSettings = mapAttrs (_: entry:
    if isAttrs entry
    then entry
    else mkExtensionEntry {id = entry;});

  /**
  Detect Firefox variant from input string.
  */
  detectVariant = input: let
    beta = ["beta" "nightly" "unstable" "latest"];
    stable = ["esr" "extend" "stable" "twilight" "support" "reproducible"];
    dev = ["development" "dev" "devedition" "dev-edition" "developer"];
  in
    if isEmpty input
    then null
    #~@ Check for Zen Browser variants
    else if
      (hasInfix "zen" input
        && (
          hasInfix "beta" input
          || hasInfix "nightly" input
          || hasInfix "unstable" input
        ))
    then "zen-beta"
    else if (hasInfix "zen" input) || (hasInfix "twilight" input)
    then "zen-twilight"
    #~@ Check for LibreWolf
    else if (elem input ["libre" "wolf"])
    then "librewolf-bin"
    #~@ Check for Pale Moon
    else if (elem input ["pale" "moon"])
    then "palemoon-bin"
    #~@ Check for Firefox variants
    else if (elem input beta)
    then "firefox-beta"
    else if (elem input stable)
    then "firefox-esr"
    else if (elem input dev)
    then "firefox-devedition"
    else "firefox";

  /**
  Resolve Firefox module configuration.
  */
  resolveModule = {
    inputs,
    pkgs,
    variant,
    policies ? {},
  }: let
    #~@ Parse the proper variant name
    detectedVariant = detectVariant (
      if isNotEmpty variant
      then
        if (policies.dev or false) || (policies.devGui or false)
        then "${variant} dev"
        else variant
      else null
    );

    #~@ Resolve Zen Browser specific configuration
    zen =
      if hasInfix "zen-" detectedVariant
      then let
        #~@ Extract suffix: "zen-beta" → "beta"
        zenVariant = substring 4 (stringLength detectedVariant - 4) detectedVariant;
      in {
        name = "zen-browser";
        module = getNestedAttrByPaths {
          attrset = inputs;
          parents = ["firefoxZen" "zenBrowser" "zen-browser" "zen_browser" "twilight" "zen"];
          target = ["homeModules" zenVariant];
        };
        # module = _.getAttrByPaths {
        #   attrset = inputs;
        #   paths = [["firefoxZen"] ["zenBrowser"] ["zen-browser"] ["zen_browser"] ["twilight"] ["zen"]];
        #   # target = "homeModules.${zenVariant}";
        # };
        variant = zenVariant;
      }
      else {
        name = null;
        module = null;
        variant = null;
      };

    #~@ Resolve package from nixpkgs
    package = getPackage {
      inherit pkgs;
      target = detectedVariant;
    };

    #~@ Determine the program name
    program =
      if isNotEmpty zen.module
      then zen.name
      else if isNotEmpty package
      then "firefox"
      else null;

    #~@ Check if configuration exists
    exists = (policies.webGui or false) && isNotEmpty program;
  in {
    inherit program zen package exists;
    variant = detectedVariant;
  };

  zenVariant = variant: let
    detectedVariant = detectVariant variant;
    isZen = hasInfix "zen-" detectedVariant;
  in
    if ! isZen
    then null
    else if hasInfix "beta" detectedVariant
    then "beta"
    else "twilight";
in {
  inherit
    mkExtensionUrl
    zenVariant
    mkExtensionEntry
    mkExtensionSettings
    detectVariant
    resolveModule
    ;

  _rootAliases = {
    mkFirefoxExtensionUrl = mkExtensionUrl;
    mkFirefoxExtensionEntry = mkExtensionEntry;
    mkFirefoxExtensionSettings = mkExtensionSettings;
    detectFirefoxVariant = detectVariant;
    getFirefoxModule = resolveModule;
  };
}
