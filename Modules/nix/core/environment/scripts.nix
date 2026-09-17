{
  config,
  lix,
  paths,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "environment";
    mod = "scripts";
  };
  inherit (context) cfg;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.filesystem.access) readDir;
  inherit (lix.filesystem.predicates) pathExists;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.lists.access) last length;
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.lists.construction) optional;
  inherit (lix.strings.construction) splitString;
  inherit (lix.lists.transformation) filter unique;
  inherit (lix.lists.predicates) elem;
  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) str;

  excludedDirs = paths.exclusions.directories;

  # Extensions that are never "the script itself" even when they live
  # inside a language tree (docs, data, lockfiles, etc). Mirrors
  # dots.sh's DOTS_BINIT_BLACKLIST_EXT so the two stay in sync.
  defaultBlacklistExt = [
    "md"
    "txt"
    "json"
    "yaml"
    "yml"
    "toml"
    "lock"
    "png"
    "jpg"
    "jpeg"
    "gif"
    "svg"
    "pdf"
  ];

  hasBlacklistedExt = blacklist: name: let
    parts = splitString "." name;
  in
    (length parts > 1) && elem (last parts) blacklist;

  # A string -> path coercion trick: `/.` is the root path, and
  # `path + string` concatenates then re-parses as a path. `dir` here
  # is already an absolute string (e.g. from `paths.repo.lib.sh`), so
  # this just changes its *type* to something readDir will accept.
  asPath = dir: /. + dir;

  # Recursively collect directories that contain at least one
  # qualifying file, pruning excluded directory names *before*
  # descending -- so anything under review/, archive/, backup/, etc.
  # is never even read, same as rg's --glob exclusion in dots.sh.
  scriptDirs = blacklist: dir:
    if !(pathExists (asPath dir))
    then []
    else let
      entries = readDir (asPath dir);
      names = attrNames entries;

      dirs = filter (n: entries.${n} == "directory" && !(elem n excludedDirs)) names;
      files = filter (n: entries.${n} == "regular" && !(hasBlacklistedExt blacklist n)) names;

      children = concatMap (n: scriptDirs blacklist "${dir}/${n}") dirs;
    in
      (optional (files != []) dir) ++ children;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {inherit context;};
      blacklistExtensions = mkOption {
        description = "File extensions to ignore when discovering script directories";
        default = defaultBlacklistExt;
        type = listOf str;
      };
      extra = mkOption {
        description = "Additional directories to prepend to PATH, highest priority first";
        default = [];
        type = listOf str;
      };
    };
    outputs = with cfg; {
      environment.sessionPath =
        extra
        ++ unique (
          concatMap (scriptDirs blacklistExtensions)
          (with paths.repo.lib; [rs py nu pwsh bash sh])
        );
    };
  }
