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
    getEnv = env: default: let
      resolved = builtins.getEnv env;
    in
      if resolved != ""
      then resolved
      else default;

    importAttr = path:
      if pathExists path
      then import path
      else {};

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

    hasPrefix = prefix: str:
      substring 0 (stringLength prefix) str == prefix;

    removePrefix = prefix: str:
      if hasPrefix prefix str
      then
        substring (stringLength prefix)
        (stringLength str - stringLength prefix)
        str
      else str;

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
      #> user/xdg/tmpdir/cache are irrelevant to loading `_` and are skipped.
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
  inherit (namedLib.lists.construction) concatLists optionals;
  inherit (namedLib.lists.access) elemAt length;
  inherit (namedLib.schema._) mkSchema;

  #> --------------------------------------------------------------------
  #> Phase 2 (real paths): now that `_` is loaded, rebuild `paths` fully
  #> through `mkTree`/`construct` - the single source of truth for path
  #> resolution from this point on. `user`/`xdg` resolve against `home`;
  #> everything else resolves against `src` (mkTree's default). Every
  #> leaf - repo-relative or not - is a uniform `{store;local;}` pair, so
  #> no zipping/reconstruction is needed at this call site anymore.
  #> --------------------------------------------------------------------
  tree = mkTree {
    stems = removeAttrs cfg.paths ["src" "home" "tmpdir"];
    roots = {
      user = bootstrap.paths.user.local;
      xdg = bootstrap.paths.user.local;
    };
  };

  paths =
    tree
    // {
      src = bootstrap.paths.src;
      home = bootstrap.paths.user;
      tmpdir = {
        store = null;
        local = getEnv "TMPDIR" (cfg.paths.tmpdir or "/tmp");
      };
    };

  transformPathVar = {
    domain,
    attrPath,
    localPath,
  }: let
    leaf = elemAt attrPath (length attrPath - 1);
    joinedAttr =
      if leaf == "default"
      then ""
      else "_${concatStringsSep "_" attrPath}";
  in
    if domain == "xdg"
    then let
      suffix =
        if leaf == "runtime_dir" || leaf == "tmpdir"
        then ""
        else "_HOME";
      varName = "XDG_${concatStringsSep "_" attrPath}${suffix}";
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
      name = "${names.src}_${domain}${joinedAttr}";
      default = localPath;
    };

  # Flatten a domain's tree into [{name; default;}], skipping non-leaf nodes.
  flattenDomain = domain: attrPath: node:
    optionals (isAttrs node) (
      if node ? local
      then [
        (transformPathVar {
          inherit domain attrPath;
          inherit (node) local;
        })
      ]
      else
        concatLists (
          mapAttrsToList (key: child: flattenDomain domain (attrPath ++ [key]) child) node
        )
    );
  env = let
    ignore = ["src" "store" "local" "mkLocal"];
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
        ++ (
          concatLists (
            mapAttrsToList
            (domain: node:
              concatLists (
                mapAttrsToList
                (key: child: flattenDomain domain [key] child)
                (removeAttrs node ignore)
              ))
            (removeAttrs paths ignore)
          )
        );
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
