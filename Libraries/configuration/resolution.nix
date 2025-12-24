{
  _,
  src,
  lib,
  ...
}: let
  inherit (lib.attrsets) attrValues genAttrs attrNames mapAttrs mapAttrsToList optionalAttrs;
  inherit (lib.strings) hasSuffix;
  inherit (lib.trivial) pathExists;
  inherit (lib.debug) traceIf;
  inherit (lib.lists) findFirst unique last flatten;
  inherit (_.lists.predicates) mostFrequent;
  inherit (_.attrsets.resolution) byPaths;

  flakePkgs = {path ? src}:
    byPaths {
      attrset = (flake {inherit path;}).inputs or {};
      paths = [
        ["nixosCore"]
        ["nixPackages"]
        ["nixosPackages"]
        ["nixpkgs-unstable"]
      ];
      default = "nixpkgs";
    };

  flakePath = path: let
    pathStr = toString path;
    result =
      if hasSuffix "/flake.nix" pathStr && pathExists pathStr
      then dirOf pathStr
      else if pathExists (pathStr + "/flake.nix")
      then pathStr
      else null;
  in
    traceIf (result == null)
    "❌ '${pathStr}' is not a valid flake path."
    result;

  flake = {path ? src}: let
    normalizedPath = flakePath path;
    derived = optionalAttrs (normalizedPath != null) (builtins.getFlake normalizedPath);
    failureReason =
      if normalizedPath == null
      then "path normalization failed"
      else if derived == null
      then "getFlake returned null"
      else if (derived._type or null) != "flake"
      then "invalid flake type: ${(derived._type or "null")}"
      else "unknown";
  in
    traceIf ((derived._type or null) != "flake")
    "❌ Flake load failed: ${toString path} (${failureReason})"
    (derived // {srcPath = path;});

  systems = {
    path ? src,
    hosts ? {},
    nixpkgs ? {},
    legacyPackages ? {},
  }: let
    pkgsBase =
      if legacyPackages != {}
      then legacyPackages
      else if nixpkgs ? legacyPackages
      then nixpkgs.legacyPackages
      else let
        f = flakePkgs {inherit path;};
      in
        optionalAttrs
        (f ? legacyPackages)
        f.legacyPackages;

    #> Extract and flatten defined systems
    defined = flatten (mapAttrsToList (_: host:
      host.platform or host.system or [])
    hosts);

    #> Default systems in alphabetical order
    default = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];

    #> Get most common defined system, or tail of default
    derived = let
      common = mostFrequent defined null;
    in
      if common != null
      then common
      else last default;

    all = unique (defined ++ default);
    per = genAttrs all;
    pkgsFor = system: pkgsBase.${system} or {};

    # Enhanced perFlake that provides pkgs automatically
    perFlake = fn: let
      perSystemOutputs = per (system:
        fn {
          inherit system;
          pkgs = pkgsFor system;
        });
      outputNames = attrNames (fn {
        system = derived;
        pkgs = pkgsFor derived;
      });
    in
      genAttrs outputNames (
        outputName:
          mapAttrs (_: systemOutputs: systemOutputs.${outputName}) perSystemOutputs
      );
  in {
    inherit all default derived defined per pkgsFor perFlake;
    system = derived;
    inherit pkgsBase;
    pkgs = pkgsFor derived;
  };

  host = {
    nixosConfigurations ?
      optionalAttrs ((flake {}) ? nixosConfigurations)
      ((flake {}).nixosConfigurations),
    system ? (systems {}).system,
  }: let
    derived =
      findFirst
      (h: (h.config.nixpkgs.hostPlatform.system or null) == system)
      null
      (attrValues nixosConfigurations);
  in
    traceIf ((derived.class or null) != "nixos")
    "❌ Failed to derive current host"
    (derived // {name = derived.config.networking.hostName;});

  # =============================================================
  __doc = ''
    Flake stuff
  '';
  exports = {
    inherit
      flake
      flakePath
      flakePkgs
      systems
      host
      ;
  };
in
  exports
  // {
    inherit __doc;
    _rootAliases = {
      inherit flakePath;
      getFlake = flake;
      getSystems = systems;
      getNixPkgs = flakePkgs;
      getHost = host;
    };
  }
