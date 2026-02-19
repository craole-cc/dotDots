{
  _,
  lib,
  ...
}: let
  inherit (_.modules.resolution) getSystem;
  inherit (lib.attrsets) filterAttrsRecursive mapAttrs mapAttrs';

  mkPackages = {inputs}: {
    #~@ Core
    nixpkgs-stable = inputs.nixpkgs-stable.legacyPackages or {};
    nixpkgs-unstable = inputs.nixpkgs-unstable.legacyPackages or {};
    home-manager = inputs.home-manager.packages or {};

    #~@ Applications
    dank-material-shell = inputs.dank-material-shell.packages or {};
    fresh-editor = inputs.fresh-editor.packages or {};
    helix = inputs.helix.packages or {};
    noctalia-shell = inputs.noctalia-shell.packages or {};
    nvf = inputs.nvf.packages or {};
    plasma = inputs.plasma.packages or {};
    quickshell = inputs.quickshell.packages or {};
    caelestia = inputs.caelestia.packages or {};
    catppuccin = inputs.catppuccin.packages or {};
    treefmt = inputs.treefmt.packages or {};
    typix = inputs.typix.packages or {};
    vscode-insiders = inputs.vscode-insiders.packages or {};
    zen-browser = inputs.zen-browser.packages or {};
  };

  mkOverlays = {
    inputs,
    packages,
    config,
  }: [
    #~@ Stable
    (final: prev: {
      fromStable = import inputs.nixpkgs-stable {
        inherit config;
        system = getSystem final;
      };
    })

    #~@ Unstable
    (final: prev: {
      fromUnstable = import inputs.nixpkgs-unstable {
        inherit config;
        system = getSystem final;
      };
    })

    #~@ Flake inputs
    #? Flattened packages (higher priority)
    (final: prev:
      filterAttrsRecursive (name: value: value != null) (
        mapAttrs' (_name: pkgsSet: {
          name = _name;
          value = pkgsSet.${getSystem prev}.${"default"} or null;
        })
        packages
      ))

    #? Categorized (lower priority, for browsing)
    (final: prev: {
      fromInputs =
        mapAttrs (
          _: pkgs: pkgs.${getSystem prev} or {}
        )
        packages;
    })

    #~@ Chaotic overlay
    (inputs.chaotic.overlays.default or (_: _: {}))
  ];
  exports = {inherit mkPackages mkOverlays;};
in
  exports // {_rootAliases = exports;}
