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
      inherit mkFlake;
      mkFlakeOutputs = mkFlake;
    };
    external = {inherit (__exports.internal) mkFlakeOutputs;};
  };

  inherit (_.hardware.system) getSystems;
  inherit (lib.attrsets) attrNames genAttrs mapAttrs;

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
  mkFlake = {
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
