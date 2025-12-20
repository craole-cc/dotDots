{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) genAttrs mapAttrsToList optionalAttrs;
  inherit (lib.strings) hasSuffix;
  inherit (lib.trivial) pathExists;
  inherit (lib.debug) traceIf;
  inherit (lib.lists) unique last;
  inherit (_.lists.predicates) mostFrequent;
  inherit (_.lists.attrsets) nestedByPaths;

  flakePkgs = path:
    nestedByPaths {
      attrset = flake path;
      paths = [
        ["inputs" "nixosCore"]
        ["inputs" "nixPackages"]
        ["inputs" "nixosPackages"]
        ["inputs" "nixpkgs-unstable"]
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
    traceIf (result != null)
    result
    "❌ '${pathStr}' is not a valid flake path.";

  flake = path: let
    normalizedPath = flakePath path;
    loadResult = optionalAttrs (normalizedPath != null) (builtins.getFlake normalizedPath);
    failureReason =
      if normalizedPath == null
      then "path normalization failed"
      else if loadResult == null
      then "getFlake returned null"
      else if (loadResult._type or null) != "flake"
      then "invalid flake type: ${(loadResult._type or "null")}"
      else "unknown";
    result =
      if (loadResult._type or null) == "flake"
      then loadResult // {srcPath = path;}
      else loadResult;
  in
    traceIf ((loadResult._type or null) == "flake")
    result
    "❌ Flake load failed: ${toString path} (${failureReason})";

  systems = {
    src ? null,
    hosts ? {},
    nixpkgs ? {},
    legacyPackages ? {},
  }: let
    pkgsBase =
      if legacyPackages != {}
      then legacyPackages
      else if nixpkgs?legacyPackages
      then nixpkgs.legacyPackages
      else if src != null
      then (flakePkgs src).legacyPackages
      else {};

    #> Extract and flatten defined systems
    defined = lib.flatten (mapAttrsToList (_: host: host.system or host.platforms or []) hosts);

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
      else last default; # "x86_64-linux"

    all = unique (defined ++ default);
    per = genAttrs all;
    pkgs = optionalAttrs (pkgsBase ? derived) pkgsBase.${derived};
    pkgsFor = system: pkgsBase.${system} or {};
  in {
    inherit all default derived defined per pkgs;
    inherit legacyPackages pkgsFor;
    system = derived;
  };
  __doc = ''
    Flake stuff
  '';
  exports = {
    inherit
      flake
      flakePath
      flakePkgs
      systems
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
    };
  }
