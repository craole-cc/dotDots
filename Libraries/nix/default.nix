{
  collisionStrategy ? "warn",
  excludedDirs ? [
    "review"
    "archive"
    "internal"
    "imports"
    "data"
    "test"
    "tmp"
    "temp"
    "wip"
    "deprecated"
    "experimental"
    "backup"
  ],
  excludedFiles ? [
    "default.nix"
    "flake.nix"
  ],
  excludedPatterns ? [
    " copy.nix"
    ".test.nix"
    ".spec.nix"
    ".bak.nix"
    ".old.nix"
  ],
  flake ? null,
  lib ? null,
  names ? null,
  paths ? null,
  allowAliases ? false,
  allowTests ? false,
  ...
} @ args: let
  inherit (builtins) attrNames foldl' isAttrs mapAttrs;

  mergeAttrs = set1: set2:
    if isAttrs set1 && isAttrs set2
    then
      (mapAttrs (key: value:
        if set1 ? ${key}
        then mergeAttrs set1.${key} value
        else value)
      set2)
      // removeAttrs set1 (attrNames set2)
    else set2;

  findFirst = pred: default: list:
    foldl'
    (
      acc: x:
        if acc != default
        then acc #? already found
        else if pred x
        then x #? this one matches
        else default
    )
    default
    list;

  attrsIf = name: value:
    if ((value != null) && (isAttrs value) && (value != {}))
    then {"${name}" = value;}
    else {};

  isFlakeLike = value:
    isAttrs value
    && value ? inputs
    && isAttrs value.inputs
    && (
      (value ? _type && value._type == "flake")
      || value ? sourceInfo
      || value ? outputs
    );

  isNixpkgsLike = value:
    isAttrs value
    && value ? lib
    && (value ? legacyPackages || value ? packages);

  implicit = {
    inherit allowAliases allowTests collisionStrategy;

    names = {
      top = names.top or "dots";
      lib = names.lib or "lix";
      src = names.src or (flake.name or "dots");
    };

    paths = {
      src = (paths.src or {}) // {store = ../../.;};
      lib = (paths.lib or {}) // {store = ./.;};
    };

    exclusions = {
      dirs = excludedDirs;
      files = excludedFiles;
      patterns = excludedPatterns;
    };
  };

  explicit = mergeAttrs implicit args;

  resolved = let
    paths' = let
      raw = let
        base = explicit.paths;
      in {
        lib = base.lib or (base.libraries or {});
        src = base.src or (base.flake or {});
      };
      normalized = {
        lib = raw.lib // {store = raw.lib.store or ./.;};
        src = raw.src // {store = raw.src.store or ../../.;};
      };
    in {
      lib = normalized.lib;
      libraries = normalized.lib;
      src = normalized.src;
      flake = normalized.src;
    };

    flake' = let
      raw =
        if flake != null && isAttrs flake
        then
          mergeAttrs flake {
            name = flake.name or explicit.names.src;
            path = flake.path or paths'.src.store;
            home = flake.home or (paths'.src.local or null);
          }
        else {};

      core =
        if isFlakeLike raw
        then
          findFirst
          (name: isNixpkgsLike (raw.inputs.${name} or null))
          null
          [
            "nixpkgs"
            "nixPackages"
            "nixPackagesUnstable"
            "nixPackagesStable"
            "nixpkgs-unstable"
            "nixpkgs-stable"
            "unstable"
            "stable"
            "nixos"
            "pkgs"
          ]
        else null;
    in
      if raw == {}
      then {}
      else
        raw
        // {
          inputs =
            if core != null && core != "nixpkgs"
            then raw.inputs // {nixpkgs = raw.inputs.${core};}
            else raw.inputs or {};
        };

    lib' =
      if lib != null && isAttrs lib
      then lib
      else if flake' ? inputs && flake'.inputs ? nixpkgs
      then flake'.inputs.nixpkgs.lib
      else import <nixpkgs/lib>;
  in
    explicit
    // {
      inherit flake';
      paths' = {
        lib = paths'.lib.store;
        src = paths'.src.store;
      };
    }
    // attrsIf "paths" paths'
    // attrsIf "flake" flake'
    // attrsIf "lib" lib';
in
  import ./internal resolved
