{
  _,
  lib,
  ...
}: let
  __doc = ''
    Module Evaluation and System Generation

    Provides the orchestration layer for turning discovered hosts, resolved
    flake inputs, generated package sets, and assembled module lists into
    fully evaluated system configurations.

    This file is responsible for two major tasks:

    1. Evaluating host systems via `evalModules`.
    2. Generating per-system flake-style output matrices from a function.
  '';

  __exports = {
    internal = {
      inherit mkSystems mkFlakeOutputs mkCore mkHome mkTree;
    };
    external = {inherit mkSystems mkFlakeOutputs;};
  };

  inherit (_.filesystem.tree) mkTree;
  inherit (_.hardware.system) getSystems;
  inherit (_.sources.modules) mkModules;
  inherit (_.sources.packages) mkPackages;
  inherit (_.modules.core._) mkCore;
  inherit (_.modules.home._) mkHome;
  inherit (lib.attrsets) attrNames genAttrs mapAttrs;
  inherit (lib.modules) evalModules;

  /**
  Evaluate all hosts from the discovered schema into concrete system outputs.

  Builds the repository tree, derives the host schema, resolves flake inputs,
  generates package and module sets for each host, and evaluates the final
  module graph through `lib.modules.evalModules`.

  For Darwin hosts, this also exposes the built system derivation under
  `system` for easier downstream consumption.

  # Args:
    self: Optional already-evaluated flake.
    path: Filesystem path to the source flake.
    args: Extra arguments merged into `specialArgs`.
    ...: Additional arguments reserved for future extension.

  # Returns:
    An attrset keyed by host name, where each value is the evaluated module
    result for that host.
  */
  mkSystems = {
    inputs,
    tree,
    schema,
    extraArgs ? {},
    ...
  }:
    mapAttrs (
      _: host: let
        inherit (host.paths) dots;
        class = host.class or "nixos";
        tree' = tree // {local = tree.mkLocal dots;};

        specialArgs =
          {inherit host class;} // extraArgs // {tree = tree';};

        flakeArgs = let
          packages = mkPackages {inherit host inputs;};
          modules = mkModules {inherit class inputs;};
        in {inherit inputs packages modules;};

        modules = let
          fromInputs = flakeArgs.modules;

          fromHost = mkCore {
            inherit host specialArgs;
            inherit (flakeArgs) modules inputs;
            inherit (flakeArgs.packages) nixpkgs;
            tree = tree';
          };

          fromEval = evalModules {
            specialArgs =
              specialArgs
              // {
                inherit (fromInputs.all) modulesPath baseModules;
                modules = fromInputs // {host = fromHost;};
              };
            modules =
              []
              ++ fromInputs.base
              ++ fromInputs.core
              ++ fromHost
              ++ (host.imports or [])
              ++ [tree'.store.mod.core]
              ++ [{config._module.args = specialArgs;}];
          };
        in {inherit fromInputs fromHost fromEval;};
      in
        if class == "darwin"
        then
          modules.fromEval
          // {system = modules.fromEval.config.system.build.toplevel;}
        else modules.fromEval
    )
    schema.hosts;

  /**
  Generate system-indexed flake-style outputs from a function.

  Evaluates the provided function for every supported system, then inverts
  the result so top-level output names map to per-system values such as
  `packages.<system>.*`, `devShells.<system>.*`, or similar output groups.

  # Args:
    flake: Optional flake providing legacy package sets.
    nixpkgs: Optional nixpkgs input.
    legacyPackages: Optional pre-evaluated legacy package attrset.
    system: Preferred system to use for deriving output names.
    hosts: Optional host definitions used to derive supported systems.
    fn: Function receiving `{ system, pkgs }` and returning flake-style outputs.

  # Returns:
    An attrset whose top-level keys are output groups and whose values are
    attrsets keyed by system.
  */
  mkFlakeOutputs = {
    flake ? {},
    nixpkgs ? {},
    legacyPackages ? {},
    system ? builtins.currentSystem or null,
    hosts ? {},
    fn,
  }: let
    inherit
      (getSystems {
        inherit
          flake
          nixpkgs
          legacyPackages
          system
          hosts
          ;
      })
      pkgsFor
      derived
      all
      ;

    perSystem = (genAttrs all) (sys:
      fn {
        system = sys;
        pkgs = pkgsFor sys;
      });

    names = attrNames (fn {
      system = derived;
      pkgs = pkgsFor derived;
    });
  in
    genAttrs names (
      name:
        mapAttrs (_: outputs: outputs.${name}) perSystem
    );
in
  __exports.internal
  // {
    inherit __doc;
    _rootAliases = __exports.external;
  }
