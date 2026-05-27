{_, ...}: let
  meta = {
    doc = ''
      Input Packages Resolution

      Builds the complete package sets and Nixpkgs instances from resolved inputs.
      It threads configurations and generated overlays into a finalized `nixpkgs`
      attribute set ready for system evaluation.
    '';

    exports = {
      internal = let
        functions = {
          inherit
            mkCore
            mkHome
            mkAll
            mkOne
            fromInputs
            ;
        };
        aliases = {
          mkPkgs = mkAll;
          mkPackages = mkAll;
          mkPackage = mkOne;
          mkPackageFromInputs = fromInputs;
          mkCorePackages = mkCore;
          mkHomePackages = mkHome;
        };
      in
        {inherit functions aliases;} // functions // aliases;

      external = {
        mkInputOverlays = mkOverlays;
        mkInputPackages = mkAll;
        mkPackageFromInputs = fromInputs;
        mkInputPackage = mkOne;
        mkCoreInputPackages = mkCore;
        mkHomeInputPackages = mkHome;
      };
    };
  };

  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.construction) listToAttrs optionalAttrs;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.attrsets.resolution) getFlake;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs;
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.hardware.system) getSystemOrDefault;
  inherit (_.lists.aggregation) concatMap;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.sources.inputs) normalize mkSource;
  inherit (_.sources.overlays) mkOverlays;

  defaults = {
    config = {
      allowUnfree = true;
      allowBroken = false;
    };
    core = {
      attrs = "legacyPackages";
      names = [
        "nixpkgs"
        "nixpkgs-stable"
        "nixpkgs-unstable"
      ];
    };
    home = {
      attrs = "packages";
      names = [
        "age"
        "caelestia"
        "catppuccin"
        "dank-material-shell"
        "dms-plugin-registry"
        "fresh-editor"
        "helix"
        "hermes-agent"
        "home-manager"
        "llm-agents"
        "noctalia-shell"
        "nvf"
        "plasma"
        "quickshell"
        "treefmt"
        "typix"
        "vscode-insiders"
        "zen-browser"
      ];
    };
  };

  mkCore = {
    inputs ? {},
    names ? [],
  }:
    mkOne {
      inherit inputs;
      inherit (defaults.core) attrs;
      names = defaults.core.names ++ names;
    };

  mkHome = {
    inputs ? {},
    names ? [],
  }:
    mkOne {
      inherit (defaults.home) attrs;
      inherit inputs;
      names = defaults.home.names ++ names;
    };

  fromInputs = {
    inputs,
    system,
    input,
  }:
    inputs.${input}.packages.${system} or {};

  bySystem = packages: let
    inputNames = attrNames packages;

    systems = unique (
      concatMap
      (name: attrNames (packages.${name} or {}))
      inputNames
    );

    inputsFor = system:
      filter
      (name: hasAttr system (packages.${name} or {}))
      inputNames;
  in
    listToAttrs (
      map (system: {
        name = system;
        value = listToAttrs (
          map (name: {
            inherit name;
            value = packages.${name}.${system};
          })
          (inputsFor system)
        );
      })
      systems
    );

  mkOne = {
    inputs,
    attrs,
    names,
  }:
    listToAttrs (
      map (name: {
        inherit name;
        value = inputs.${name}.${attrs} or {};
      })
      names
    );

  mkAll = {
    flake ? {},
    host ? {},
    inputs ? {},
    # nixpkgs ? {},
    system ? null,
    config ? {},
    coreNames ? [],
    homeNames ? [],
  }: let
    inputs' = normalize (
      if isNotEmpty inputs
      then inputs
      else if isNotEmpty flake
      then flake
      else getFlake {}
    );

    system' = getSystemOrDefault {
      inputs = inputs';
      inherit host system;
    };

    config' = let
      pkgs = host.packages or {};
    in
      {
        allowUnfree = pkgs.allowUnfree or defaults.allowUnfree;
        allowBroken = pkgs.allowBroken or defaults.allowBroken;
      }
      // config;

    packages = let
      raw =
        mkCore {
          inputs = inputs';
          names = coreNames;
        }
        // mkHome {
          inputs = inputs';
          names = homeNames;
        };
    in
      filterAttrs (_name: value: isNotEmpty value) raw;

    overlays = mkOverlays {
      inherit packages;
      inputs = inputs';
      config = config';
    };

    nixpkgs' = let
      source = let
        src = mkSource {
          inherit host;
          input = inputs'.nixpkgs or null;
        };
      in
        optionalAttrs (isNotEmpty src) (src.flake.source or src.source);
    in
      source
      // {
        inputs = inputs';
        legacyPackages =
          mapAttrs
          (sys: base: base // ((bySystem packages).${sys} or {}))
          (inputs'.nixpkgs.legacyPackages or {});
      };
  in {
    inherit packages overlays;

    inputs = inputs';
    config = config';
    nixpkgs = nixpkgs';

    pkgs = import inputs'.nixpkgs {
      inherit overlays;
      system = system';
      config = config';
    };
  };
in
  with meta.exports;
    internal
    // {
      __docs = meta.doc;
      __rootAliases = external;
    }
