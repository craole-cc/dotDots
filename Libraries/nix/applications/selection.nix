{_, ...}: let
  meta = let
    doc = ''
      Primitive application set selectors (Layer 3).

      Provides low-level set selectors and set transforms that operate on
      whole application attrsets. These functions filter by boolean or
      inequality predicates and derive resolved config paths, but do not
      assign semantic query names or compose higher-level query bundles.

      Depends on: applications.primitives.
    '';
    functions = {
      inherit
        withFlag
        withoutFlag
        withNeq
        resolveConfig
        ;
    };
    exports = {
      local = functions;
      alias = {};
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.applications.primitives) toValue;
  inherit (_.attrsets.access) attrByPath;
  inherit (_.attrsets.merging) recursiveUpdate;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs setAttrByPath;
  inherit (_.attrsets.predicates) isAttrs;

  /**
  Select applications where a boolean field is `true`.

  Missing fields are treated as `false`.

  # Type
  ```nix
  withFlag :: {
    field :: string | [string],
    set   :: AttrSet,
  } -> AttrSet
  ```

  # Examples
  ```nix
  withFlag {
    field = "desktop";
    set = {
      foot = { desktop = false; };
      zen = { desktop = true; };
    };
  }
  # => { zen = { desktop = true; }; }
  ```
  */
  withFlag = {
    field,
    set,
  }:
    filterAttrs (
      _: app:
        toValue {
          inherit field;
          default = false;
        }
        app
    )
    set;

  /**
  Select applications where a boolean field is `false` or absent.

  # Type
  ```nix
  withoutFlag :: {
    field :: string | [string],
    set   :: AttrSet,
  } -> AttrSet
  ```

  # Examples
  ```nix
  withoutFlag {
    field = "desktop";
    set = {
      foot = { desktop = false; };
      zen = { desktop = true; };
      bash = {};
    };
  }
  # => {
  #      foot = { desktop = false; };
  #      bash = {};
  #    }
  ```
  */
  withoutFlag = {
    field,
    set,
  }:
    filterAttrs (
      _: app: let
        val =
          toValue {
            inherit field;
            default = null;
          }
          app;
      in
        val == null || !val
    )
    set;

  /**
  Select applications where a field is not equal to `value`.

  Useful for excluding sentinel values. Missing fields evaluate to
  `default`.

  # Type
  ```nix
  withNeq :: {
    field   :: string | [string],
    default :: a,    # optional, default null
    value   :: a,    # optional, default null
    set     :: AttrSet,
  } -> AttrSet
  ```

  # Examples
  ```nix
  withNeq {
    field = "channel";
    value = "unstable";
    set = {
      a = { channel = "stable"; };
      b = { channel = "unstable"; };
      c = {};
    };
  }
  # => {
  #      a = { channel = "stable"; };
  #      c = {};
  #    }
  ```
  */
  withNeq = {
    field,
    default ? null,
    value ? null,
    set,
  }:
    filterAttrs (_: app: toValue {inherit field default;} app != value) set;

  /**
      Resolve `config.home` and `config.file` into `config.path` across a set.

      Accepts either a named attrset `{ set, path? }` / `{ raw, path? }` or a
      flat application attrset directly.

      When both `home` and `file` are present at `path`, adds a derived `path`
      member equal to `"${home}/${file}"` while preserving the original fields.

      # Type
  ```nix
      resolveConfig :: AttrSet | { set :: AttrSet, path :: [string] } -> AttrSet
  ```

      # Examples
  ```nix
      resolveConfig { set = { app1 = { config = { home = ".config"; file = "foot/foot.ini"; }; }; }; }
      # => { app1 = { config = { home = ".config"; file = "foot/foot.ini"; path = ".config/foot/foot.ini"; }; }; }

      # Flat form — no wrapping needed
      resolveConfig { app1 = { config = { home = ".config"; file = "foot/foot.ini"; }; }; }
      # => { app1 = { config = { ... path = ".config/foot/foot.ini"; }; }; }
  ```
  */
  resolveConfig = args: let
    set = args.set or args.raw or args;
    path = args.path or ["config"];
  in
    assert isAttrs set;
      mapAttrs (
        _: app: let
          cfg = attrByPath path null app;
        in
          if cfg != null && cfg ? home && cfg ? file
          then recursiveUpdate app (setAttrByPath path (cfg // {path = "${cfg.home}/${cfg.file}";}))
          else app
      )
      set;
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
