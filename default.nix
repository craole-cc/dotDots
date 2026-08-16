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
    Bootstrap-only stand-in for `_.filesystem.primitives.construct` - only
    needed until real lix is reachable. Recursively resolves stems (attrset,
    list, or string) into `{ store, local }` records.

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
          store = base.store;
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
        store = base.store + "/${relPath}";
        local = concatStringsSep "/" (filter (string: string != "") [base.local relPath]);
      };
  };
  inherit (bootstrap) asPath getEnv importAttr mergeAttrs;

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

  paths = let
    src = {
      store = ./.;
      local =
        if root != null
        then root
        else getEnv "PWD" cfg.paths.src;
    };
  in
    asPath {
      base = src;
      stem = cfg.paths;
    }
    // {inherit src;};

  libraries = import paths.lib.default.store {
    inherit names flake lib;
    paths = {
      src = paths.src.store;
      libraries = paths.lib.default.store;
    };
  };
  _ = libraries.${names.lib};

  inherit (_.attrsets.transformation) asEnvVars mapAttrsToList;
  inherit (_.filesystem.tree) mkTree flattenTree;
  inherit (_.lists.construction) concatLists;
  inherit (_.schema._) mkSchema;
  inherit (_.strings.transformation) toUpper;

  tree = mkTree {stems = cfg.paths;};

  env = asEnvVars {
    type = "set";
    uppercase = true;
    vars =
      (
        mapAttrsToList
        (name: default: {inherit name default;})
        cfg.environment
      )
      ++ (let
        inherit (names) src;
      in
        [
          {
            name = toUpper "${src}_HOME";
            default = paths.src.local;
          }
        ]
        ++ concatLists (mapAttrsToList
          (name: tree:
            flattenTree {
              inherit tree;
              prefix = "${src}_${name}";
            })
          (removeAttrs paths ["src"])));
  };

  schema = mkSchema {inherit tree;};
  inherit (schema) hosts users;
in {
  inherit
    cfg
    env
    hosts
    paths
    schema
    tree
    users
    ;
  inherit (names) top;
  "${names.lib}" = _;
}
