/**
Firefox browser configuration and variant resolution utilities.

This module provides comprehensive tools for managing Firefox and Firefox-based
browsers (Zen Browser, LibreWolf, Pale Moon) including variant detection,
extension management, and Home Manager module resolution.

Key Features:
- Automatic variant detection from user strings
- Support for Zen Browser (twilight/beta) with flake integration
- Firefox extension URL generation and policy management
- Unified interface for Firefox, LibreWolf, and Pale Moon

Supported Browsers:
- Firefox (stable, ESR, beta, nightly, devedition)
- Zen Browser (twilight, beta)
- LibreWolf
- Pale Moon

Common Patterns:
```nix
# Resolve browser module from user preference
browser = getFirefoxModule {
  inherit inputs pkgs;
  variant = "zen twilight";
  policies = { webGui = true; };
};

# Generate extension settings
programs.firefox.policies.ExtensionSettings =
  mkFirefoxExtensionSettings {
    "uBlock0@raymondhill.net" = { pinned = true; };
    "addon@darkreader.org" = {};
  };
```
*/
{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs isAttrs optionalAttrs;
  inherit (lib.lists) elem;
  inherit (lib.strings) hasInfix substring stringLength;
  inherit (_) isEmpty isNotEmpty getNestedAttrByPaths getPackage getAttr;

  /**
  Create a Firefox extension download URL.

  Generate the Mozilla Add-ons CDN URL for a given extension ID. This URL
  format is used in Firefox policies for automated extension installation.

  # Type
  ```
  mkExtensionUrl :: String -> String
  ```

  # Arguments
  - `id`: The Firefox extension ID (usually ends in @domain or @creator)

  # Returns
  A string containing the full CDN download URL

  # Examples
  ```nix
  mkExtensionUrl "uBlock0@raymondhill.net"
  # => "https://addons.mozilla.org/firefox/downloads/latest/uBlock0@raymondhill.net/latest.xpi"

  mkExtensionUrl "addon@darkreader.org"
  # => "https://addons.mozilla.org/firefox/downloads/latest/addon@darkreader.org/latest.xpi"
  ```

  # Use Cases
  - Generating install_url for Firefox policies
  - Automated extension deployment
  - Extension management in declarative configs

  # Notes
  - Extension ID format varies (often @author.domain or @organization)
  - Find extension IDs from about:support → Extensions in Firefox
  - URL always points to latest version of the extension
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
    system ? "x86_64-linux",
    variant ? "firefox",
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
    zen = let
      check = hasInfix "zen-" detectedVariant;
      #> Extract suffix: "zen-beta" → "beta"
      zenVariant = substring 4 (stringLength detectedVariant - 4) detectedVariant;
      parents = ["firefoxZen" "zenBrowser" "zen-browser" "zen_browser" "twilight" "zen"];
      attrset = inputs;
    in
      optionalAttrs check {
        name = "zen-browser";
        module = getNestedAttrByPaths {
          inherit attrset parents;
          target = ["homeModules" zenVariant];
        };
        package = getNestedAttrByPaths {
          inherit attrset parents;
          target = ["packages" system zenVariant];
        };
        variant = zenVariant;
      };

    #~@ Resolve package from nixpkgs
    package = getAttr zen "package" (getPackage {
      inherit pkgs;
      target = detectedVariant;
    });

    #~@ Determine the program name
    program = zen.name or "firefox";

    #~@ Check if configuration exists
    allowed = (policies.webGui or false) && isNotEmpty program;
  in
    {
      inherit program package allowed;
      variant = detectedVariant;
    }
    // _.optionalAttr zen "module";

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
