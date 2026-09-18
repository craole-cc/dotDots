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
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.filesystem.access) readDir;
  inherit (lix.filesystem.predicates) pathExists;
  inherit (lix.lists.access) last length;
  inherit (lix.lists.aggregation) concatMap foldl';
  inherit (lix.lists.construction) optional;
  inherit (lix.lists.predicates) any elem;
  inherit (lix.lists.transformation) filter unique;
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable mkOption mkTrue;
  inherit (lix.strings.construction) concat splitString;
  inherit (lix.strings.transformation) escapeShellArgs toEnvVar;
  inherit (lix.strings.predicates) hasInfix;
  inherit (lix.types.combinators) enum listOf;
  inherit (lix.types.primitives) str;

  # Single tree walk producing both:
  #   local.directories -- local directories containing at least one
  #                        qualifying file, for PATH
  #   local.files       -- qualifying local files, for chmod
  # The store-backed source is traversed during pure evaluation, while
  # every emitted value names the corresponding mutable local path.
  discover = {
    source,
    local,
  }:
    if source == null || !(pathExists source)
    then {
      local = {
        directories = [];
        files = [];
      };
    }
    else let
      contents = readDir source;
      entries =
        filter
        (name:
          !(
            any
            (pattern: hasInfix pattern name)
            cfg.exclusions.patterns
          ))
        (attrNames contents);

      directories = map (name:
        discover {
          source = source + "/${name}";
          local = "${local}/${name}";
        }) (
        filter (
          name:
            (contents.${name} == "directory")
            && !(elem name cfg.exclusions.directories)
        )
        entries
      );

      files =
        filter (
          name:
            (contents.${name} == "regular")
            && !(
              let
                parts = splitString "." name;
              in
                (length parts > 1)
                && elem (last parts) cfg.exclusions.extensions
            )
        )
        entries;
    in {
      local = {
        directories =
          (optional (files != []) local)
          ++ (
            concatMap
            (results: results.local.directories)
            directories
          );
        files =
          (map (name: "${local}/${name}") files)
          ++ (
            concatMap
            (results: results.local.files)
            directories
          );
      };
    };

  # Keep both projections: `.store` is safe to traverse during pure flake
  # evaluation, while `.local` is the path used by the activated system.
  roots = removeAttrs paths.repo.lib ["default"];

  libraries = let
    # Traverse the store-backed Libraries tree during pure evaluation, while
    # emitting only corresponding local paths for PATH and activation.
    root = with paths.repo.lib.default; {
      source = dirOf store;
      local = dirOf local;
    };
    entries = readDir root.source;
  in {inherit root entries;};

  discovered = let
    results = map (root:
      discover (
        if pathExists (root.store + "/bin")
        then {
          source = root.store + "/bin";
          local = "${root.local}/bin";
        }
        else {
          source = root.store;
          local = root.local;
        }
      )) (
      (map (name: roots.${name}) cfg.priority)
      ++ (map (name: {
          store = libraries.root.source + "/${name}";
          local = "${libraries.root.local}/${name}";
        })
        (filter (
          name:
            (libraries.entries.${name} == "directory")
            && name != "nix"
            && !(elem name (
              map (name: baseNameOf roots.${name}.local)
              cfg.priority
            ))
        ) (attrNames libraries.entries)))
    );
  in {
    local = {
      directories = unique (
        concatMap
        (result: result.local.directories)
        results
      );
      files = unique (
        concatMap
        (result: result.local.files)
        results
      );
    };
  };

  options = {
    enable = mkEnable {inherit context;};
    chmod = mkTrue "Whether to make discovered scripts executable at system activation";
    priority = mkOption {
      description = "Library labels to place first on PATH, highest priority first";
      default = ["zig" "rs" "py" "bash" "sh"];
      type = listOf (enum (attrNames roots));
    };
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
        description = "Patterns to ignore when from paths names when discovering valid scripts";
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

  outputs = {
    environment.sessionVariables = let
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
      (toVar {value = libraries.root.local;})
      // (
        # DOTS_LIB_RS, DOTS_LIB_PY, DOTS_LIB_NU, DOTS_LIB_PWSH, DOTS_LIB_BASH,
        # DOTS_LIB_SH, DOTS_LIB_NIX -- one variable per named library root.
        foldl' (acc: suffix:
          acc
          // toVar {
            inherit suffix;
            value = roots.${suffix}.local;
          }) {}
        (attrNames roots)
      )
      // (toVar {
        name = "PATH";
        value = unique (cfg.extra ++ discovered.local.directories);
      });

    system.activationScripts.dotsScriptPermissions =
      mkIf
      (cfg.chmod && discovered.local.files != []) {
        text =
          "chmod +x -- "
          + escapeShellArgs discovered.local.files;
      };
  };
in
  mkConfig {inherit context options outputs;}
