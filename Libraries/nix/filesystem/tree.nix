{
  _,
  src,
  ...
}: let
  inherit (_.attrsets.transformation) mapAttrs mapAttrsToList;
  inherit (_.filesystem.primitives) construct;
  inherit (_.lists.construction) concatLists;
  inherit (_.strings.transformation) toUpper;
  inherit (_.types.predicates) isAttrs;

  exports = {
    internal = {
      inherit
        flattenTree
        mkTree
        wallman
        ;
    };
    external = {
      flattenProjectTree = flattenTree;
      mkProjectTree = mkTree;
    };
  };

  # wallman.sh lives alongside this file in Libraries/nix/filesystem/.
  # Exported as a path value so consumers (e.g. modules/home/paths.nix) can
  # reference it via _.filesystem.tree.wallman without a fragile relative path.
  wallman = ./wallman.sh;

  /**
  Build a fully-resolved path tree from caller-supplied stems.

  Unlike earlier versions, `mkTree` carries no built-in groups or default
  stems - every group and key comes from the `stems` argument, which is the
  single source of truth (typically `cfg.paths` from `API/nix/global/config.toml`).
  This avoids duplicating the same stem data in two places that can drift
  out of sync.

  Each group in `stems` resolves against `src` by default. Callers may
  override the root for individual groups via `roots.<group>` - e.g.
  resolving `user`/`xdg` against `home` instead of the repo root.

  # Type
  ```
  mkTree :: { stems :: { <group> :: { <key> :: [string] } }
            , roots :: { <group> :: { store :: path | null, local :: string } }?
            }
         -> { default :: path | null
            , mkLocal :: path | string | { root :: path | string }
                       -> { default :: string, <group> :: { <key> :: string } }
            , <group>  :: { <key> :: path | null }
            , …
            }
  ```

  # Arguments
  - `stems` - attrset of `<group> = { <key> = [segments]; }`, taken as-is
              (no merging with built-in defaults - there are none)
  - `roots` - optional per-group root override, `{ store; local; }` pairs.
              Groups not listed here resolve against `src`.

  # Examples
  ```nix
  mkTree {
    stems = {
      lib = { nix = ["Libraries" "nix"]; rs = ["Libraries" "rust"]; };
      user = { downloads = ["Downloads"]; };
    };
    roots = { user = home; };
  }
  # => {
  #      store.lib.nix = /nix/store/…-dotDots/Libraries/nix;
  #      store.lib.rs  = /nix/store/…-dotDots/Libraries/rust;
  #      store.user.downloads = null;  # outside src, unless home is also outside
  #      mkLocal = <fn>;
  #    }
  ```
  */
  mkTree = {
    stems,
    roots ? {},
  }: let
    rootFor = group:
      roots.${
        group
      }
      or {
        store = src;
        local = toString src;
      };

    resolveStore = root: group:
      mapAttrs
      (_key: stem: (construct {inherit root stem;}).store)
      group;

    resolveLocal = root: group:
      mapAttrs
      (_key: stem: (construct {inherit root stem;}).local)
      group;

    mkLocal = arg: let
      root =
        if isAttrs arg
        then arg.root
        else arg;
    in
      {default = (construct {inherit root;}).local;}
      // mapAttrs (groupName: group: resolveLocal (rootFor groupName).local group) stems;

    store =
      {
        default = (construct {root = src;}).store;
      }
      // mapAttrs (groupName: group: resolveStore (rootFor groupName) group) stems;
  in {inherit mkLocal store;};

  /**
    Recursively flattens a nested attrset into a `[{ name, default }]` list, for feeding into asEnvVars.

    # Arguments
    `tree` (attrset)
    : A nested attrset whose leaves are the values to expose.

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
      mapAttrsToList
      (key: value:
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
        ])
      tree
    );
in
  exports.internal // {__rootAliases = exports.external;}
