{
  collisionStrategy ? "warn",
  excludedDirs ? [],
  excludedFiles ? [],
  excludedPatterns ? [],
  allowAliases ? false,
  allowTests ? false,
  paths ? {},
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
  in
    recursiveUpdate args {
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
            src.store = ../../.;
            lib.default.store = ./.;
            api.default.store = ../../API/nix;
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

  init = import ./_ derived;

  defined = let
    _ = init.libraries.default;
    inherit (_.attrsets.aggregation) recursiveUpdate;
    inherit (_.filesystem.construction) mkTree;
    inherit (_.schema.construction) mkSchema;

    schema = mkSchema {
      api = init.paths.repo.api.default.store;
    };

    # API-owned structural tree used when no physical host is selected.
    # Its repository store projection is sufficient for importing modules,
    # while host-specific local paths are supplied only by explicit hosts.
    structuralPaths = mkTree {
      inherit (schema.paths) roots stems;
    };

    selected =
      if args ? host
      then {
        host = args.host;
        inherit (args.host) paths;
      }
      else {paths = structuralPaths;};
  in
    recursiveUpdate init ({inherit schema;} // selected);

  eval = defined;
in
  eval
