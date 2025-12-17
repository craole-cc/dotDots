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

  __doc = ''
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
  '';

  /**
  Create a Firefox extension download URL.

  Generate the Mozilla Add-ons CDN URL for a given extension ID. This URL
  format is used in Firefox policies for automated extension installation.

  # Type
  ```
  extensionUrl :: String -> String
  ```

  # Arguments
  - `id`: The Firefox extension ID (format: `name@domain` or `{uuid}`)

  # Returns
  A string containing the full CDN download URL for the latest extension version

  # Examples
  ```nix
  extensionUrl "uBlock0@raymondhill.net"
  # => "https://addons.mozilla.org/firefox/downloads/latest/uBlock0@raymondhill.net/latest.xpi"

  extensionUrl "{446900e4-71c2-419f-a6a7-df9c091e268b}"
  # => "https://addons.mozilla.org/firefox/downloads/latest/{446900e4-71c2-419f-a6a7-df9c091e268b}/latest.xpi"
  ```

  # Finding Extension IDs
  1. Open Firefox and navigate to `about:support`
  2. Scroll to "Extensions" section
  3. Copy the ID from the extension's entry
  4. Or check the extension's page URL: `addons.mozilla.org/<*>/addon/<id>/`

  # Use Cases
  - Generating install_url for Firefox policies
  - Automated extension deployment
  - Extension management in declarative configs

  # Notes
  - Extension ID format varies (often @author.domain or {uuid})
  - URL always points to latest published version of the extension
  - URL format is compatible with Firefox Enterprise policies
  */
  extensionUrl = id: "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";

  /**
  Create a Firefox extension policy entry.

  Generates a complete Firefox policy configuration for automated extension
  installation with optional toolbar pinning.

  # Type
  ```
  extensionEntry :: { id :: String, pinned :: Bool? } -> AttrSet
  ```

  # Arguments
  - `id`: Firefox extension ID (required)
  - `pinned`: Pin extension to toolbar (optional, default: false)

  # Returns
  Attribute set containing:
  - `install_url`: Mozilla CDN download URL
  - `installation_mode`: Set to "force_installed"
  - `default_area`: Set to "navbar" if pinned is true

  # Examples
  ```nix
  # Basic extension entry
  extensionEntry { id = "uBlock0@raymondhill.net"; }
  # => {
  #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/...";
  #   installation_mode = "force_installed";
  # }

  # Pinned extension (appears in toolbar)
  extensionEntry {
    id = "uBlock0@raymondhill.net";
    pinned = true;
  }
  # => {
  #   install_url = "https://...";
  #   installation_mode = "force_installed";
  #   default_area = "navbar";
  # }
  ```

  # Use Cases
  - Manual extension policy creation
  - Custom extension configuration
  - Integration with existing policy management
  */
  extensionEntry = {
    id,
    pinned ? false,
  }: let
    base = {
      install_url = extensionUrl id;
      installation_mode = "force_installed";
    };
  in
    if pinned
    then base // {default_area = "navbar";}
    else base;

  /**
  Create Firefox extension settings from a simplified format.

  Batch create Firefox extension policies from a simplified attribute set format.
  Automatically converts simple entries to full policy configurations while
  allowing custom settings to pass through unchanged.

  # Type
  ```
  extensionSettings :: AttrSet -> AttrSet
  ```

  # Arguments
  Attribute set where:
  - Keys are extension IDs
  - Values are either:
    - Empty attribute set `{}` for default installation
    - `{ pinned = true; }` to pin to toolbar
    - Custom attribute set for advanced configuration (passed through)

  # Returns
  Attribute set suitable for `programs.firefox.policies.ExtensionSettings`

  # Examples
  ```nix
  # Multiple extensions with defaults
  extensionSettings {
    "uBlock0@raymondhill.net" = {};
    "addon@darkreader.org" = {};
    "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {};
  }

  # Mixed configuration with pinning
  extensionSettings {
    "uBlock0@raymondhill.net" = { pinned = true; };
    "addon@darkreader.org" = {};
  }

  # With custom settings (passthrough)
  extensionSettings {
    "uBlock0@raymondhill.net" = {
      install_url = "https://custom.url/extension.xpi";
      installation_mode = "normal_installed";
    };
  }
  ```

  # Behavior
  - Empty `{}` → converts to `extensionEntry` with defaults
  - `{ pinned = true; }` → converts to `extensionEntry` with toolbar pinning
  - Custom attribute sets → passed through unchanged for full control

  # Use Cases
  - Declarative extension management
  - Batch extension installation
  - Simplified Home Manager configuration
  */
  extensionSettings = mapAttrs (_: entry:
    if isAttrs entry
    then entry
    else extensionEntry {id = entry;});

  /**
  Detect Firefox variant from input string.

  Parse user-provided strings to detect and normalize browser variant names.
  Supports flexible keyword-based detection for Firefox variants and
  Firefox-based browsers.

  # Type
  ```
  detectVariant :: String -> String?
  ```

  # Arguments
  - `input`: User-provided variant string (case-insensitive keywords)

  # Returns
  - Normalized variant string for nixpkgs/flakes
  - `null` if input is empty

  # Supported Input Patterns

  ## Firefox Variants
  - **ESR**: "esr", "extend", "stable", "support", "reproducible", "twilight"
  - **Beta**: "beta", "nightly", "unstable", "latest"
  - **Developer**: "dev", "development", "devedition", "dev-edition", "developer"
  - **Default**: "firefox" (for unrecognized inputs)

  ## Zen Browser
  - **Twilight** (stable): "zen", "twilight", "zen twilight"
  - **Beta**: "zen beta", "zen nightly", "zen unstable"

  ## Other Browsers
  - **LibreWolf**: "libre", "wolf"
  - **Pale Moon**: "pale", "moon"

  # Examples
  ```nix
  detectVariant "esr"           # => "firefox-esr"
  detectVariant "beta"          # => "firefox-beta"
  detectVariant "dev"           # => "firefox-devedition"
  detectVariant "zen"           # => "zen-twilight"
  detectVariant "zen beta"      # => "zen-beta"
  detectVariant "libre"         # => "librewolf-bin"
  detectVariant "pale"          # => "palemoon-bin"
  detectVariant ""              # => null
  ```

  # Use Cases
  - User-friendly variant selection
  - Configuration file parsing
  - Interactive browser selection

  # Notes
  - Detection is case-insensitive and keyword-based
  - Zen Browser requires special handling for flake integration
  - Returns normalized names matching nixpkgs attribute paths
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

  Resolve complete browser configuration including packages, Home Manager modules,
  and policy settings. Handles special cases like Zen Browser flake integration
  and developer edition variant selection.

  # Type
  ```
  resolveModule :: {
    inputs :: FlakeInputs,
    pkgs :: Nixpkgs,
    system :: String?,
    variant :: String?,
    policies :: AttrSet?
  } -> AttrSet
  ```

  # Arguments
  - `inputs`: Flake inputs containing browser sources
  - `pkgs`: Nixpkgs instance for package resolution
  - `system`: Target system (optional, default: "x86_64-linux")
  - `variant`: Browser variant string (optional, default: "firefox")
  - `policies`: Configuration policies (optional)

  # Policies Attribute Set
  - `webGui` (Bool): Enable web GUI module (required for allowed = true)
  - `dev` (Bool): Force developer edition variant
  - `devGui` (Bool): Same as dev, alternative naming

  # Returns
  Attribute set containing:
  - `program` (String): Program name ("firefox", "zen-browser", etc.)
  - `package` (Derivation): Resolved browser package
  - `variant` (String): Detected/normalized variant name
  - `allowed` (Bool): Whether configuration is allowed (requires webGui = true)
  - `module` (Module, optional): Home Manager module (Zen Browser only)

  # Examples
  ```nix
  # Basic Firefox ESR
  resolveModule {
    inherit inputs pkgs;
    variant = "esr";
    policies = { webGui = true; };
  }
  # => {
  #   program = "firefox";
  #   package = pkgs.firefox-esr;
  #   variant = "firefox-esr";
  #   allowed = true;
  # }

  # Zen Browser with flake integration
  resolveModule {
    inherit inputs pkgs;
    system = "x86_64-linux";
    variant = "zen twilight";
    policies = { webGui = true; };
  }
  # => {
  #   program = "zen-browser";
  #   package = inputs.zen-browser.packages.x86_64-linux.twilight;
  #   variant = "zen-twilight";
  #   allowed = true;
  #   module = inputs.zen-browser.homeModules.twilight;
  # }

  # Developer edition with GUI
  resolveModule {
    inherit inputs pkgs;
    variant = "firefox";
    policies = {
      webGui = true;
      dev = true;
    };
  }
  # => {
  #   program = "firefox";
  #   package = pkgs.firefox-devedition;
  #   variant = "firefox-devedition";
  #   allowed = true;
  # }
  ```

  # Zen Browser Integration
  Searches these flake input names for Zen Browser:
  - firefoxZen
  - zenBrowser
  - zen-browser
  - zen_browser
  - twilight
  - zen

  Expected flake structure:
  ```nix
  inputs.zen-browser = {
    url = "github:...";
    packages.x86_64-linux = {
      twilight = <derivation>;
      beta = <derivation>;
    };
    homeModules = {
      twilight = <module>;
      beta = <module>;
    };
  };
  ```

  # Use Cases
  - Unified browser configuration interface
  - Home Manager integration
  - Dynamic browser selection based on user preferences
  - Flake-based browser management

  # Notes
  - Automatically handles Zen Browser flake integration
  - Falls back to nixpkgs for standard Firefox variants
  - Requires webGui = true policy for module activation
  - Developer edition can be forced via policy flags
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

  /**
  Extract Zen Browser variant from user input string.

  Convenience function to extract the specific Zen Browser variant (twilight or beta)
  from a user input string, or return null if not a Zen Browser variant.

  # Type
  ```
  zenVariant :: String -> String?
  ```

  # Arguments
  - `variant`: User-provided variant string

  # Returns
  - "beta" for beta/nightly/unstable variants
  - "twilight" for stable/default variants
  - null if not a Zen Browser variant

  # Examples
  ```nix
  zenVariant "zen"            # => "twilight"
  zenVariant "zen beta"       # => "beta"
  zenVariant "zen nightly"    # => "beta"
  zenVariant "twilight"       # => "twilight"
  zenVariant "firefox"        # => null
  zenVariant "libre"          # => null
  ```

  # Use Cases
  - Zen Browser-specific configuration
  - Variant validation
  - Flake attribute path generation
  */
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
  #~@ Values
  version = "1.0.0";
  defaultSettings = {pinned = false;};

  inherit
    # __doc
    extensionUrl
    zenVariant
    extensionEntry
    extensionSettings
    detectVariant
    resolveModule
    ;

  _rootAliases = {
    mkFirefoxExtensionUrl = extensionUrl;
    mkFirefoxExtensionEntry = extensionEntry;
    mkFirefoxExtensionSettings = extensionSettings;
    detectFirefoxVariant = detectVariant;
    getFirefoxModule = resolveModule;
  };
}
