{
  config,
  lix,
  paths,
  names,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "environment";
    mod = "scripts";
  };
  inherit (context) cfg;
  inherit (lix.attrsets.access) attrNames getAttr;
  inherit (lix.attrsets.construction) listToAttrs;
  inherit (lix.filesystem.access) readDir;
  inherit (lix.filesystem.predicates) pathExists;
  inherit (lix.lists.access) last length;
  inherit (lix.lists.aggregation) concatMap foldl';
  inherit (lix.lists.construction) optional;
  inherit (lix.lists.predicates) any elem;
  inherit (lix.lists.transformation) filter unique;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption mkTrue;
  inherit (lix.strings.construction) concat splitString;
  inherit (lix.strings.predicates) hasInfix;
  inherit (lix.strings.transformation) escapeShellArgs toEnvVar;
  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) str;

  # A string -> path coercion trick: `/.` is the root path, and
  # `path + string` concatenates then re-parses as a path. `dir` here
  # must already be a resolved absolute-path *string* (paths.repo.lib.*
  # is an { env, local, stem, store } set -- `.local` is the concrete
  # on-disk string, the only representation readDir can walk).
  asPath = dir: /. + dir;

  # True if `name` contains any of the configured exclusion patterns
  # as a substring -- e.g. "script copy.sh" matched by " copy.".
  matchesPattern = name: any (pattern: hasInfix pattern name) cfg.exclusions.patterns;

  hasBlacklistedExt = name: let
    parts = splitString "." name;
  in
    (length parts > 1) && elem (last parts) cfg.exclusions.extensions;

  # Single tree walk producing both:
  #   dirs  -- directories containing at least one qualifying file,
  #            for PATH (same rule as before: pruning excluded dir
  #            names, blacklisted extensions, and pattern matches
  #            before descending)
  #   files -- the qualifying files themselves, full path, for chmod
  # Previously this would've needed two separate readDir passes over
  # the same tree; one recursion now serves both consumers.
  discover = dir:
    if !(pathExists (asPath dir))
    then {
      dirs = [];
      files = [];
    }
    else let
      entries = readDir (asPath dir);
      entryNames = filter (name: !(matchesPattern name)) (attrNames entries);

      subdirs =
        filter (
          name:
            (entries.${name} == "directory")
            && !(elem name cfg.exclusions.directories)
        )
        entryNames;

      localFiles =
        filter (
          name:
            (entries.${name} == "regular")
            && !(hasBlacklistedExt name)
        )
        entryNames;

      childResults = map (name: discover "${dir}/${name}") subdirs;
    in {
      dirs =
        (optional (localFiles != []) dir)
        ++ (concatMap (r: r.dirs) childResults);
      files =
        (map (name: "${dir}/${name}") localFiles)
        ++ (concatMap (r: r.files) childResults);
    };

  # rs > py > nu > pwsh > bash > sh -- label order here IS PATH
  # priority order downstream, since `unique` keeps first occurrence.
  labels = ["rs" "py" "nu" "pwsh" "bash" "sh"];

  # { rs = "/.../rust"; py = "/.../python"; ... } -- .local pulls the
  # resolved filesystem string out of each { env, local, stem, store } set.
  roots = with paths.repo.lib;
    listToAttrs (map (name: {
        inherit name;
        value =
          (
            getAttr name
            {inherit rs py nu pwsh bash sh;}
          ).local;
      })
      labels);

  discovered = let
    results = map (name: discover roots.${name}) labels;
  in {
    dirs = unique (concatMap (r: r.dirs) results);
    files = unique (concatMap (r: r.files) results);
  };

  sessionVariables = let
    toVar = {
      name ? null,
      suffix ? null,
      value,
    }:
      toEnvVar (
        if name != null
        then name
        else (concat "_" [(names.src or "dots") "lib" suffix])
      )
      value;
  in
    (toVar {value = dirOf paths.repo.lib.default.local;})
    // (
      # DOTS_LIB_RS, DOTS_LIB_PY, DOTS_LIB_NU, DOTS_LIB_PWSH, DOTS_LIB_BASH,
      # DOTS_LIB_SH -- one var per language root, pointing at its resolved dir.
      foldl' (acc: suffix:
        acc
        // toVar {
          inherit suffix;
          value = roots.${suffix};
        }) {}
      labels
    )
    // (toVar {
      name = "PATH";
      value = unique (cfg.extra ++ discovered.dirs);
    });
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {inherit context;};
      chmod = mkTrue "Whether to make discovered scripts executable at system activation";
      exclusions = {
        extensions = mkOption {
          description = "File extensions to ignore when discovering valid scripts";
          default = [
            "bac"
            "bak"
            "gif"
            "jpeg"
            "jpg"
            "json"
            "lock"
            "md"
            "old"
            "pdf"
            "png"
            "svg"
            "toml"
            "txt"
            "yaml"
            "yml"
          ];
          type = listOf str;
        };

        directories = mkOption {
          description = "Directories to ignore when discovering valid scripts";
          default =
            paths.exclusions.directories or [
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
            ];
          type = listOf str;
        };

        patterns = mkOption {
          description = "Substrings to exclude from paths names when discovering valid scripts";
          default =
            paths.exclusions.patterns or [" copy."];
          type = listOf str;
        };
      };
      extra = mkOption {
        description = "Additional directories to prepend to PATH, highest priority first";
        default = [];
        type = listOf str;
      };
    };
    outputs =
      {environment = {inherit sessionVariables;};}
      // (
        if cfg.chmod && discovered.files != []
        then {
          system.activationScripts.dotsScriptPermissions.text =
            "chmod +x -- " + escapeShellArgs discovered.files;
        }
        else {}
      );
  }
