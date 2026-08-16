{
  lib ? null,
  flake ? null,
  root ? null,
}: let
  inherit
    (builtins)
    attrNames
    concatStringsSep
    filter
    genList
    isAttrs
    isString
    mapAttrs
    pathExists
    replaceStrings
    split
    stringLength
    substring
    ;

  #> --------------------------------------------------------------------
  #> Bootstrap: builtins-only helpers, used only until `_` (real lix) is
  #> reachable. Nothing here should be relied on after `_` is loaded -
  #> everything downstream should route through `_.filesystem.tree.mkTree`
  #> / `_.filesystem.primitives.construct` instead, so there is exactly
  #> one source of truth for path resolution post-bootstrap.
  #> --------------------------------------------------------------------
  bootstrap = rec {
    /**
    Safely reads an environment variable, returning a fallback default if unset or empty.

    # Arguments
    `env` (string)
    : The name of the environment variable to query.

    `default` (any)
    : The fallback value to return if the environment variable is empty or unset.
    */
    getEnv = env: default: let
      resolved = builtins.getEnv env;
    in
      if resolved != ""
      then resolved
      else default;

    /**
    Safely imports a file at the given path if it exists on disk; otherwise returns an empty set.

    # Arguments
    `path` (path or string)
    : The filesystem path to check and conditionally import.
    */
    importAttr = path:
      if pathExists path
      then import path
      else {};

    /**
    Recursively merges two attribute sets (right-hand set2 overrides left-hand set1).
    Nested attrsets are merged key-by-key; any other value type is replaced outright.

    # Arguments
    `set1` (attrset)
    : The base attribute set.

    `set2` (attrset)
    : The overriding attribute set whose values take precedence.
    */
    mergeAttrs = set1: set2:
      if isAttrs set1 && isAttrs set2
      then
        (
          mapAttrs (
            key: value:
              if set1 ? ${key}
              then mergeAttrs set1.${key} value
              else value
          )
          set2
        )
        // removeAttrs set1 (attrNames set2)
      else set2;

    /**
    Returns true if `str` starts with `prefix`. Builtins-only stand-in for
    `lib.strings.hasPrefix`, needed here because `lib` may not be available
    at bootstrap time.
    */
    hasPrefix = prefix: str:
      substring 0 (stringLength prefix) str == prefix;

    /**
    Strips `prefix` from the start of `str` if present; otherwise returns
    `str` unchanged. Builtins-only stand-in for `lib.strings.removePrefix`.
    */
    removePrefix = prefix: str:
      if hasPrefix prefix str
      then
        substring (stringLength prefix)
        (stringLength str - stringLength prefix)
        str
      else str;

    /**
    Bootstrap-only stand-in for `_.filesystem.primitives.construct` - only
    needed until real lix is reachable. Recursively resolves stems (attrset,
    list, or string) into `{ store, local }` records. `store` is `null`
    whenever the resolved path is not relative to `base` (mirrors the
    "not under src -> null" rule enforced by the real `construct`).

    # Arguments
    `base` (attrset)
    : An attribute set containing `{ store, local }` root paths.

    `stem` (attrset, list, or string)
    : A path stem, or nested attribute set of stems, to resolve.
    */
    asPath = {
      stem,
      base,
    }: let
      stringToCharacters = str:
        genList
        (char: substring char 1 str)
        (stringLength str);
      escape = list: replaceStrings list (map (char: "\\${char}") list);
      escapeRegex = escape (stringToCharacters "\\[{()^$?*+|.");
      addContextFrom = src: target: substring 0 0 src + target;
      splitString = sep: str: let
        string = toString string;
        separator = toString separator;
      in
        if separator == ""
        then [(addContextFrom str string)]
        else
          map
          (addContextFrom str)
          (filter isString (split (escapeRegex separator) string));
      splitStem = value:
        filter (val: isString val && val != "")
        (splitString "/" value);
    in
      if isAttrs stem
      then
        mapAttrs (_: part:
          asPath {
            inherit base;
            stem = part;
          })
        stem
      else if isString stem
      then
        if substring 0 1 stem == "/"
        then {
          store =
            if substring 0 11 stem == "/nix/store/"
            then /. + stem
            else null;
          local = stem;
        }
        else
          asPath {
            inherit base;
            stem = splitStem stem;
          }
      else let
        relPath = concatStringsSep "/" stem;
      in {
        store =
          if base.store == null
          then null
          else base.store + "/${relPath}";
        local = concatStringsSep "/" (filter (string: string != "") [base.local relPath]);
      };

    #> --------------------------------------------------------------------
    #> Phase 1 (bootstrap paths): resolve just enough to import `_` itself -
    #> `src`, `home`, and `paths.lib.default.store`. Everything else is
    #> re-resolved properly in Phase 2 once `_` is reachable.
    #> --------------------------------------------------------------------
    paths = {
      src = {
        store = ./.;
        local =
          if root != null
          then root
          else getEnv "PWD" cfg.paths.src;
      };

      user = let
        path = getEnv "HOME" "/home/${cfg.names.alpha}";
        srcLocal = toString paths.src.local;
      in {
        store =
          if hasPrefix srcLocal path
          then paths.src.store + removePrefix srcLocal path
          else null;
        local = path;
      };

      #> Only the repo-relative groups are needed to reach paths.lib.default -
      #> user/xdg/tmpdir are irrelevant to loading `_` and are skipped here.
      repo = asPath {
        base = paths.src;
        stem = removeAttrs cfg.paths ["user" "xdg" "src" "home" "tmpdir"];
      };
    };
  };
  inherit (bootstrap) getEnv importAttr mergeAttrs;

  cfg = let
    global = import ./API/nix/global;
    host = let
      name = getEnv "HOSTNAME" "Victus";
      path = ./. + "/${concatStringsSep "/" global.paths.api.hosts}/${name}";
    in
      importAttr path;
  in
    mergeAttrs global host;

  inherit (cfg) names;

  libraries = import bootstrap.paths.repo.lib.default.store {
    inherit names lib;
    flake =
      if flake != null
      then flake
      else {};
    paths = with bootstrap.paths; {
      src = src.store;
      libraries = repo.lib.default.store;
    };
  };
  namedLib = libraries.${names.lib};

  inherit (namedLib.attrsets.transformation) asEnvVars mapAttrsToList;
  inherit (namedLib.filesystem.tree) mkTree;
  inherit (namedLib.lists.construction) concatLists;
  inherit (namedLib.lists.access) elemAt length;
  inherit (namedLib.schema._) mkSchema;

  #> --------------------------------------------------------------------
  #> Phase 2 (real paths): now that `_` is loaded, rebuild `paths` fully
  #> through `mkTree`/`construct` - the single source of truth for path
  #> resolution from this point on. `user`/`xdg` resolve against `home`;
  #> everything else resolves against `src` (mkTree's default).
  #> --------------------------------------------------------------------
  tree = mkTree {
    stems = removeAttrs cfg.paths ["src" "home" "tmpdir"];
    roots = {
      user = bootstrap.paths.user;
      xdg = bootstrap.paths.user;
    };
  };

  paths =
    tree.store
    // {
      src = bootstrap.paths.src;
      home = bootstrap.paths.user;
      tmpdir = {
        store = null;
        local = getEnv "TMPDIR" (cfg.paths.tmpdir or "/tmp");
      };
    };

  env = let
    transformPathVar = domain: attrPath: localPath: let
      leaf = elemAt attrPath (length attrPath - 1);
      joinedAttr = concatStringsSep "_" attrPath;
    in
      if domain == "xdg"
      then let
        suffix =
          if leaf == "runtime_dir" || leaf == "tmpdir"
          then ""
          else "_HOME";
        varName = "XDG_${joinedAttr}${suffix}";
      in {
        name = varName;
        default = localPath;
      }
      else if domain == "user"
      then {
        name = leaf;
        default = localPath;
      }
      else {
        name = "${names.src}_${domain}_${joinedAttr}";
        default = localPath;
      };

    # Flatten a domain's tree into [{name; default;}], skipping non-leaf nodes.
    # A leaf is any attrset with a `local` key (matches paths.*.* shape).
    flattenDomain = domain: attrPath: node:
      if isAttrs node && node ? local
      then [(transformPathVar domain attrPath node.local)]
      else if isAttrs node
      then
        concatLists (
          mapAttrsToList (key: child: flattenDomain domain (attrPath ++ [key]) child) node
        )
      else [];

    pathEnvVars = concatLists (
      mapAttrsToList (domain: node:
        concatLists (
          mapAttrsToList (key: child: flattenDomain domain [key] child)
          (removeAttrs node ["src"])
        ))
      (removeAttrs paths ["src" "modules"])
    );
  in
    asEnvVars {
      type = "set";
      uppercase = true;
      vars =
        (mapAttrsToList (name: default: {inherit name default;}) cfg.environment)
        ++ [
          {
            name = names.src;
            default = paths.src.local;
          }
          {
            name = "${names.src}_HOME";
            default = paths.src.local;
          }
        ]
        ++ pathEnvVars;
    };

  schema = mkSchema {inherit tree;};
  inherit (schema) hosts users;
in {
  inherit
    cfg
    env
    bootstrap
    hosts
    paths
    schema
    tree
    libraries
    users
    names
    ;
  inherit (names) top;
  "${names.lib}" = namedLib;
}
