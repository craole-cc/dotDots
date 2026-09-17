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
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable mkOption mkTrue;
  inherit (lix.strings.construction) concat splitString;
  inherit (lix.strings.transformation) escapeShellArgs toEnvVar;
  inherit (lix.strings.predicates) hasInfix;

  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) str;

  # True if `name` contains any of the configured exclusion patterns
  # as a substring -- e.g. "script copy.sh" matched by " copy.".
  matchesPattern = name: any (pattern: hasInfix pattern name) cfg.exclusions.patterns;

  hasBlacklistedExt = name: let
    parts = splitString "." name;
  in
    (length parts > 1) && elem (last parts) cfg.exclusions.extensions;
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
      entries = readDir source;
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

      childResults = map (name:
        discover {
          source = source + "/${name}";
          local = "${local}/${name}";
        }) subdirs;
    in {
      local = {
        directories =
          (optional (localFiles != []) local)
          ++ (concatMap (result: result.local.directories) childResults);
        files =
          (map (name: "${local}/${name}") localFiles)
          ++ (concatMap (result: result.local.files) childResults);
      };
    };

  # rs > py > nu > pwsh > bash > sh -- label order here IS PATH
  # priority order downstream, since `unique` keeps first occurrence.
  labels = ["rs" "py" "nu" "pwsh" "bash" "sh"];

  # Keep both projections: `.store` is safe to traverse during pure flake
  # evaluation, while `.local` is the path used by the activated system.
  roots = with paths.repo.lib;
    listToAttrs (map (name: {
        inherit name;
        value = getAttr name {inherit rs py nu pwsh bash sh;};
      })
      labels);

  discovered = let
    results = map (name:
      discover {
        source = roots.${name}.store;
        local = roots.${name}.local;
      })
    labels;
  in {
    local = {
      directories = unique (concatMap (result: result.local.directories) results);
      files = unique (concatMap (result: result.local.files) results);
    };
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
          value = roots.${suffix}.local;
        }) {}
      labels
    )
    // (toVar {
      name = "PATH";
      value = unique (cfg.extra ++ discovered.local.directories);
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
      environment = {
        inherit sessionVariables;
      };

      system = {
        activationScripts.dotsScriptPermissions = mkIf (cfg.chmod && discovered.local.files != []) {
          text = "chmod +x -- " + escapeShellArgs discovered.local.files;
        };
      };
    };
  }
