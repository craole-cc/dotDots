{
  _,
  lib,
  ...
}: let
  inherit (_.filesystem.paths) source;
  inherit (_.hardware.system) getSystem;
  inherit (_.inputs.resolution) inputs;
  inherit (_.attrsets.access) getIn;
  inherit (_.debug.assertions) mkTest mkTest';
  inherit (_.debug.runners) runTests;
  inherit (lib.attrsets) filterAttrsRecursive listToAttrs mapAttrs mapAttrs';
  inherit (lib.lists) length;

  defaults = {
    allowUnfree = true;
    allowBroken = false;
    corePackages = ["nixpkgs" "nixpkgs-stable" "nixpkgs-unstable"];
    homePackages = [
      "caelestia" "catppuccin" "dank-material-shell" "fresh-editor"
      "helix" "home-manager" "noctalia-shell" "nvf" "plasma"
      "quickshell" "treefmt" "typix" "vscode-insiders" "zen-browser"
    ];
  };

  /**
  Build a name → packages attrset by resolving `inputs.<name>.<attr>` for
  each name in `names`.

  # Type
  ```nix
  mkPackageSet :: { attr :: string, names :: [string] } -> AttrSet
  ```
  */
  mkPackageSet = {attr, names}:
    listToAttrs (map (name: {
      inherit name;
      value = getIn {attrs = inputs; path' = [name attr]; default = {};};
    }) names);

  packages =
    mkPackageSet {attr = "legacyPackages"; names = defaults.corePackages;}
    // mkPackageSet {attr = "packages";       names = defaults.homePackages;};

  /**
  Build the full nixpkgs config block for a host.

  # Type
  ```nix
  mkPackages :: { host :: AttrSet } -> { nixpkgs, inputs, packages, overlays }
  ```
  */
  mkPackages = {host}: let
    config = {
      allowUnfree = host.packages.allowUnfree or defaults.allowUnfree;
      allowBroken = host.packages.allowBroken or defaults.allowBroken;
    };
    overlays = mkOverlays {inherit config;};
    nixpkgs  = {inherit config overlays; hostPlatform = host.system;}
               // source {inherit host inputs;};
  in {inherit nixpkgs inputs packages overlays;};

  /**
  Build the standard overlay list for a nixpkgs instantiation.

  # Type
  ```nix
  mkOverlays :: { config :: AttrSet? } -> [overlay]
  ```
  */
  mkOverlays = {config ? {}}: let
    config' = {inherit (defaults) allowUnfree allowBroken;} // config;
  in [
    #~@ Stable
    (final: _: let system = getSystem final; in {
      fromStable = import inputs.nixpkgs-stable {config = config'; inherit system;};
    })
    #~@ Unstable
    (final: _: let system = getSystem final; in {
      fromUnstable = import inputs.nixpkgs-unstable {config = config'; inherit system;};
    })
    #~@ Flake inputs — flattened (higher priority)
    (final: prev: let system = getSystem prev; in
      filterAttrsRecursive (_: v: v != null) (
        mapAttrs' (name: pkgsSet: {
          inherit name;
          value = getIn {attrs = pkgsSet; path' = [system "default"]; default = null;};
        }) packages))
    #~@ Flake inputs — categorised (lower priority)
    (final: prev: let system = getSystem prev; in {
      fromInputs = mapAttrs (_: pkgsSet:
        getIn {attrs = pkgsSet; path' = [system]; default = {};}) packages;
    })
    #~@ Chaotic
    (inputs.chaotic.overlays.default or (_: _: {}))
  ];

  exports = {
    inherit defaults mkOverlays mkPackageSet mkPackages packages;
    getInputDefaults    = defaults;
    getInputPackages    = packages;
    mkInputOverlays     = mkOverlays;
    mkInputPackageSet   = mkPackageSet;
    mkInputPackages     = mkPackages;
  };
in
  exports
  // {
    _rootAliases = {
      inherit (exports)
        getInputDefaults getInputPackages
        mkInputPackageSet mkInputOverlays mkInputPackages;
    };

    _tests = runTests {
      defaults = {
        allowUnfreeIsTrue    = mkTest' true  defaults.allowUnfree;
        allowBrokenIsFalse   = mkTest' false defaults.allowBroken;
        hasCorePackages      = mkTest' true  (length defaults.corePackages > 0);
        hasHomePackages      = mkTest' true  (length defaults.homePackages > 0);
      };

      getIn = {
        resolvesNestedPath = mkTest {
          desired = "val";
          outcome = getIn {attrs = {a.b = "val";}; path' = ["a" "b"]; default = null;};
          command = ''getIn { attrs = { a.b = "val"; }; path' = ["a" "b"]; default = null; }'';
        };
        fallsBackToDefault = mkTest {
          desired = {};
          outcome = getIn {attrs = {}; path' = ["missing" "key"]; default = {};};
          command = ''getIn { attrs = {}; path' = ["missing" "key"]; default = {}; }'';
        };
      };
    };
  }
