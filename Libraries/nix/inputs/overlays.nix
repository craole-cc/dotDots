{
  _,
  lib,
  ...
}: let
  inherit (_.hardware.system) getSystem;
  inherit (lib.attrsets) filterAttrsRecursive mapAttrs mapAttrs';

  exports = {
    internal = {
      inherit mkCore mkHome mkAll;
      mkOverlays = mkAll;
    };
    external = {
      mkInputOverlays = mkAll;
      mkInputCoreOverlays = mkCore;
      mkInputHomeOverlays = mkHome;
    };
  };

  #~@ Core overlays — stable/unstable nixpkgs channels

  stableOverlay = {
    inputs,
    config,
  }: final: _: let
    system = getSystem final;
  in {
    fromStable = import (inputs.nixpkgs-stable or inputs.nixpkgs) {
      inherit system config;
    };
  };

  unstableOverlay = {
    inputs,
    config,
  }: final: _: let
    system = getSystem final;
  in {
    fromUnstable = import (inputs.nixpkgs-unstable or inputs.nixpkgs) {
      inherit system config;
    };
  };

  #~@ Home overlays — flake input packages

  #> Flattened — exposes each input's default package directly on pkgs
  #> e.g. pkgs.helix = inputs.editorHelix.packages.${system}.default
  flattenedOverlay = {packages}: final: prev: let
    system = getSystem prev;
    resolve = pkgsSet: let
      val = pkgsSet.${system} or null;
    in
      if val == null
      then null
      else if val ? outPath
      then val #? already a derivation
      else val.default or null; #? attrset → pick .default
  in
    filterAttrsRecursive (_: v: v != null) (
      mapAttrs' (name: pkgsSet: {
        inherit name;
        value = resolve pkgsSet;
      })
      packages
    );

  #> Variant expansion — explicitly expose named variants for known multi-output inputs
  #> Avoids forcing evaluation of entire nixpkgs attrsets (which causes AAAAAASomeThingsFailToEvaluate)
  variantOverlay = {packages}: final: prev: let
    system = getSystem prev;
    zenPkgs = packages."zen-browser".${system} or {};
  in {
    #> zen-browser — required by the zen-browser HM module which looks up pkgs.zen-twilight
    zen-twilight = zenPkgs.twilight or zenPkgs.default or null;
    zen-beta = zenPkgs.beta     or zenPkgs.default or null;
  };

  #> Categorised — exposes all input package sets under pkgs.fromInputs.<name>
  #> e.g. pkgs.fromInputs.helix = { default = ...; helix = ...; }
  fromInputsOverlay = {packages}: final: prev: let
    system = getSystem prev;
  in {
    fromInputs = mapAttrs (_: pkgsSet: pkgsSet.${system} or null) packages;
  };

  #~@ Builder functions

  mkCore = {
    inputs,
    config,
  }: [
    (stableOverlay {inherit inputs config;})
    (unstableOverlay {inherit inputs config;})
  ];

  mkHome = {
    inputs,
    packages,
  }: [
    (flattenedOverlay {inherit packages;})
    (variantOverlay {inherit packages;})
    (fromInputsOverlay {inherit packages;})
    #~@ Chaotic nyx overlay
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
