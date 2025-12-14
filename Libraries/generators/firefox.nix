{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs isAttrs;
  inherit (lib.strings) substring stringLength;
  inherit (_.predicates.strings) contains containsAny;
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
  in
    if isEmpty input
    then null
    #~@ Check for Zen Browser variants
    else if contains ["zen" "twilight"] input
    then
      if
        containsAny {
          patterns = beta;
          inherit input;
        }
      then "zen-beta"
      else "zen-twilight"
    #~@ Check for LibreWolf
    else if contains ["libre" "wolf"] input
    then "librewolf-bin"
    #~@ Check for Pale Moon
    else if contains ["pale" "moon"] input
    then "palemoon-bin"
    #~@ Check for Firefox variants
    else if
      containsAny {
        patterns = beta;
        inherit input;
      }
    then "firefox-beta"
    else if
      containsAny {
        patterns = stable;
        inherit input;
      }
    then "firefox-esr"
    else if contains ["dev"] input
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
      if contains "zen-" detectedVariant
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
in {
  # Regular module exports (under applications.firefox.*)
  inherit
    makeExtensionUrl
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
