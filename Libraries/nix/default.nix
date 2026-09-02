{
  collisionStrategy ? "warn",
  excludedDirs ? [],
  excludedFiles ? [],
  excludedPatterns ? [],
  flake ? {},
  inputs ? null,
  nixpkgs ? null,
  lib ? null,
  names ? {},
  allowAliases ? false,
  allowTests ? false,
  stores ? {
    lib = ./.;
    src = ../../.;
    api = ../../API/nix;
  },
  paths ? {},
  ...
} @ args: let
  derived = let
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
      inputs ? {},
    }: let
      checks = {
        lib = target: target ? attrsets.attrNames && target ? trivial;
        inputs = target: target ? nixpkgs.lib && checks.lib target.nixpkgs.lib;
      };

      lib' =
        if checks.lib lib
        then lib
        else if checks.inputs inputs
        then inputs.nixpkgs.lib
        else import <nixpkgs/lib>;
    in
      if checks.lib lib'
      then lib'
      else throw "Failed to resolve a valid Nix library instance (lib.trivial not found).";

    names' = {
      top = names.top or "_";
      lib = names.lib or "lix";
      prefix = names.prefix or ".";
      src = names.src or "dots";
    };

    lib' = normalizeLib {inherit lib inputs;};
    inherit (lib'.attrsets) recursiveUpdate;

    seed = recursiveUpdate args {
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
