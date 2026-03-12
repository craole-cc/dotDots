{
  _,
  lib,
  ...
}: let
  inherit (_.lists.predicates) mostFrequent;
  inherit (_.contents.fallback) orDefault;
  inherit (_.debug.assertions) mkTest mkTest';
  inherit (_.debug.runners) runTests;
  inherit (lib.attrsets) attrNames genAttrs mapAttrs mapAttrsToList;
  inherit (lib.lists) all elem flatten last unique;

  /**
  Derive a complete system set from optional host and nixpkgs inputs.

  # Type
  ```nix
  getSystems :: { hosts?, nixpkgs?, legacyPackages? } -> { all, default, defined, system, per, perFlake, pkgs, pkgsBase, pkgsFor }
  ```
  */
  getSystems = {
    hosts ? {},
    nixpkgs ? {},
    legacyPackages ? {},
  }: let
    pkgsBase = orDefault {
      content = legacyPackages;
      default = orDefault {
        content = nixpkgs.legacyPackages or {};
        default = {};
      };
    };

    defined = flatten (mapAttrsToList (_: host: host.platform or host.system or []) hosts);
    default = ["aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux"];
    derived = orDefault {
      content = mostFrequent defined null;
      default = last default;
    };

    all = unique (defined ++ default);
    per = genAttrs all;
    pkgsFor = system: pkgsBase.${system} or {};

    perFlake = fn: let
      perSystemOutputs = per (system:
        fn {
          inherit system;
          pkgs = pkgsFor system;
        });
      outputNames = attrNames (fn {
        system = derived;
        pkgs = pkgsFor derived;
      });
    in
      genAttrs outputNames
      (outputName: mapAttrs (_: systemOutputs: systemOutputs.${outputName}) perSystemOutputs);
  in {
    inherit all default defined derived per pkgsBase pkgsFor perFlake;
    system = derived;
    pkgs = pkgsFor derived;
  };

  /**
  Extract the host platform string from a pkgs attrset.

  # Type
  ```nix
  getSystem :: AttrSet -> string
  ```
  */
  getSystem = pkgs: pkgs.stdenv.hostPlatform.system;

  /**
  Convenience wrapper returning `getSystems.perFlake` directly.
  */
  perFlake = {
    hosts ? {},
    nixpkgs ? {},
    legacyPackages ? {},
  }:
    (getSystems {inherit hosts nixpkgs legacyPackages;}).perFlake;

  exports = {
    inherit getSystem getSystems perFlake;
    getSystemsPerFlake = perFlake;
  };
in
  exports
  // {
    _rootAliases = {
      inherit (exports) getSystem getSystems getSystemsPerFlake;
    };

    _tests = runTests {
      getSystems = {
        defaultSystemIsX86 = mkTest {
          desired = "x86_64-linux";
          outcome = (getSystems {}).system;
          command = "(getSystems {}).system";
        };
        allContainsDefaults = mkTest {
          desired = true;
          outcome =
            all (s: elem s (getSystems {}).all)
            ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
          command = "all default systems present in getSystems {}.all";
        };
        usesHostPlatform = mkTest {
          desired = "aarch64-linux";
          outcome = (getSystems {hosts.myHost.platform = "aarch64-linux";}).system;
          command = ''(getSystems { hosts.myHost.platform = "aarch64-linux"; }).system'';
        };
        definedIncludesHostPlatform = mkTest {
          desired = true;
          outcome =
            elem "aarch64-linux"
            (getSystems {hosts.myHost.platform = "aarch64-linux";}).defined;
          command = ''elem "aarch64-linux" (getSystems {...}).defined'';
        };
        emptyHostsGivesEmptyDefined = mkTest' [] (getSystems {}).defined;
        pkgsForReturnsEmptyWhenNoPkgs = mkTest' {} ((getSystems {}).pkgsFor "x86_64-linux");
        allIsUnique = mkTest {
          desired = true;
          outcome = let sys = getSystems {hosts.a.platform = "x86_64-linux";}; in sys.all == unique sys.all;
          command = "getSystems {hosts.a.platform = ...}.all == unique ...all";
        };
      };
    };
  }
