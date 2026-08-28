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
  inherit (builtins) attrNames isAttrs mapAttrs;

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

  resolved = let
    defaults =
      mergeAttrs {
        inherit allowAliases allowTests collisionStrategy;

        names = {
          top = names.top or "dots";
          lib = names.lib or "lix";
          src = names.src or (flake.name or "dots");
        };

        exclusions = {
          dirs = excludedDirs;
          files = excludedFiles;
          patterns = excludedPatterns;
        };
      }
      args;
  in
    defaults
    // {
      paths =
        mergeAttrs defaults.paths
        {
          src = (paths.src or {}) // {store = ../../.;};
          lib = (paths.lib or {}) // {store = ./.;};
        };
    }
    // (
      let
        flake' =
          if flake != null && isAttrs flake
          then flake
          else if (builtins ? getFlake)
          then let
            inherit (builtins) getFlake pathExists;
            inherit (resolved.paths) src;
          in
            if pathExists (toString src + "/flake.nix")
            then getFlake (toString src)
            else {}
          else {};
      in
        if flake' != {}
        then {
          flake = mergeAttrs flake' {
            name = flake'.name or resolved.names.src;
            path = flake'.path or resolved.src.store;
            home = flake'.home or resolved.src.local;
          };
        }
        else {}
    )
    // {
      lib =
        if lib != null
        then lib
        else if resolved.flake.inputs ? nixpkgs
        then resolved.flake.inputs.nixpkgs.lib
        else if resolved.flake.inputs ? nixPackages
        then resolved.flake.inputs.nixPackages.lib
        else import <nixpkgs/lib>;
    };
in
  import ./internal resolved
