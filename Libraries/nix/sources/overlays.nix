{_, ...}: let
  __doc = ''
    Input Overlays Generation

    Constructs Nixpkgs overlays from flake inputs. It provides stable and
    unstable channels, flattens default packages directly onto `pkgs`, and
    extracts named variants to avoid broad evaluation errors.
  '';

  inherit (_.hardware.system) systemOf;
  inherit (_.attrsets.transformation) mapAttrs mapAttrs' removeNulls;

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

  #~@ Core overlays - stable/unstable nixpkgs channels

  stable = {
    inputs,
    config,
  }: final: _: let
    system = systemOf final;
  in {
    fromStable = import (inputs.nixpkgs-stable or inputs.nixpkgs) {inherit system config;};
  };

  unstable = {
    inputs,
    config,
  }: final: _: let
    system = systemOf final;
  in {
    fromUnstable = import (inputs.nixpkgs-unstable or inputs.nixpkgs) {inherit system config;};
  };

  #~@ Home overlays - flake input packages

  #> Flattened - exposes each input's default package directly on pkgs.
  #> Inputs listed in `exclude` remain available under pkgs.fromInputs but do
  #> not replace an existing nixpkgs package of the same name.
  flattened = {
    packages,
    exclude ? [],
  }: _final: prev: let
    system = systemOf prev;
    resolve = pkgsSet: let
      val = pkgsSet.${system} or null;
    in
      if val == null
      then null
      else if val ? outPath
      then val # ? already a derivation
      else val.default or null; # ? attrset -> pick .default
  in
    removeNulls (
      mapAttrs' (name: pkgsSet: {
        inherit name;
        value = resolve pkgsSet;
      })
      (removeAttrs packages exclude)
    );

  #> Variant expansion - explicitly expose named variants for known multi-output inputs
  #> Avoids forcing evaluation of entire nixpkgs attrsets (which causes AAAAAASomeThingsFailToEvaluate)
  variant = {packages}: _final: prev: let
    system = systemOf prev;
    zen = packages."zen-browser".${system} or {};
  in {
    #> zen-browser - required by the zen-browser HM module which looks up pkgs.zen-twilight
    zen-twilight = zen.twilight or zen.default or null;
    zen-beta = zen.beta or zen.default or null;
  };

  #> Categorised - exposes all input package sets under pkgs.fromInputs.<name>
  #> e.g. pkgs.fromInputs.helix = { default = ...; helix = ...; }
  fromInputs = {packages}: _final: prev: {
    fromInputs =
      mapAttrs
      (_: pkgsSet: pkgsSet.${systemOf prev} or null)
      packages;
  };

  #~@ Builder functions

  mkCore = {
    inputs,
    config,
  }: [
    (stable {inherit inputs config;})
    (unstable {inherit inputs config;})
  ];

  mkHome = {
    inputs,
    packages,
  }:
    [
      # The application registry resolves Helix from nixpkgs. Keep the flake
      # input available for explicit consumers without allowing its default
      # package to shadow pkgs.helix during whole-system evaluation.
      (flattened {
        inherit packages;
        exclude = ["helix"];
      })
      (variant {inherit packages;})
      (fromInputs {inherit packages;})
    ]
    ++ (with inputs; [
      (rust-overlay.overlays.default or (_: _: {}))
      (chaotic.overlays.default or (_: _: {}))
      (codex.overlays.default or (_: _: {}))
    ]);

  mkAll = {
    config,
    inputs,
    packages,
  }:
    mkCore {inherit inputs config;}
    ++ mkHome {inherit inputs packages;};
in
  __exports.internal
  // {
    inherit __doc;
    __rootAliases = __exports.external;
  }
