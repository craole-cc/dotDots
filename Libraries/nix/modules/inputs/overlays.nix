{
  _,
  lib,
  ...
}: let
  inherit (_.hardware.system) getSystem;
  inherit (_.attrsets.predicates) valueOr;
  inherit (lib.attrsets) filterAttrsRecursive mapAttrs mapAttrs';
  exports = {
    internal = {
      inherit
        mkCore
        mkHome
        mkAll
        ;
      mkOverlays = mkAll;
    };
    external = {
      mkInputOverlays = mkAll;
      mkInputCoreOverlays = mkCore;
      mkInputHomeOverlays = mkHome;
    };
  };

  mkCore = {
    inputs,
    config,
  }: [
    (final: _: let
      system = getSystem final;
    in {
      fromStable = import (inputs.nixpkgs-stable or inputs.nixpkgs) {
        inherit system config;
      };
    })

    (final: _: let
      system = getSystem final;
    in {
      fromUnstable = import (inputs.nixpkgs-unstable or inputs.nixpkgs) {
        inherit system config;
      };
    })
  ];

  mkHome = {
    inputs,
    packages,
  }: [
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

  mkAll = {
    config,
    inputs,
    packages,
  }:
    []
    ++ mkCore {inherit inputs config;}
    ++ mkHome {inherit inputs packages;};
in
  exports.internal // {_rootAliases = exports.external;}
