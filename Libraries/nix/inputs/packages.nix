{
  _,
  lib,
  ...
}: let
  inherit (_.filesystem.paths) source;
  inherit (_.hardware.system) getSystem;
  inherit (_.inputs.resolution) inputs;
  inherit (_.attrsets.access) valueOr;
  inherit (_.debug.assertions) mkTest mkTest' mkThrows;
  inherit (_.debug.runners) runTests;
  inherit (lib.attrsets) filterAttrsRecursive listToAttrs mapAttrs mapAttrs';
  inherit (lib.lists) length;

  defaults = {
    allowUnfree = true;
    allowBroken = false;
    corePackages = ["nixpkgs" "nixpkgs-stable" "nixpkgs-unstable"];
    homePackages = [
      "caelestia"
      "catppuccin"
      "dank-material-shell"
      "fresh-editor"
      "helix"
      "home-manager"
      "noctalia-shell"
      "nvf"
      "plasma"
      "quickshell"
      "treefmt"
      "typix"
      "vscode-insiders"
      "zen-browser"
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
  mkPackageSet = {
    attr,
    names,
  }:
    listToAttrs (map (name: {
        inherit name;
        value = let
          input = valueOr {
            attrs = inputs;
            key = name;
            default = {};
          };
        in
          valueOr {
            attrs = input;
            key = attr;
            default = {};
          };
      })
      names);

  packages =
    mkPackageSet {
      attr = "legacyPackages";
      names = defaults.corePackages;
    }
    // mkPackageSet {
      attr = "packages";
      names = defaults.homePackages;
    };

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
    nixpkgs =
      {
        inherit config overlays;
        hostPlatform = host.system;
      }
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
    (final: _: let
      system = getSystem final;
    in {
      fromStable = import inputs.nixpkgs-stable {
        config = config';
        inherit system;
      };
    })
    #~@ Unstable
    (final: _: let
      system = getSystem final;
    in {
      fromUnstable = import inputs.nixpkgs-unstable {
        config = config';
        inherit system;
      };
    })
    #~@ Flake inputs — flattened (higher priority)
    (final: prev: let
      system = getSystem prev;
    in
      filterAttrsRecursive (_: v: v != null) (
        mapAttrs' (name: pkgsSet: {
          inherit name;
          value = valueOr {
            attrs = pkgsSet;
            key = system;
            default = null;
          };
        })
        packages
      ))
    #~@ Flake inputs — categorised (lower priority)
    (final: prev: let
      system = getSystem prev;
    in {
      fromInputs = mapAttrs (_: pkgsSet:
        valueOr {
          attrs = pkgsSet;
          key = system;
          default = {};
        })
      packages;
    })
    #~@ Chaotic
    (inputs.chaotic.overlays.default or (_: _: {}))
  ];

  exports = {
    inherit defaults mkOverlays mkPackageSet mkPackages packages;
    outputDefaults = defaults;
    outputPackages = packages;
    mkInputOverlays = mkOverlays;
    mkInputPackageSet = mkPackageSet;
    mkInputPackages = mkPackages;
  };
in
  exports
  // {
    _rootAliases = {
      inherit
        (exports)
        outputDefaults
        outputPackages
        mkInputPackageSet
        mkInputOverlays
        mkInputPackages
        ;
    };

    _tests = runTests {
      defaults = {
        allowUnfreeIsTrue = mkTest' true defaults.allowUnfree;
        allowBrokenIsFalse = mkTest' false defaults.allowBroken;
        hasCorePackages = mkTest' true (length defaults.corePackages > 0);
        hasHomePackages = mkTest' true (length defaults.homePackages > 0);
        nixpkgsInCore = mkTest' true (builtins.elem "nixpkgs" defaults.corePackages);
        homeManagerInHome = mkTest' true (builtins.elem "home-manager" defaults.homePackages);
      };

      valueOr = {
        resolvesExistingKey = mkTest {
          desired = "bar";
          command = ''valueOr { attrs = { foo = "bar"; }; key = "foo"; default = "?"; }'';
          outcome = valueOr {
            attrs = {foo = "bar";};
            key = "foo";
            default = "?";
          };
        };
        fallsBackWhenMissing = mkTest {
          desired = "?";
          command = ''valueOr { attrs = {}; key = "foo"; default = "?"; }'';
          outcome = valueOr {
            attrs = {};
            key = "foo";
            default = "?";
          };
        };
        returnsNullWhenKeyIsNull = mkTest {
          desired = null;
          command = ''valueOr { attrs = { foo = null; }; key = "foo"; default = "?"; }'';
          outcome = valueOr {
            attrs = {foo = null;};
            key = "foo";
            default = "?";
          };
        };
        rejectsNonAttrset = mkThrows (valueOr {
          attrs = "nope";
          key = "foo";
          default = "?";
        });
      };
    };
  }
