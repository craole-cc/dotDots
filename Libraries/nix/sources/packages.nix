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
            pkgOf
            pkgsFrom
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

  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.construction) listToAttrs optionalAttrs;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.attrsets.resolution) getFlake;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs;
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.hardware.system) getSystemOrDefault;
  inherit (_.lists.aggregation) concatMap;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.sources.access) getBin getExe getExe';
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

  # -- pkgOf

  /**
  Resolve a single package by name, trying `input`'s package set first,
  then falling back to `pkgs`.

  Either `pkgs` or `system` must resolve to a real value: if `pkgs` is
  given, `system` defaults to `pkgs.stdenv.hostPlatform.system`; otherwise
  `system` must be supplied explicitly. Throws if neither is available.

  When `required` is true, throws if the package is found in neither
  source. Otherwise returns `null` on a miss.

  # Type
  ```nix
  pkgOf :: {
    inputs :: AttrSet,
    input :: string,
    name :: string,
    pkgs :: AttrSet?,
    system :: string?,
    required :: bool?
  } -> Derivation | null
  ```
  */
  pkgOf = {
    inputs,
    input,
    name,
    exe ? null,
    pkgs ? null,
    system ?
      if pkgs != null
      then pkgs.stdenv.hostPlatform.system
      else null,
    required ? false,
  }: let
    _name = "pkgOf";
    _ctx = "package '${name}' from input '${input}' or pkgs.";

    resolved = {
      inherit inputs input name pkgs;

      system = assert withContext {
        name = _name;
        context = "resolving system for ${_ctx}";
        assertion = system != null;
        message = "either `pkgs` or `system` must be provided.";
      }; system;

      source = {
        legacy =
          if pkgs != null
          then pkgs
          else
            import resolved.inputs.nixpkgs
            {inherit (resolved) system;};
        flakes =
          fromInputs
          {inherit (resolved) inputs input system;};
      };

      package = let
        value =
          resolved.source.flakes.${name} or
          (resolved.source.legacy.${name} or null);

        result =
          if value == null
          then null
          else {
            inherit name value;
            pkg = value;

            exe =
              if exe != null
              then getExe' value exe
              else getExe value;

            paths = {
              bin = "${getBin value}/bin";
              store = value.outPath or "${value}";
            };
          };
      in
        if required
        then
          assert withContext {
            name = _name;
            context = "Resolving ${_ctx}";
            assertion = result != null;
            message = "Unable to locate ${_ctx}.";
          }; result
        else result;
    };
  in
    resolved.package;

  # -- pkgsFrom

  /**
  Resolve multiple named packages via `pkgOf`, one input per name.

  `sources` maps package name -> input name, e.g.
  `{codex = "llm-agents"; hermes-agent = "hermes-agent";}` - this lets
  ambiguous names (present in more than one input) resolve to a specific
  input per-package, rather than relying on a single global priority order.

  Returns the resolved attrset (name -> derivation) merged with two
  convenience keys:
    - `names`  - `attrNames` of the resolved set
    - `values` - `attrValues` of the resolved set, for splicing into a
                  flat `packages = [...] ++ values` list

  `system` is passed straight through to `pkgOf` only when explicitly
  given; when omitted, each `pkgOf` call derives it from `pkgs` itself,
  so passing an explicit `null` here can't shadow that derivation.

  # Type
  ```nix
  pkgsFrom :: {
    inputs :: AttrSet,
    sources :: AttrSet,
    pkgs :: AttrSet?,
    system :: string?,
    required :: bool?
  } -> AttrSet
  ```
  */
  pkgsFrom = {
    inputs,
    sources,
    pkgs ? null,
    system ? null,
    required ? false,
  }: let
    raw =
      mapAttrs
      (name: input:
        pkgOf (
          {inherit inputs pkgs required input name;}
          // optionalAttrs (system != null) {inherit system;}
        ))
      sources;

    # Filter out missing packages if required = false
    filtered = filterAttrs (_: pkg: pkg != null) raw;

    names = attrNames filtered;
    values = attrValues filtered;

    # The list of actual Nix derivations (ready for buildInputs, etc.)
    packages = map (pkg: pkg.value) values;
  in
    filtered // {inherit raw filtered names values packages;};

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
