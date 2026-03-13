{
  _,
  lib,
  ...
}: let
  __doc = ''
    Hardware System Derivation

    Provides utilities for extracting, calculating, and resolving Nix hardware
    architectures (e.g., `x86_64-linux`, `aarch64-darwin`). It intelligently
    derives the correct system string by parsing explicitly defined hosts,
    falling back to sensible defaults, and mapping architecture strings back
    to evaluated Nixpkgs instances.
  '';

  inherit (_.lists.predicates) mostFrequent;
  inherit (_.debug.assertions) mkTest mkTest';
  inherit (_.debug.runners) runTests;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.lists) all elem flatten last unique;
  currentSystem = builtins.currentSystem or null;

  __exports = {
    internal = {inherit systemOf getPackages getSystems;};
    external = {inherit systemOf getPackages getSystems;};
  };

  /**
  Extracts the host platform string from an evaluated packages set.

  Provides a clean, explicit way to read the underlying system architecture
  from a Nixpkgs instance without directly chaining attributes. Designed to
  mirror the naming conventions of Nix builtins like `dirOf` or `typeOf`.

  Type:
    systemOf :: AttrSet -> string

  Args:
    pkgs: An evaluated Nixpkgs attribute set.

  Returns:
    The system architecture string (e.g., "x86_64-linux").
  */
  systemOf = pkgs: pkgs.stdenv.hostPlatform.system;

  /**
  Resolves and normalizes Nixpkgs package sets.

  Provides a safe fallback mechanism to prevent evaluation errors when
  systems are missing or pure evaluation blocks `builtins.currentSystem`.

  Args:
    flake: The current flake's inputs.
    nixpkgs: The nixpkgs input.
    legacyPackages: Pre-evaluated legacy packages.
    system: An explicit system string (e.g., "x86_64-linux").

  Returns:
    pkgsBase: The root attribute set containing all evaluated systems.
    pkgsFor: A function taking a system string and returning its packages.
    pkgs: The evaluated packages for the provided (or default) system.
  */
  getPackages = {
    flake ? {},
    nixpkgs ? {},
    legacyPackages ? {},
    system ? currentSystem,
  }: let
    pkgsBase =
      if legacyPackages != {}
      then legacyPackages
      else flake.legacyPackages or nixpkgs.legacyPackages or {};

    pkgsFor = sys:
      if sys == null
      then import <nixpkgs> {}
      else pkgsBase.${sys} or (import <nixpkgs> {system = sys;});

    pkgs = pkgsFor system;
  in {
    inherit pkgsBase pkgsFor pkgs;
  };

  /**
  Calculates the required system architectures based on defined hosts.

  Extracts system strings from a given `hosts` set and combines them with
  a default list. Determines the most reliable "derived" system to use
  for evaluating top-level flake attributes.

  Args:
    hosts: An attribute set of machine configurations to extract systems from.
    (Inherits all arguments from getPackages)

  Returns:
    all: A unique list of all defined and default system strings.
    defined: Systems explicitly found in the hosts set.
    default: The baseline fallback systems.
    derived: The highest-priority system architecture to use as a primary.
    system: Alias for `derived`.
    pkgs: Packages evaluated specifically for the `derived` system.
  */
  getSystems = {
    flake ? {},
    nixpkgs ? {},
    legacyPackages ? {},
    system ? currentSystem,
    hosts ? {},
  }: let
    inherit
      (getPackages {
        inherit flake nixpkgs legacyPackages system;
      })
      pkgsBase
      pkgsFor
      ;

    #~@ Types Lists
    defined = flatten (
      mapAttrsToList (
        _: host: host.platform or host.system or []
      )
      hosts
    );
    default = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];
    all = unique (defined ++ default);

    #~@ Selection
    common = mostFrequent defined null;
    derived =
      #? Give an explicitly passed 'system' argument highest priority
      if system != null
      then system
      else if common != null
      then common
      else last default;
  in {
    inherit all default defined derived pkgsBase pkgsFor;
    system = derived;
    pkgs = pkgsFor derived;
  };
in
  __exports.internal
  // {
    inherit __doc;
    _rootAliases = __exports.external;
    _tests = runTests {
      getSystems = {
        defaultSystemIsX86 = mkTest {
          desired = "x86_64-linux";
          outcome = (getSystems {system = null;}).system;
          command = "(getSystems { system = null; }).system";
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
          # Pass system = null so the test relies entirely on the 'hosts' attribute
          outcome =
            (getSystems {
              system = null;
              hosts.myHost.platform = "aarch64-linux";
            }).system;
          command = ''(getSystems { system = null; hosts.myHost.platform = "aarch64-linux"; }).system'';
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
