{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs isAttrs;
  inherit (lib.lists) elem;
  inherit (lib.strings) hasPrefix hasSuffix hasInfix substring stringLength;
  inherit (_.predicates.emptiness) isEmpty isNotEmpty;
  inherit (_.attrsets.resolution) getNestedAttr getPackage;

  /**
  Create a Firefox extension download URL.
  */
  makeExtensionUrl = id: "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";

  /**
  Create a Firefox extension policy entry.
  */
  makeExtensionEntry = {
    id,
    pinned ? false,
  }: let
    base = {
      install_url = makeExtensionUrl id;
      installation_mode = "force_installed";
    };
  in
    if pinned
    then base // {default_area = "navbar";}
    else base;

  /**
  Create Firefox extension settings from a simplified format.
  */
  makeExtensionSettings = mapAttrs (_: entry:
    if isAttrs entry
    then entry
    else makeExtensionEntry {id = entry;});

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
    else if (hasInfix "zen" input && (hasInfix "beta" input || hasInfix "nightly" input || hasInfix "unstable" input))
    then "zen-beta"
    else if (hasInfix "zen" input)
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
    policies,
  }: let
    #~@ Parse the proper variant name
    detectedVariant = detectVariant (
      with policies;
        if isNotEmpty variant
        then
          if dev || devGui
          then "${variant} dev"
          else variant
        else null
    );

    #~@ Resolve Zen Browser specific configuration
    zen =
      if hasPrefix "zen-" detectedVariant
      then let
        #~@ Extract suffix: "zen-beta" → "beta"
        zenVariant = substring 4 (stringLength detectedVariant - 4) detectedVariant;
      in {
        name = "zen-browser";
        module = getNestedAttr inputs ["zenBrowser" "zen-browser" "zen_browser" "twilight" "zen"] "homeModules.${zenVariant}" null;
      }
      else {
        name = null;
        module = null;
      };

    #~@ Resolve package from nixpkgs
    package = getPackage pkgs detectedVariant null;

    #~@ Determine the program name
    program =
      if isNotEmpty zen.module
      then zen.name
      else if isNotEmpty package
      then "firefox"
      else null;

    #~@ Check if configuration exists
    exists = policies.webGui && isNotEmpty program;
  in {
    inherit program zen package exists;
    variant = detectedVariant;
  };

  zenVariant = variant:
    if (! hasPrefix "zen-" (detectVariant variant))
    then null
    else if hasInfix (detectVariant variant) "beta"
    then "beta"
    else "twilight";
in {
  # Regular module exports (under applications.firefox.*)
  inherit
    makeExtensionUrl
    zenVariant
    makeExtensionEntry
    makeExtensionSettings
    detectVariant
    resolveModule
    ;

  # Root aliases (exposed at _lib.*)
  _rootAliases = {
    makeFirefoxExtensionUrl = makeExtensionUrl;
    makeFirefoxExtensionEntry = makeExtensionEntry;
    makeFirefoxExtensionSettings = makeExtensionSettings;
    detectFirefoxVariant = detectVariant;
    resolveFirefoxModule = resolveModule;
  };
}
