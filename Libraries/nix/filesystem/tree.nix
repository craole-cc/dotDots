{
  _,
  src,
  ...
}: let
  inherit (_.attrsets.aggregation) recursiveUpdateUntil;
  inherit (_.attrsets.transformation) mapAttrs mapAttrsToList;
  inherit (_.filesystem.primitives) construct;
  inherit (_.lists.construction) concatLists;
  inherit (_.strings.transformation) toUpper;
  inherit (_.types.predicates) isAttrs;

  exports = {
    internal = {
      inherit
        flattenTree
        stems
        mkTree
        mkGroup
        mkLangGroup
        wallman
        ;
    };
    external = {
      flattenProjectTree = flattenTree;
      mkProjectTree = mkTree;
    };
  };

  /**
  Build a multi-language group where sibling languages share a common parent
  directory. Each language is a peer - none derives from another.

  `default` always points to `nix` as the project-primary language.

  Used for: `Libraries`, `Packages`, `API`, `Templates` - all follow the
  pattern `<parent>/<language>/`.

  # Type
  ```
  mkLangGroup :: parent :: [string]
              -> langs  :: { key :: string }
              -> { default :: [string], <key> :: [string], … }
  ```

  # Examples
  ```nix
  mkLangGroup ["Libraries"] { nix = "nix"; rust = "rust"; }
  # => {
  #      default = ["Libraries" "nix"];
  #      nix     = ["Libraries" "nix"];
  #      rust    = ["Libraries" "rust"];
  #    }
  ```
  */
  mkLangGroup = parent: langs: {default = parent ++ ["nix"];} // mapAttrs (_: lang: parent ++ [lang]) langs;

  #
  # Defined once here and shared between `stems` and `mkTree` so they can
  # never drift out of sync. `mkTree` overrides these via its `bases` arg.

  defaultBases = {
    lib = ["Libraries"];
  };

  # Build all group stems from a resolved `bases` attrset. Extracted so both
  # `stems` and `mkTree` use exactly the same construction logic and can
  # never diverge.

  mkGroup = bases: {
    lib = mkLangGroup bases.lib {
      bash = "bash";
      nix = "nix";
      nu = "nushell";
      sh = "shellscript";
      pwsh = "powershell";
      py = "python";
      rs = "rust";
    };
  };

  /**
  Raw stem segment lists for every well-known location in the project tree.

  Stems are plain lists of strings - pass them to `construct` or `concat`
  as the `stem` argument. They are the source of truth that `mkTree`
  resolves into `{ store, local }` pairs.

  # Group shapes
  - `lib`    - language peers: `Libraries/<lang>/`
  - `pkg`    - language peers + nix sub-dirs: `Packages/<lang>/`
  - `api`    - language peers + nix sub-dirs: `API/<lang>/`
  - `kit`    - language peers + nix template types: `Templates/<lang>/`
  - `res`    - `Assets/` with typed sub-dirs as flat siblings
  - `cfg`    - flat single-key group
  - `env`    - flat single-key group

  # Examples
  ```nix
  stems.lib.nix         # => ["Libraries" "nix"]
  stems.lib.rust        # => ["Libraries" "rust"]
  stems.pkg.nix         # => ["Packages" "nix"]
  stems.pkg.overlays    # => ["Packages" "nix" "overlays"]
  stems.api.nix         # => ["API" "nix"]
  stems.api.hosts       # => ["API" "nix" "hosts"]
  stems.kit.nix         # => ["Templates" "nix"]
  stems.kit.rust        # => ["Templates" "rust"]
  stems.kit.common      # => ["Templates" "nix" "common"]
  stems.kit.dev         # => ["Templates" "nix" "dev"]
  stems.res.default     # => ["Assets"]
  stems.res.images      # => ["Assets" "Images"]
  stems.res.fonts       # => ["Assets" "Fonts"]
  stems.res.icons       # => ["Assets" "Icons"]
  stems.res.wallpaper   # => ["Assets" "Images" "wallpaper"]
  stems.cfg.default     # => ["Configuration"]
  stems.env.default     # => ["Environment"]
  ```
  */
  stems =
    {
      default = [];
    }
    // mkGroup defaultBases;

  # wallman.sh lives alongside this file in Libraries/nix/filesystem/.
  # Exported as a path value so consumers (e.g. modules/home/paths.nix) can
  # reference it via _.filesystem.tree.wallman without a fragile relative path.
  wallman = ./wallman.sh;

  /**
  Build a fully-resolved path tree for every well-known location in the
  project. Each leaf in the store tree is a Nix path value (importable as
  a module). `mkLocal` builds a parallel string tree rooted at a runtime
  path.

  Built-in groups are always present. Callers extend or override them via:

  - `bases` - change the root segment of any group, re-deriving all keys
  - `stems` - patch individual keys, add new keys, or replace a whole group
              (a group with a `default` key takes over the full derivation;
              otherwise keys merge deeply, preserving siblings)

  # Type
  ```
  mkTree :: { bases :: { <group> :: [string] }?
            , stems :: { <group> :: { <key> :: [string] } }?
            }
         -> { default  :: path | null
            , mkLocal  :: path | string | { root :: path | string } -> { default :: string, <group> :: { <key> :: string } }
            , <group>  :: { <key> :: path | null }
            , …
            }
  ```

  # Arguments
  - `bases` - override the root segment of any built-in group
  - `stems` - override/extend individual keys or add new groups

  # Examples
  ```nix
  mkTree {}.lib.nix               # => /nix/store/…-dotDots/Libraries/nix
  mkTree {}.pkg.overlays          # => /nix/store/…-dotDots/Packages/nix/overlays

  mkTree {}.mkLocal "/home/user/dots"
  # => { default = "/home/user/dots"; lib.nix = "/home/user/dots/Libraries/nix"; … }

  mkTree { bases.lib = ["Lib"]; }.lib.rust
  # => /nix/store/…-dotDots/Lib/rust
  ```
  */
  mkTree = {
    bases ? {},
    stems ? {},
  }: let
    bases' = defaultBases // bases;
    commonStems = mkGroup bases';

    stems' =
      recursiveUpdateUntil (
        _path: _lhs: rhs:
          isAttrs rhs && rhs ? default
      )
      commonStems
      stems;

    resolveStore = root: group:
      mapAttrs
      (_: stem: (construct {inherit root stem;}).store)
      group;

    resolveLocal = root: group:
      mapAttrs
      (_: stem: (construct {inherit root stem;}).local)
      group;

    mkLocal = arg: let
      root =
        if isAttrs arg
        then arg.root
        else arg;
    in
      {default = (construct {inherit root;}).local;} // mapAttrs (_: resolveLocal root) stems';

    store =
      {
        default = (construct {root = src;}).store;
      }
      // mapAttrs (_: resolveStore src) stems';
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
# flattenTree = {
#   flattenGroup = mkTest {
#     desired = [
#       {
#         name = "DOTS_LIB_BASH";
#         default = "Templates/bash";
#       }
#       {
#         name = "DOTS_LIB";
#         default = "Templates/nix";
#       }
#     ];
#     command = ''
#       flattenTree {
#         prefix = "DOTS_LIB";
#         tree = {
#           default = { local = "Templates/nix"; };
#           bash = { local = "Templates/bash"; };
#         };
#       }
#     '';
#     outcome = flattenTree {
#       prefix = "DOTS_LIB";
#       tree = {
#         default = {local = "Templates/nix";};
#         bash = {local = "Templates/bash";};
#       };
#     };
#   };
# };
