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
  inherit (_.inputs.generators) normalizedPackages;

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

  flakeAttrs = {path ? src}: let
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
      else normalizedPackages {inherit path;};

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

  system = pkgs: pkgs.stdenv.hostPlatform.system;

  host = {
    nixosConfigurations ?
      optionalAttrs ((flakeAttrs {}) ? nixosConfigurations)
      ((flakeAttrs {}).nixosConfigurations),
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

  # inputs = {
  # };

  # =============================================================
  __doc = ''
    Flake stuff
  '';
  exports = {
    inherit
      flakeAttrs
      flakePath
      host
      system
      systems
      ;

    # inherit
    #   (core)
    #   nixpkgs
    #   nixpkgs-stable
    #   nixpkgs-unstable
    #   home-manager
    #   ;
    # inherit
    #   (home)
    #   dank-material-shell
    #   noctalia-shell
    #   nvf
    #   plasma
    #   zen-browser
    #   ;
  };
in
  exports
  // {
    inherit __doc;
    _rootAliases = {
      inherit flakePath;
      getFlake = flakeAttrs;
      getSystems = systems;
      getSystem = system;
      getHost = host;
    };
  }
