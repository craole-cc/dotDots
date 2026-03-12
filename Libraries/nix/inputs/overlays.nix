{
  _,
  lib,
  ...
}: let
  inherit (_.hardware.system) getSystem;
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
      resolve = pkgsSet: let
        val = pkgsSet.${system} or null;
      in
        if val == null
        then null
        else if val ? outPath
        then val
        else val.default or null;

      resolveVariants = name: pkgsSet: let
        val = pkgsSet.${system} or null;
      in
        if val == null || val ? outPath
        then {}
        else
          #> Expose each variant as pkgs.<name>-<variant>
          mapAttrs' (variant: drv: {
            name = "${name}-${variant}";
            value = drv;
          }) (lib.filterAttrs (_: v: v ? outPath) val);
    in
      filterAttrsRecursive (_: v: v != null) (
        mapAttrs' (name: pkgsSet: {
          inherit name;
          value = resolve pkgsSet;
        })
        packages
      )
      //
      # Also expose zen-twilight, zen-beta etc. individually
      lib.foldAttrs lib.const {} (
        lib.mapAttrsToList resolveVariants packages
      ))
    #~@ Flake inputs — categorised (lower priority)
    (final: prev: let
      system = getSystem prev;
    in {
      fromInputs =
        mapAttrs (_: pkgsSet: pkgsSet.${system} or null)
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
