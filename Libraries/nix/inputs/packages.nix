{
  _,
  lib,
  ...
}: let
  __doc = ''
    Input Packages Resolution

    Builds the complete package sets and Nixpkgs instances from resolved inputs.
    It threads configurations and generated overlays into a finalized `nixpkgs`
    attribute set ready for system evaluation.
  '';

  # Updated to the new function names
  inherit (_.inputs.source) resolveInputs sourceInput;
  inherit (_.inputs.overlays) mkOverlays;
  inherit (lib.attrsets) listToAttrs;

  __exports = {
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
      inputs = (resolveInputs {}).resolved // inputs;
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
      inputs = (resolveInputs {}).resolved // inputs;
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
    pkgs = host.packages or{};
    config' =
      {
        allowUnfree = pkgs.allowUnfree or true;
        allowBroken = pkgs.allowBroken or false;
      }
      // config;

    inputs' = (resolveInputs {}).resolved // inputs;

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
      // sourceInput {
        inherit host;
        input = inputs'.nixpkgs or null;
      };
  in {
    inherit nixpkgs packages overlays;
    inputs = inputs';
    config = config';
  };
in
  __exports.internal
  // {
    inherit __doc;
    _rootAliases = __exports.external;
  }
