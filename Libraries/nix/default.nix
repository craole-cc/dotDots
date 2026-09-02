{
  collisionStrategy ? "warn",
  excludedDirs ? [],
  excludedFiles ? [],
  excludedPatterns ? [],
  flake ? {},
  lib ? null,
  names ? {},
  allowAliases ? false,
  allowTests ? false,
  stores ? {
    lib = ./.;
    src = ../../.;
    api = ../../API/nix;
  },
  host ? {},
  schema ? null,
  paths ? {},
  ...
} @ args: let
  derived = let
    inherit (builtins) head tail;

    /*
    Finds the first element in a list matching a predicate function,
    returning `null` if no element satisfies the predicate.

    Evaluates lazily and short-circuits as soon as a match is found.

    # Type:
    > findFirstOrNull :: (a -> Bool) -> [a] -> (a | Null)
    */
    findFirstOrNull = predicate: list:
      if list == []
      then null
      else if predicate (head list)
      then (head list)
      else findFirstOrNull predicate (tail list);

    /*
    Normalizes a flake attribute set by locating its primary Nixpkgs input
    and ensuring standard attributes are populated.

    Scans `flake.inputs` against common Nixpkgs attribute aliases
    verified by the presence of `legacyPackages` and `lib.trivial`.

    # Type:
    ```nix
      normalizeFlake :: {
        flake :: AttrSet,
        name ? null,
        path ? null
      } -> (AttrSet | Null)
    ```

    # Example:
      - Given a flake with `inputs.unstable` ("nixpkgs/nixos-unstable"):
      ```nix
        normalizeFlake {
          flake = myFlake;
          name = "my-flake";
          path = "/nix/store/...";
        } -> {
          inputs = { unstable = <...>; nixpkgs = <...>; };
          name = "my-flake";
          path = "/nix/store/...";
          ...
        }
      ```
    */
    normalizeFlake = {
      flake,
      name ? names.src,
      path ? stores.src,
    }: let
      checks = {
        source = flake:
          flake ? inputs
          && (
            (flake._type or "" == "flake")
            || flake ? sourceInfo
            || flake ? outputs
          );
        inputs = input:
          input ? legacyPackages
          && input ? lib.trivial;
      };
    in
      if checks.source flake
      then let
        nixpkgsKey =
          findFirstOrNull
          (input: checks.inputs flake.inputs.${input})
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
          ];

        update = {
          #> Update inputs to include a canonical nixpkgs alias
          inputs = flake.inputs // {nixpkgs = flake.inputs.${nixpkgsKey};};

          #> Populate standard attributes with explicit fallbacks
          name = flake.name or name;
          path = flake.path or flake.outPath or path;
        };
      in
        if nixpkgsKey != null
        then flake // update
        else null
      else null;

    /*
    Resolves and normalizes a valid Nix library (`lib`) instance using a 3-tier strategy:
    1. Provided `lib` parameter (if valid and contains `lib.trivial`).
    2. The `lib` exported by the normalized flake's primary Nixpkgs input.
    3. Ambient system `<nixpkgs/lib>` via NIX_PATH lookup.

    # Type:
    ```nix
      normalizeLib :: {
        lib ? null,
        flake ? null
      } -> AttrSet
    ```

    # Example:
    ```nix
      normalizeLib {
        lib = myLib;
        flake = myFlake;
      } ->  {
        attrsets = <...>;
        lists = <...>;
        ...
        trivial = <...>;
        ...
      }
    ```
    */
    normalizeLib = {
      lib ? null,
      flake ? null,
    }: let
      checks = {
        flake = flake: flake ? inputs.nixpkgs.lib;
        lib = lib: lib ? trivial;
      };

      flake' =
        if checks.flake flake
        then flake
        else normalizeFlake {inherit flake;};

      lib' =
        if checks.lib lib
        then lib
        else if checks.flake flake'
        then flake'.inputs.nixpkgs.lib
        else import <nixpkgs/lib>;
    in
      if checks.lib lib'
      then lib'
      else throw "Failed to resolve a valid Nix library instance (lib.trivial not found).";

    names' = {
      top = names.top or "_";
      lib = names.lib or "lix";
      prefix = names.prefix or ".";
      src = names.src or (flake.name or "dots");
    };

    flake' = normalizeFlake {
      inherit flake;
      name = names'.src;
      path = stores.src;
    };

    lib' = normalizeLib {
      inherit lib;
      flake = flake';
    };
    inherit (lib'.attrsets) recursiveUpdate;

    seed = recursiveUpdate args {
      flake = flake';
      lib = lib';
      names = names';
      paths =
        recursiveUpdate {
          repo = {
            src.store = stores.src;
            lib.default.store = stores.lib;
            api.default.store = stores.api;
          };
        }
        paths;
      settings = {
        inherit allowAliases allowTests collisionStrategy;
        exclusions = {
          dirs = excludedDirs;
          files = excludedFiles;
          patterns = excludedPatterns;
        };
      };
    };
    context = import ./internal seed;
  in
    context;

  defined = let
    _ = derived.libraries.default;
    inherit (_.attrsets.aggregation) recursiveUpdate;
    inherit (_.schema.construction) mkSchema;
    schema = mkSchema {
      api = derived.paths.repo.api.default.store;
      host = derived.host or {};
    };
    host = schema.hosts.default;

    seed = recursiveUpdate derived {
      inherit schema host;
      inherit (host) paths;
    };
    # context =
  in
    seed;
in
  defined
