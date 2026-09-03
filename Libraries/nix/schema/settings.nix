{_, ...}: let
  meta = let
    doc = ''
      # Settings Schema

      Normalizes and merges global and host-level system settings for `pkg` (nixpkgs) and `lib` (library options).
      Supports alias normalization (`packages` -> `pkg`, `libraries` -> `lib`) whether declared as `host.packages`,
      `host.settings.pkg`, or globally.

      ## Functions

      - `mkSettings` - Merges `global` and `host` settings, resolving package/library aliases, kernel selections, and unstable flags.

    '';
    exports = {
      local = {inherit mkSettings;};
      alias = {
        settings = mkSettings;
      };
    };
  in {
    inherit doc exports;
  };

  inherit (_.attrsets.aggregation) recursiveUpdate;

  /**
  Resolves combined settings by normalizing aliases (`packages` / `pkg`, `libraries` / `lib`),
  recursively merging global defaults with host overrides, and strictly mapping options to
  `forNixpkgs` and `forLibraries`.

  # Arguments
  - global: Global settings or API global set (`raw.global.settings` or `raw.global`)
  - host: Host attrset or host settings (`hostAttr` or `hostAttr.settings`)

  # Returns
  An attrset containing merged `pkg` and `lib` options alongside structured
  `forNixpkgs` and `forLibraries` outputs.
  */
  mkSettings = {
    global ? {},
    host ? {},
  }: let
    # Extract global settings and normalize pkg/lib aliases
    globalSettings = global.settings or global;
    globalPkg = globalSettings.pkg or globalSettings.packages or {};
    globalLib = globalSettings.lib or globalSettings.libraries or {};
    globalNormalized =
      globalSettings
      // {
        pkg = globalPkg;
        lib = globalLib;
      };

    # Extract host settings (supports host.packages, host.pkg, host.settings.pkg, etc.)
    hostSettings = host.settings or host;
    hostPkg = hostSettings.pkg or hostSettings.packages or host.pkg or host.packages or {};
    hostLib = hostSettings.lib or hostSettings.libraries or host.lib or host.libraries or {};
    hostNormalized =
      hostSettings
      // {
        pkg = hostPkg;
        lib = hostLib;
      };

    merged = recursiveUpdate globalNormalized hostNormalized;

    pkg = merged.pkg or {};
    lib = merged.lib or {};

    forNixpkgs = {
      allowUnfree = pkg.allowUnfree or true;
      allowBroken = pkg.allowBroken or false;
      unstable = pkg.unstable or false;
      kernel = pkg.kernel or null;
    };

    forLibraries = {
      collisionStrategy = lib.collisionStrategy or "warn";
      allowAliases = lib.allowAliases or false;
      allowTests = lib.allowTests or false;
    };
  in
    merged
    // {
      inherit
        pkg
        lib
        forNixpkgs
        forLibraries
        ;
    };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
