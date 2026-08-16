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
    isPath
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

    home = let
      path = getEnv "HOME" "/home/${cfg.names.alpha}";

      hasPrefix = prefix: str:
        substring 0 (stringLength prefix) str == prefix;

      removePrefix = prefix: str:
        if hasPrefix prefix str
        then
          substring (stringLength prefix)
          (stringLength str - stringLength prefix)
          str
        else str;

      localStr = toString src.local;
    in {
      store =
        if hasPrefix localStr path
        then src.store + removePrefix localStr path
        else null;
      local = path;
    };

    #> Resolve repo-relative paths (api, lib, mod, pkg, etc.)
    repo = asPath {
      base = src;
      stem = removeAttrs cfg.paths ["user" "xdg" "src"];
    };

    #> Resolve user home paths (Documents, Pictures, Projects)
    user = asPath {
      base = home;
      stem = cfg.paths.user or {};
    };

    #> Resolve XDG system paths (.config, .local/share, .cache)
    xdg = asPath {
      base = home;
      stem = cfg.paths.xdg or {};
    };
  in
    repo // {inherit src user xdg;};

  libraries = import paths.lib.default.store {
    inherit names flake lib;
    paths = {
      src = paths.src.store;
      libraries = paths.lib.default.store;
    };
  };
  _ = libraries.${names.lib};

  inherit (_.attrsets.transformation) asEnvVars mapAttrsToList mapAttrsRecursive;
  inherit (_.filesystem.tree) mkTree;
  inherit (_.lists.construction) concatLists;
  inherit (_.lists.access) elemAt length;
  inherit (_.schema._) mkSchema;

  tree = mkTree {stems = removeAttrs cfg.paths ["src"];};
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
    flattenDomain = domain: tree: attrPath: node:
      if isAttrs node && node ? local
      then [(transformPathVar domain attrPath node.local)]
      else if isAttrs node
      then
        concatLists (
          mapAttrsToList (key: child: flattenDomain domain tree (attrPath ++ [key]) child) node
        )
      else [];

    pathEnvVars = concatLists (
      mapAttrsToList (domain: tree:
        concatLists (
          mapAttrsToList (key: node: flattenDomain domain tree [key] node)
          (removeAttrs tree ["src"])
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
  # env = asEnvVars {
  #   type = "set";
  #   uppercase = true;
  #   vars =
  #     (
  #       mapAttrsToList
  #       (name: default: {inherit name default;})
  #       cfg.environment
  #     )
  #     ++ (let
  #       inherit (names) src;
  #     in
  #       [
  #         {
  #           name = src;
  #           default = paths.src.local;
  #         }
  #         {
  #           name = "${src}_HOME";
  #           default = paths.src.local;
  #         }
  #       ]
  #       ++ concatLists (mapAttrsToList
  #         (name: tree:
  #           flattenTree {
  #             inherit tree;
  #             prefix = "${src}_${name}";
  #           })
  #         (removeAttrs paths ["src"])));
  # };

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
