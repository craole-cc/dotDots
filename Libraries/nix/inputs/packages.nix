{
  _,
  lib,
  ...
}: let
  inherit (_.inputs.source) mkInputs mkNixPkgs;
  inherit (_.inputs.overlays) mkOverlays;
  inherit (lib.attrsets) listToAttrs;
  exports = {
    internal = {
      inherit
        mkCore
        mkHome
        mkAll
        mkOne
        ;
      mkPackages = mkAll;
      mkPackage = mkOne;
      mkCorePackages = mkCore;
      mkHomePackages = mkHome;
    };
    external = {
      mkInputOverlays = mkOverlays;
      mkInputPackages = mkAll;
      mkInputPackage = mkOne;
      mkCoreInputPackages = mkCore;
      mkHomeInputPackages = mkHome;
    };
  };

  mkCore = {
    inputs ? {},
    names ? [],
  }:
    mkOne {
      attrs = "legacyPackages";
      inputs = mkInputs {} // inputs;
      names =
        [
          "nixpkgs"
          "nixpkgs-stable"
          "nixpkgs-unstable"
        ]
        ++ names;
    };

  mkHome = {
    inputs ? {},
    names ? [],
  }:
    mkOne {
      attrs = "packages";
      inputs = mkInputs {} // inputs;
      names =
        [
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
        ]
        ++ names;
    };

  mkOne = {
    inputs,
    attrs,
    names,
  }:
    listToAttrs (map (name: {
        inherit name;
        value = inputs.${name}.${attrs} or {};
      })
      names);

  mkAll = {
    host ? {},
    inputs ? {},
    config ? {},
    coreNames ? [],
    homeNames ? [],
  }: let
    config' =
      {
        allowUnfree = host.packages.allowUnfree or true;
        allowBroken = host.packages.allowBroken or false;
      }
      // config;

    inputs' = mkInputs {} // inputs;

    packages =
      mkCore {
        inputs = inputs';
        names = coreNames;
      }
      // mkHome {
        inputs = inputs';
        names = homeNames;
      };

    overlays = mkOverlays {
      inherit packages;
      inputs = inputs';
      config = config';
    };

    nixpkgs =
      {
        inherit overlays;
        config = config';
        hostPlatform = host.system;
      }
      // mkNixPkgs {
        class = host.class or "nixos";
        inputs = inputs';
      };
  in {
    inherit nixpkgs packages overlays;
    inputs = inputs';
    config = config';
  };
in
  exports.internal // {_rootAliases = exports.external;}
