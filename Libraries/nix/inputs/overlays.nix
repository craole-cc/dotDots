{
  _,
  lib,
  ...
}: let
  __doc = ''
    Input Overlays Generation

    Constructs Nixpkgs overlays from flake inputs. It provides stable and
    unstable channels, flattens default packages directly onto `pkgs`, and
    extracts named variants to avoid broad evaluation errors.
  '';

  inherit (_.hardware.system) systemOf;
  inherit (lib.attrsets) filterAttrs mapAttrs mapAttrs';

  __exports = {
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
    system = systemOf final;
  in {
    fromStable = import (inputs.nixpkgs-stable or inputs.nixpkgs) {
      inherit system config;
    };
  };

  unstableOverlay = {
    inputs,
    config,
  }: final: _: let
    system = systemOf final;
  in {
    fromUnstable = import (inputs.nixpkgs-unstable or inputs.nixpkgs) {
      inherit system config;
    };
  };

  #~@ Home overlays — flake input packages

  #> Flattened — exposes each input's default package directly on pkgs
  #> e.g. pkgs.helix = inputs.editorHelix.packages.${system}.default
  flattenedOverlay = {packages}: final: prev: let
    system = systemOf prev;
    resolve = pkgsSet: let
      val = pkgsSet.${system} or null;
    in
      if val == null
      then null
      else if val ? outPath
      then val #? already a derivation
      else val.default or null; #? attrset → pick .default
  in
    filterAttrs (_: v: v != null) (
      mapAttrs' (name: pkgsSet: {
        inherit name;
        value = resolve pkgsSet;
      })
      packages
    );

  #> Variant expansion — explicitly expose named variants for known multi-output inputs
  #> Avoids forcing evaluation of entire nixpkgs attrsets (which causes AAAAAASomeThingsFailToEvaluate)
  variantOverlay = {packages}: final: prev: let
    system = systemOf prev;
    zen = packages."zen-browser".${system} or {};
  in {
    #> zen-browser — required by the zen-browser HM module which looks up pkgs.zen-twilight
    zen-twilight = zen.twilight or zen.default or null;
    zen-beta = zen.beta     or zen.default or null;
  };

  #> Categorised — exposes all input package sets under pkgs.fromInputs.<name>
  #> e.g. pkgs.fromInputs.helix = { default = ...; helix = ...; }
  fromInputsOverlay = {packages}: final: prev: let
    system = systemOf prev;
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
  __exports.internal
  // {
    inherit __doc;
    _rootAliases = __exports.external;
  }
