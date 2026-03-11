{
  _,
  lib,
  ...
}: let
  inherit (_.attrsets.predicates) valueOr;
  inherit (_.content.fallback) firstNonEmpty;
  inherit (_.filesystem.paths) flakeOrNull;
  inherit (_.filesystem.paths) source;
  inherit (_.hardware.system) getSystem;
  inherit (lib.attrsets) filterAttrsRecursive listToAttrs mapAttrs mapAttrs';

  exports = {
    internal = {
      inherit
        mkInputs
        mkOverlays
        mkPackages
        mkSource
        ;
    };
    external = {
      # inputPackages = resolved;
      mkInputOverlays = mkOverlays;
      mkInputPackages = mkPackages;
      mkInputSource = mkSource;
    };
  };

  mkInputs = {flake ? flakeOrNull {}}: let
    raw = flake.inputs;
  in
    raw;

  mkPackages = {
    host,
    inputs ? {},
    config ? {},
    core ? ["nixpkgs" "nixpkgs-stable" "nixpkgs-unstable"],
    home ? [
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
    ],
  }: let
    config' =
      {
        allowUnfree = host.packages.allowUnfree or true;
        allowBroken = host.packages.allowBroken or false;
      }
      // config;

    inputs' = _.inputs.resolution.inputs // inputs;

    packages =
      mkPackageSet {
        inputs = inputs';
        attrs = "legacyPackages";
        names = core;
      }
      // mkPackageSet {
        inputs = inputs';
        attrs = "packages";
        names = home;
      };

    overlays = mkOverlays {
      inherit packages;
      inputs = inputs';
      config = config';
    };

    nixpkgs =
      {
        inherit config overlays;
        hostPlatform = host.system;
      }
      // source {
        inherit host;
        inputs = inputs';
      };
  in {
    inherit nixpkgs packages overlays;
    inputs = inputs';
    config = config';
  };

  mkPackageSet = {
    inputs,
    attrs,
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
            key = attrs;
            default = {};
          };
      })
      names);

  mkOverlays = {
    config,
    inputs,
    packages,
  }: let
    inputs' = inputs // _.inputs.resolution.inputs;
  in [
    #~@ Stable
    (final: _: let
      system = getSystem final;
    in {
      fromStable = import (inputs'.nixpkgs-stable or inputs'.nixpkgs) {
        inherit system config;
      };
    })
    #~@ Unstable
    (final: _: let
      system = getSystem final;
    in {
      fromUnstable = import (inputs.nixpkgs-unstable or inputs'.nixpkgs) {
        inherit system config;
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

  /**
  Build the `nixpkgs` source attribute set appropriate for the host class.

  Darwin uses `source`; NixOS uses `flake.source`.

  # Type
  ```nix
  mkSource :: { host? :: AttrSet, root? :: any, inputs? :: AttrSet } -> AttrSet
  ```
  */
  mkSource = {
    host ? {},
    root ? null,
    inputs ? {},
    ...
  }: let
    root' = firstNonEmpty [root (inputs.nixpkgs or null)];
  in
    if (host.class or "nixos") == "darwin"
    then {source = root';}
    else {flake.source = root';};
in
  exports.internal // {_rootAliases = exports.external;}
