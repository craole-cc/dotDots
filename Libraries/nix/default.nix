{
  collisionStrategy ? "warn",
  excludedDirs ? [],
  excludedFiles ? [],
  excludedPatterns ? [],
  allowAliases ? false,
  allowTests ? false,
  stores ? {
    lib = ./.;
    src = ../../.;
    api = ../../API/nix;
    build = ./internal;
  },
  ...
} @ args: let
  derived = let
    lib = let
      nixpkgs = args.inputs.${args.nixpkgsTag or "nixPackages"} or {};
      isValib = target: target ? attrsets.attrNames && target ? trivial;
      lib' =
        if isValib (args.lib or null)
        then args.lib
        else if isValib (nixpkgs.lib or {})
        then nixpkgs.lib
        else import <nixpkgs/lib>;
    in
      if isValib lib'
      then lib'
      else throw "Failed to resolve a valid Nix library instance (lib.trivial not found).";

    inherit (lib.attrsets) recursiveUpdate;

    seed = recursiveUpdate args {
      inherit lib;
      names =
        recursiveUpdate {
          top = "_";
          lib = "lix";
          prefix = ".";
          src = "dots";
        }
        (args.names or {});

      paths =
        recursiveUpdate {
          repo = {
            src.store = stores.src;
            lib.default.store = stores.lib;
            api.default.store = stores.api;
          };
        }
        (args.paths or {});

      settings = {
        inherit allowAliases allowTests collisionStrategy;
        exclusions = {
          dirs = excludedDirs;
          files = excludedFiles;
          patterns = excludedPatterns;
        };
      };
    };
    context = import stores.build seed;
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
