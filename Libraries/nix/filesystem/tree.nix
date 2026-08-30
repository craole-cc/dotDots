{
  _,
  _defaults,
  ...
}: let
  inherit (_.attrsets.transformation) mapAttrs mapAttrsToList;
  inherit (_.lists.construction) concatLists;
  inherit (builtins) concatStringsSep foldl';
  inherit (_.strings.transformation) toUpper;
  inherit (_.types.predicates) isAttrs;

  src =
    if isAttrs _defaults.paths.src
    then _defaults.paths.src.store
    else _defaults.paths.src;
  store = src;
  primitiveContext = {
    filesystem.predicates = _.filesystem.predicates;
    types.predicates = _.types.predicates;
  };
  primitives = import ./primitives.nix {
    _ = primitiveContext;
    inherit src;
    lib = _defaults.lib or null;
  };
  inherit (primitives) construct;
  vars = _defaults.vars or ["HOME" "UID"];
  namesSrc =
    if _defaults ? names && _defaults.names ? src
    then _defaults.names.src
    else if _defaults ? flake && _defaults.flake ? name
    then _defaults.flake.name
    else "dots";
  getEnvOr = key: fallback: let
    value = builtins.getEnv key;
  in
    if value == ""
    then fallback
    else value;
  upper = value: toUpper (builtins.replaceStrings ["-"] ["_"] value);

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
  Build a fully-resolved path tree from caller-supplied stems.

  Every group and key comes from the `stems` argument - the single source
  of truth (typically `cfg.paths` from `API/nix/global/config.toml`). No
  built-in groups or defaults are merged in.

  The returned tree has every leaf as a `{ store; local; }` pair - this is
  the canonical, single source of truth (e.g. `tree.api.global.store`).
  For ergonomic legacy-style access, two derived projections are also
  exposed at the top level:

  - `tree.store.<group>.<key>` - same shape as the tree, but every leaf is
    just the bare `store` path (equivalent to `tree.<group>.<key>.store`)
  - `tree.local.<group>.<key>` - same, but the `local` string

  These projections are mechanically derived once from the canonical tree,
  so they can never drift from it - use whichever access style reads best
  at a given call site.

  Each group in `stems` resolves against `src` by default. Callers may
  override the root for individual groups via `roots.<group>` - e.g.
  resolving `user`/`xdg` against `home` instead of the repo root. Root
  overrides are bare paths (string or path value) - the same shape as
  `src` itself.

  A stem entry may be:
  - a group: `{ <key> = [segments]; … }` - each key resolves to its own
    `{ store; local; }` leaf
  - a bare stem: a string or list of segments - resolves directly to a
    single `{ store; local; }` leaf, with no sub-keys (e.g. TOML's flat
    `cache = ".cache"` or `home = []`)

  # Type
  ```
  mkTree :: { stems :: { <group> :: { <key> :: [string] } | [string] | string }
            , roots :: { <group> :: path | string }?
            }
         -> { default :: { store :: path | null, local :: string }
            , store   :: { <group> :: { <key> :: path | null } | path | null, … }
            , local   :: { <group> :: { <key> :: string } | string, … }
            , <group>  :: { <key> :: { store :: path | null, local :: string } }
                         | { store :: path | null, local :: string }
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
      lib = { nix = ["Libraries" "nix"]; rs = ["Libraries" "rust"]; };
      cache = [".cache"];
      user = { downloads = ["Downloads"]; };
    };
    roots = { user = home.local; };
  }
  # => {
  #      default        = { store = /…/dotDots; local = "/…/dotDots"; };
  #      lib.nix         = { store = /…/dotDots/Libraries/nix; local = "/…/dotDots/Libraries/nix"; };
  #      lib.rs          = { store = /…/dotDots/Libraries/rust; local = "/…/dotDots/Libraries/rust"; };
  #      cache           = { store = /…/dotDots/.cache; local = "/…/dotDots/.cache"; };
  #      user.downloads  = { store = null; local = "/home/user/Downloads"; };
  #
  #      store.lib.nix   = /…/dotDots/Libraries/nix;      # same data, projected
  #      local.lib.nix   = "/…/dotDots/Libraries/nix";
  #    }
  ```
  */
  mkTree = {
    stems,
    roots ? {},
  }: let
    isVar = value:
      isAttrs value
      && value ? var
      && builtins.isString value.var;

    normalize = value:
      if builtins.isList value
      then
        map (segment:
          if isVar segment
          then getEnvOr segment.var "\${${segment.var}}"
          else segment)
        value
      else if isVar value
      then getEnvOr value.var "\${${value.var}}"
      else value;

    rootPair = group: let
      root = roots.${group} or src;
    in
      if isVar root
      then {
        store = null;
        local = normalize root;
      }
      else if isAttrs root && (root ? store || root ? local)
      then {
        store = root.store or null;
        local = normalize (root.local or root.store or null);
      }
      else {
        store = root;
        local = normalize root;
      };

    envName = group: segments:
      concatStringsSep "_"
      ((
          if group == "base"
          then []
          else [(upper namesSrc)]
        )
        ++ map upper (builtins.filter (segment: segment != "default") segments));

    resolve = group: segments: value:
      if isAttrs value && !(isVar value)
      then mapAttrs (key: child: resolve group (segments ++ [key]) child) value
      else let
        root = rootPair group;
        normalized = normalize value;
        storePath =
          if root.store == null
          then {store = null;}
          else
            construct {
              root = root.store;
              stem = normalized;
            };
        localPath = construct {
          root = root.local;
          stem = normalized;
        };
      in {
        env = envName group segments;
        inherit (localPath) local;
        inherit (storePath) store;
        stem = value;
      };

    full = mapAttrs (group: groupStems: resolve group [] groupStems) stems;
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
        then foldl' (acc: key: acc // walk node.${key}) {} (builtins.attrNames node)
        else {};
    in
      walk full;
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
  }:
    concatLists (
      mapAttrsToList (
        key: value:
          if isAttrs value && !(value ? local)
          then
            flattenTree {
              inherit getValue;
              tree = value;
              prefix = "${prefix}_${toUpper key}";
            }
          else [
            {
              name =
                if key == "default"
                then prefix
                else "${prefix}_${toUpper key}";
              default = getValue value;
            }
          ]
      )
      tree
    );
in
  exports.internal // {__rootAliases = exports.external;}
