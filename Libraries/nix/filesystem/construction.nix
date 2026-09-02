{
  _,
  _defaults,
  ...
}: let
  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs mapAttrsToList;
  inherit (_.filesystem.primitives) construct;
  inherit (_.lists.access) last;
  inherit (_.lists.aggregation) foldl';
  inherit (_.lists.construction) concatLists optional;
  inherit (_.lists.transformation) filter;
  inherit (_.strings.access) getEnvOr;
  inherit (_.strings.construction) concat;
  inherit (_.strings.transformation) toLower toEnv;
  inherit (_.types.predicates) isAttrs isList isString;

  # TODO Why are we defining this? The library would not have been imported if both we not already defined.
  src = {
    store =
      _defaults.paths.repo.src.store or (
        _defaults.paths.repo.src.store or ../../../.
      );
    name =
      _defaults.names.src or (
        _defaults.flake.name or  "dots"
      );
  };

  exports = {
    internal = {
      inherit flattenTree mkTree mkLocal wallman;
    };
    external = {
      flattenProjectTree = flattenTree;
      mkProjectTree = mkTree;
      mkLocalTree = mkLocal;
    };
  };

  wallman = ./wallman.sh;

  /**
  Build the full env-var name for a tree leaf from its group and segment
  path: `${prefix}_${SEGMENTS}(_${suffix})`. All per-segment string
  transformation is delegated to `toEnv`; this only handles the
  group-specific framing around it.

  # Type
  ```
  mkEnv :: { group :: string, segments :: [string] } -> string
  ```

  # Examples
  ```nix
  mkEnv { group = "repo"; segments = ["lib" "rs"]; }
  # => "DOTS_LIB_RS"

  mkEnv { group = "xdg"; segments = ["runtime"]; }
  # => "XDG_RUNTIME_DIR"
  ```
  */
  # #ODO: construct should be creating env, not tree, because env is per path, not per group. The tree is just a projection of the env.
  mkEnv = {
    group,
    segments,
  }: let
    group' = toLower group;
    # Four groups have fixed, special-cased env-prefix behavior; any other
    # group name falls back to the `repo`-style prefix (`${names.src}`).
    # TODO: Use optionals and isIn (elem) here
    prefix =
      if group' == "slash" || group' == "home"
      then []
      else if group' == "xdg"
      then ["XDG"]
      else [(toEnv src.name)];

    # XDG's five variables are fixed and irregular: four end in `_HOME`,
    # `runtime` ends in `_DIR`. Narrow, known exception - owned here rather
    # than pushed into the stems data or a generic suffix mechanism.
    suffix =
      if group' != "xdg"
      then null
      else if (last segments) == "runtime"
      then "DIR"
      else "HOME";

    parts = map toEnv (filter (segment: segment != "default") segments);
  in
    concat "_" (prefix ++ parts ++ (optional (suffix != null) suffix));

  isVar = value:
    isAttrs value
    && value ? var
    && isString value.var;

  resolveVar = vars: value:
    if isList value
    then
      map (segment:
        if isVar segment
        then vars.${segment.var} or (getEnvOr segment.var "\${${segment.var}}")
        else segment)
      value
    else if isVar value
    then vars.${value.var} or (getEnvOr value.var "\${${value.var}}")
    else value;

  mkRootPair = {
    roots,
    group,
    vars ? {},
  }: let
    root = roots.${group} or src.path;
  in
    if isVar root
    then {
      store = null;
      local = resolveVar vars root;
    }
    else if isAttrs root && (root ? store || root ? local)
    then {
      store = root.store or null;
      local = resolveVar vars (root.local or root.store or null);
    }
    else {
      store = root;
      local = resolveVar vars root;
    };

  /**
  Resolve one `stems` entry - a group, or a stem within one - into its
  `{ store; local; env; stem; }` leaf (or, for a group, the nested
  attrset of such leaves). Recurses on nested attrsets; `mkTree` calls
  this once per top-level group and lets the recursion walk the rest.

  Lifted out of `mkTree` so the resolve step can be read, and reused,
  on its own - `mkTree` itself is left as pure construction/projection
  over the result.

  # Type
  ```
  mkTreePath :: { roots :: { <group> :: path | string }?
                , group :: string
                , segments :: [string]?
                , value :: AttrSet | [string] | string | { var :: string }
                }
             -> { store :: path | null, local :: string, env :: string, stem :: [string] }
              | { <key> :: ... }
  ```

  # Arguments
  - `roots`    - per-group root override map, as passed to `mkTree`
  - `group`    - the group this value belongs to (drives root lookup and env prefix)
  - `segments` - key path walked so far, for env-var naming; starts at `[]`
  - `value`    - a stem (string/list, optionally holding `{ var = "…"; }`
                 placeholders) or a nested attrset of them

  # Examples
  ```nix
  mkTreePath { roots = {}; group = "repo"; value = ["Libraries" "nix"]; }
  # => { store = /…/dotDots/Libraries/nix; local = "..."; env = "DOTS"; stem = ["Libraries" "nix"]; }

  mkTreePath { roots = {}; group = "repo"; value = { lib.default = ["Libraries" "nix"]; }; }
  # => { lib.default = { store = ...; local = ...; env = "DOTS_LIB"; stem = [...]; }; }
  ```
  */
  mkTreePath = {
    roots,
    group,
    segments ? [],
    value,
    vars ? {},
  }:
    if isAttrs value && !(isVar value)
    then
      mapAttrs (key: child:
        mkTreePath {
          inherit roots group vars;
          segments = segments ++ [key];
          value = child;
        })
      value
    else let
      root = mkRootPair {inherit roots group vars;};
      stem = resolveVar vars value;
    in {
      env = mkEnv {inherit group segments;};
      store =
        if root.store == null
        then null
        else
          (construct {
            root = root.store;
            inherit stem;
          }).store;
      inherit
        (construct {
          root = root.local;
          inherit stem;
        })
        local
        stem
        ;
    };

  /**
  Build a fully-resolved path tree from caller-supplied stems.

  Every group and key comes from the `stems` argument - the single source
  of truth (typically `cfg.paths` from `API/nix/global/config.toml`). No
  built-in groups or defaults are merged in.

  The returned tree has every leaf as a `{ store; local; env; stem; }`
  record - this is the canonical, single source of truth (e.g.
  `tree.repo.api.default.store`). For ergonomic legacy-style access, three
  derived projections are also exposed at the top level:

  - `tree.store.<group>.<key>` - same shape as the tree, but every leaf is
    just the bare `store` path (equivalent to `tree.<group>.<key>.store`)
  - `tree.local.<group>.<key>` - same, but the `local` string
  - `tree.stores.<group>` - flat, one entry per group that declares a
    `default` sub-key (plus `tree.stores.src`, the tree's own root) - the
    bare `store` path of that group's `default` leaf, nothing else. Not a
    general per-leaf projection - groups without a `default`, and any
    group's non-default siblings (`lib.rs`, `api.hosts`, ...), are only
    reachable through the full tree or the `store`/`local` projections.

  These projections are mechanically derived once from the canonical tree,
  so they can never drift from it - use whichever access style reads best
  at a given call site.

  Each group in `stems` resolves against `src` by default. Callers may
  override the root for individual groups via `roots.<group>` - e.g.
  resolving `home`/`xdg` against `home` instead of the repo root. Root
  overrides are bare paths (string or path value) - the same shape as
  `src` itself.

  Leaf resolution itself (root lookup, var placeholders, `construct` calls,
  env-var naming) is delegated entirely to `mkTreePath`, called once per
  top-level group; `mkTree` is left as pure construction/projection over
  the resulting tree.

  ## Env var naming

  Every leaf's `env` field is its computed environment-variable name,
  built by `mkEnv` from `${prefix}_${STEM_SEGMENTS}(_${suffix})`. The
  prefix depends on which group the leaf belongs to - four groups have
  fixed, special-cased behavior; any other group name falls back to the
  `repo`-style prefix:

  - `repo`  - prefixed with `${names.src}` (upper-cased), e.g. `DOTS_LIB_RS`
  - `slash` - no prefix at all, e.g. `NIX_STORE`, `USR_BIN`
  - `home`  - no prefix at all, e.g. `DOWNLOADS`
  - `xdg`   - prefixed with the literal `XDG`, e.g. `XDG_CONFIG_HOME`;
              `xdg.runtime` is the one irregular case, suffixed `_DIR`
              instead of `_HOME`
  - anything else - prefixed with `${names.src}`, same as `repo`

  A stem entry may be:
  - a group: `{ <key> = [segments]; … }` - each key resolves to its own
    `{ store; local; env; stem; }` leaf
  - a bare stem: a string or list of segments - resolves directly to a
    single `{ store; local; env; stem; }` leaf, with no sub-keys (e.g.
    TOML's flat `cache = ".cache"` or `src = []`)

  # Type
  ```
  mkTree :: { stems :: { <group> :: { <key> :: [string] } | [string] | string }
            , roots :: { <group> :: path | string }?
            }
         -> { default :: { store :: path | null, local :: string }
            , store   :: { <group> :: { <key> :: path | null } | path | null, … }
            , local   :: { <group> :: { <key> :: string } | string, … }
            , stores  :: { src :: path | null, <group> :: path | null, … }
            , <group>  :: { <key> :: { store :: path | null, local :: string, env :: string, stem } }
                         | { store :: path | null, local :: string, env :: string, stem }
            , …
            }
  ```

  # Arguments
  - `stems` - attrset of `<group> = { <key> = [segments]; }` (or a bare
              stem), taken as-is - no merging with built-in defaults
  - `roots` - optional per-group root override, a bare path. Groups not
              listed here resolve against `src`.

  # Examples
  ```nix
  mkTree {
    stems = {
      repo = { lib = { default = ["Libraries" "nix"]; rs = ["Libraries" "rust"]; }; };
      slash = { usr = { bin = ["usr" "bin"]; }; };
      home = { downloads = ["Downloads"]; };
    };
    roots = { home = home.local; slash = "/"; };
  }
  # => {
  #      repo.lib.default = { store = /…/dotDots/Libraries/nix; local = "..."; env = "DOTS_LIB"; stem = [...]; };
  #      repo.lib.rs      = { store = /…/dotDots/Libraries/rust; local = "..."; env = "DOTS_LIB_RS"; stem = [...]; };
  #      slash.usr.bin    = { store = null; local = "/usr/bin"; env = "USR_BIN"; stem = [...]; };
  #      home.downloads   = { store = null; local = "/home/user/Downloads"; env = "DOWNLOADS"; stem = [...]; };
  #
  #      store.repo.lib.default = /…/dotDots/Libraries/nix;   # same data, projected
  #      local.repo.lib.default = "/…/dotDots/Libraries/nix";
  #      stores.lib              = /…/dotDots/Libraries/nix;  # flat anchor projection
  #      stores.src              = /…/dotDots;
  #    }
  ```
  */

  mkTree = {
    stems,
    roots ? {},
    vars ? {},
  }: let
    full = mapAttrs (group: groupStems:
      mkTreePath {
        inherit roots group vars;
        value = groupStems;
      })
    stems;

    project = field: let
      walk = node:
        if isAttrs node && node ? ${field}
        then node.${field}
        else mapAttrs (_: walk) node;
    in
      walk full;

    variables = let
      walk = node:
        if isAttrs node && node ? env && node ? local
        then {${node.env} = node.local;}
        else if isAttrs node
        then foldl' (acc: key: acc // walk node.${key}) {} (attrNames node)
        else {};
    in
      walk full;
    # # Flat anchor projection: one bare store path per group that declares
    # # a `default` sub-key, plus `src` for the tree's own root. Does NOT
    # # cover non-default siblings (`lib.rs`, `api.hosts`, ...) - those stay
    # # reachable only through the full tree or `store`/`local`.
    # stores =
    #   {src = src.path;}
    #   // (
    #     mapAttrs
    #     (_: group: group.default.store)
    #     (filterAttrs (_: group: isAttrs group && group ? default) full)
    #   );
  in
    full
    // {
      inherit variables;
      store = project "store";
      local = project "local";
      mkLocal = base: mkLocal {inherit base stems;};
    };

  # Re-derive the local-string tree against a different root at call time
  # (e.g. a host-specific runtime path), rather than the build-time `src`
  # projections above, which are fixed once `mkTree` is called.
  mkLocal = {
    base,
    stems,
  }: let
    root =
      if isAttrs base
      then base.root
      else base;

    resolveAt = value:
      if isAttrs value
      then mapAttrs (_key: resolveAt) value
      else
        (construct {
          inherit root;
          stem = value;
        }).local;
  in
    {default = (construct {inherit root;}).local;} // mapAttrs (_groupName: resolveAt) stems;

  /**
    Recursively flattens a nested `{store;local;}`-leaved tree into a
    `[{ name, default }]` list, for feeding into asEnvVars.

    # Arguments
    `tree` (attrset)
    : A nested attrset whose leaves are `{ store; local; }` pairs.

    `prefix` (string)
    : Prepended (with "_") to every generated name; used as the base namespace.

    `getValue` (function, default: leaf -> leaf.local)
    : How to extract the default value from a leaf entry.

    # Type

  ```nix
    flattenTree :: { tree :: AttrSet, prefix :: string, getValue :: (AttrSet -> a) } -> [ { name :: string, default :: a } ]

  ```
  */
  flattenTree = {
    tree,
    prefix,
    getValue ? (entry: entry.local),
  }: let
    prefixed = name: "${prefix}_${toEnv name}";
  in
    concatLists (
      mapAttrsToList (
        key: value:
          if isAttrs value && !(value ? local)
          then
            flattenTree {
              inherit getValue;
              tree = value;
              prefix = prefixed key;
            }
          else [
            {
              name =
                if key == "default"
                then prefix
                else prefixed key;
              default = getValue value;
            }
          ]
      )
      tree
    );
in
  exports.internal // {__rootAliases = exports.external;}
