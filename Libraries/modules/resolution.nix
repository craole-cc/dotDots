{
  _,
  src,
  lib,
  ...
}: let
  inherit (_.lists.predicates) mostFrequent;
  inherit (_.modules.generators.inputs) mkInputs mkPackages mkOverlays mkModules;
  inherit (builtins) getFlake;
  inherit (lib.attrsets) attrValues genAttrs attrNames mapAttrs mapAttrsToList optionalAttrs;
  inherit (lib.debug) traceIf;
  inherit (lib.lists) findFirst unique last flatten;
  inherit (lib.strings) hasSuffix;
  inherit (lib.trivial) pathExists;

  flakePath = {
    self ? {},
    path ? src,
  }: let
    pathStr = toString path;
    result =
      if hasSuffix "/flake.nix" pathStr && pathExists pathStr
      then dirOf pathStr
      else if pathExists (pathStr + "/flake.nix")
      then pathStr
      else null;
  in
    if (self ? outPath)
    then self.outPath
    else
      traceIf (result == null)
      "❌ '${pathStr}' is not a valid flake path."
      result;

  flakeAttrs = {
    self ? {},
    path ? src,
  }: let
    normalizedPath = flakePath {inherit self path;};
    derived = optionalAttrs (normalizedPath != null) (getFlake normalizedPath);
    failureReason =
      if normalizedPath == null
      then "path normalization failed"
      else if derived == null
      then "getFlake returned null"
      else if (derived._type or null) != "flake"
      then "invalid flake type: ${(derived._type or "null")}"
      else "unknown";
  in
    if self != {}
    then self
    else
      traceIf ((derived._type or null) != "flake")
      "❌ Flake load failed: ${toString path} (${failureReason})"
      (derived // {srcPath = path;});

  getSystems = {
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
      else (getInputs {}).inputs.nixpkgs.legacyPackages or {};

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

  perFlake = {
    path ? src,
    hosts ? {},
    nixpkgs ? {},
    legacyPackages ? {},
  }:
    (getSystems {inherit path hosts nixpkgs legacyPackages;}).perFlake;

  getSystem = pkgs: pkgs.stdenv.hostPlatform.system;

  hostAttrs = {
    nixosConfigurations ?
      optionalAttrs ((flakeAttrs {}) ? nixosConfigurations)
      ((flakeAttrs {}).nixosConfigurations),
    system ? (getSystems {}).system,
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

  getInputs = {
    flake ? {},
    host ? {},
    specialArgs ? {},
    self ? {},
    path ? {},
    ...
  }: let
    flake' =
      if flake != {}
      then flake
      else flakeAttrs {inherit self path;};

    host' =
      if host != {}
      then host
      else
        hostAttrs {
          nixosConfigurations = flake.nixosConfigurations or {};
          system = host.system or (getSystems {}).system;
        };

    inputs = mkInputs {inputs = flake'.inputs;};

    config = {
      allowUnfree = host.packages.allowUnfree or false;
      allowBroken = host.packages.allowBroken or false;
    };

    packages = mkPackages {inherit inputs;};

    overlays = mkOverlays {
      inherit (inputs) nixpkgs-stable nixpkgs-unstable;
      inherit packages config;
    };

    modules = mkModules {
      inherit
        inputs
        packages
        specialArgs
        ;
      host = host';
    };

    nixpkgs =
      {
        hostPlatform = host.system;
        inherit config overlays;
      }
      // (
        if (host.class or "nixos") == "darwin"
        then {source = inputs.nixpkgs.outPath;}
        else {flake.source = flake.outPath;}
      );
  in {
    inherit
      inputs
      nixpkgs
      modules
      overlays
      packages
      ;
  };

  # =============================================================
  __doc = ''
    Flake stuff
  '';
  exports = {
    inherit
      flakeAttrs
      flakePath
      getInputs
      getSystem
      getSystems
      hostAttrs
      perFlake
      ;

    getFlake = flakeAttrs;
    getHost = hostAttrs;
    getSystemsPerFlake = perFlake;
  };
in
  exports
  // {
    inherit __doc;
    _rootAliases = {
      inherit flakePath;
      inherit (exports) getSystems getSystem getFlake getHost;
    };
  }
