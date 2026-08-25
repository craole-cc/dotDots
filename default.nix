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
        (mapAttrs (key: value:
          if set1 ? ${key}
          then mergeAttrs set1.${key} value
          else value)
        set2)
        // removeAttrs set1 (attrNames set2)
      else set2;

    hasPrefix = prefix: str: substring 0 (stringLength prefix) str == prefix;

    removePrefix = prefix: str:
      if hasPrefix prefix str
      then substring (stringLength prefix) (stringLength str - stringLength prefix) str
      else str;

    asPath = {
      stem,
      base,
    }: let
      stringToCharacters = str: genList (char: substring char 1 str) (stringLength str);

      escape = list: replaceStrings list (map (char: "\\${char}") list);

      escapeRegex = escape (stringToCharacters "\\[{()^$?*+|.");

      addContextFrom = flake: target: substring 0 0 flake + target;

      splitString = sep: str: let
        string = toString str;
        separator = toString sep;
      in
        if separator == ""
        then [(addContextFrom str string)]
        else map (addContextFrom str) (filter isString (split (escapeRegex separator) string));

      splitStem = value: filter (val: isString val && val != "") (splitString "/" value);
    in
      if isAttrs stem
      then
        mapAttrs (
          _: part:
            asPath {
              inherit base;
              stem = part;
            }
        )
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

        local = concatStringsSep "/" (
          filter (string: string != "") [
            base.local
            relPath
          ]
        );
      };

    #> --------------------------------------------------------------------
    #> Raw API data: imported and host-merged using bootstrap-only helpers.
    #> This is the unresolved configuration used only to bootstrap the real
    #> library and construct the final resolved `cfg`.
    #> --------------------------------------------------------------------
    raw = let
      global = import ./API/nix/global;

      host = let
        name = getEnv "HOSTNAME" "Victus";
        path = ./. + "/${concatStringsSep "/" global.paths.api.hosts}/${name}";
      in
        importAttr path;
    in
      mergeAttrs global host;

    #> --------------------------------------------------------------------
    #> Phase 1 (bootstrap paths): resolve just enough to import `_` itself -
    #> `flake`, `home`, and `paths.lib.default.store`. Everything else is
    #> re-resolved properly in Phase 2 once `_` is reachable.
    #> --------------------------------------------------------------------
    paths = {
      flake = {
        store = ./.;
        local =
          if root != null
          then root
          else getEnv "PWD" raw.paths.flake;
      };

      user = let
        path = getEnv "HOME" "/home/${raw.names.alpha}";
        flakeLocal = toString paths.flake.local;
      in {
        store =
          if hasPrefix flakeLocal path
          then paths.flake.store + removePrefix flakeLocal path
          else null;

        local = path;
      };

      #> Only the repo-relative groups are needed to reach paths.lib.default -
      #> user/xdg/tmpdir are irrelevant to loading `_` and are skipped.
      repo = asPath {
        base = paths.flake;
        stem = removeAttrs raw.paths [
          "user"
          "xdg"
          "flake"
          "home"
          "tmpdir"
        ];
      };
    };
  };

  inherit (bootstrap) getEnv raw;
  inherit (raw) names;

  libraries = import bootstrap.paths.repo.lib.default.store {
    inherit names lib;

    flake =
      if flake != null
      then flake
      else {};

    paths = {
      flake = bootstrap.paths.flake.store;
      libraries = bootstrap.paths.repo.lib.default.store;
    };
  };

  namedLib = libraries.${names.lib};

  inherit
    (namedLib.attrsets.transformation)
    asEnvVars
    mapAttrsToList
    ;

  inherit (namedLib.filesystem.tree) mkTree;
  inherit (namedLib.lists.construction) concatLists optionals;
  inherit (namedLib.lists.access) elemAt length;
  inherit (namedLib.schema._) mkSchema;

  #> --------------------------------------------------------------------
  #> Phase 2 (real paths): now that `_` is loaded, rebuild `paths` fully
  #> through `mkTree`/`construct` - the single source of truth for path
  #> resolution from this point on. `user`/`xdg` resolve against `home`;
  #> everything else resolves against `flake` (mkTree's default). Every
  #> leaf - repo-relative or not - is a uniform `{store;local;}` pair.
  #> --------------------------------------------------------------------
  tree = mkTree {
    stems = removeAttrs raw.paths [
      "flake"
      "home"
      "tmpdir"
    ];

    roots = {
      user = bootstrap.paths.user.local;
      xdg = bootstrap.paths.user.local;
    };
  };

  paths =
    tree
    // {
      flake = bootstrap.paths.flake;
      home = bootstrap.paths.user;

      tmpdir = {
        store = null;
        local = getEnv "TMPDIR" (raw.paths.tmpdir or "/tmp");
      };
    };

  #> --------------------------------------------------------------------
  #> Final configuration: preserve the raw API data, but replace its raw
  #> path stems with the fully-resolved canonical path model.
  #> --------------------------------------------------------------------
  cfg =
    raw
    // {
      inherit paths;
    };

  env = let
    transformPathVar = domain: attrPath: localPath: let
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
        name = "${names.flake}_${domain}${joinedAttr}";
        default = localPath;
      };

    # Flatten a domain's tree into [{name; default;}], skipping non-leaf nodes.
    flattenDomain = domain: attrPath: node:
      optionals (isAttrs node) (
        if node ? local
        then
          # XDG_RUNTIME_DIR is session-owned (by PAM/systemd) and must not be
          # synthesized from the repository path model or overwritten in shells.
          optionals
          (domain != "xdg" || elemAt attrPath (length attrPath - 1) != "runtime_dir")
          [
            (transformPathVar domain attrPath node.local)
          ]
        else concatLists (mapAttrsToList (key: child: flattenDomain domain (attrPath ++ [key]) child) node)
      );

    ignore = [
      "flake"
      "store"
      "local"
      "mkLocal"
    ];
  in
    asEnvVars {
      type = "set";
      uppercase = true;

      vars =
        (mapAttrsToList (name: default: {inherit name default;}) cfg.environment)
        ++ [
          {
            name = names.flake;
            default = paths.flake.local;
          }
          {
            name = "${names.flake}_HOME";
            default = paths.flake.local;
          }
        ]
        ++ (concatLists (
          mapAttrsToList (
            domain: node:
              concatLists (
                mapAttrsToList (key: child: flattenDomain domain [key] child) (removeAttrs node ignore)
              )
          ) (removeAttrs paths ignore)
        ));
    };

  schema = mkSchema {inherit tree;};
  inherit (schema) hosts users;
in {
  inherit
    bootstrap
    cfg
    env
    hosts
    libraries
    names
    paths
    schema
    tree
    users
    ;
  "${names.lib}" = namedLib;
}
