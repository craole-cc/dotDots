# attrsets/access.nix
#
# Safe attribute access and selection utilities.
{
  __libraryPath,
  _,
  lib,
  ...
}: let
  inherit (_.debug.module) mkModuleDebug;
  inherit (_.debug.assertions) mkTest;
  inherit (_.debug.runners) runTests;
  inherit (_.types.predicates) isAttrs isList;
  inherit (_debug) mkFn;
  inherit (lib.attrsets) hasAttr filterAttrs mapAttrsToList;
  inherit (lib.lists) foldl';

  _debug = mkModuleDebug __libraryPath;

  /**
  Get an attribute value with a fallback default.

  Unlike `attrs.key or default`, works with dynamic key names and
  correctly handles the case where the key exists but holds null.

  # Type
  ```nix
  getOr :: { attrs :: AttrSet, key :: string, default :: a } -> a
  ```

  # Examples
  ```nix
  getOr { attrs = { foo = "bar"; }; key = "foo"; default = "?"; }  # => "bar"
  getOr { attrs = { foo = null; }; key = "foo"; default = "?"; }   # => null
  getOr { attrs = {};              key = "foo"; default = "?"; }   # => "?"
  ```
  */
  getOr = {
    attrs,
    key,
    default,
  }:
    if !isAttrs attrs
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "getOr";
          fn = getOr;
        };
        message = "attrs must be an attrset";
        input = attrs;
      })
    else if hasAttr key attrs
    then attrs.${key}
    else default;

  /**
  Get a deeply nested attribute value, returning a default if any key
  along the path is missing.

  # Type
  ```nix
  getIn :: { attrs :: AttrSet, path :: [string], default :: a } -> a
  ```

  # Examples
  ```nix
  getIn { attrs = { a.b.c = 1; }; path = ["a" "b" "c"]; default = 0; }  # => 1
  getIn { attrs = { a.b = 1; };   path = ["a" "x" "c"]; default = 0; }  # => 0
  getIn { attrs = {};              path = ["a"];          default = 0; }  # => 0
  ```
  */
  getIn = {
    attrs,
    path,
    default,
  }:
    if !isAttrs attrs
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "getIn";
          fn = getIn;
        };
        message = "attrs must be an attrset";
        input = attrs;
      })
    else if !isList path
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "getIn";
          fn = getIn;
        };
        message = "path must be a list of strings";
        input = path;
      })
    else
      foldl'
      (acc: key:
        if isAttrs acc && hasAttr key acc
        then acc.${key}
        else default)
      attrs
      path;

  /**
  Return a new attrset containing only the listed keys.

  Missing keys are silently omitted — no error is thrown.

  # Type
  ```nix
  pick :: { attrs :: AttrSet, keys :: [string] } -> AttrSet
  ```

  # Examples
  ```nix
  pick { attrs = { a = 1; b = 2; c = 3; }; keys = ["a" "c"]; }
  # => { a = 1; c = 3; }

  pick { attrs = { a = 1; }; keys = ["a" "z"]; }
  # => { a = 1; }
  ```
  */
  pick = {
    attrs,
    keys,
  }:
    if !isAttrs attrs
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "pick";
          fn = pick;
        };
        message = "attrs must be an attrset";
        input = attrs;
      })
    else if !isList keys
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "pick";
          fn = pick;
        };
        message = "keys must be a list of strings";
        input = keys;
      })
    else filterAttrs (key: _: builtins.elem key keys) attrs;

  /**
  Return a new attrset with the listed keys removed.

  Missing keys are silently ignored.

  # Type
  ```nix
  omit :: { attrs :: AttrSet, keys :: [string] } -> AttrSet
  ```

  # Examples
  ```nix
  omit { attrs = { a = 1; b = 2; c = 3; }; keys = ["b"]; }
  # => { a = 1; c = 3; }

  omit { attrs = { a = 1; }; keys = ["z"]; }
  # => { a = 1; }
  ```
  */
  omit = {
    attrs,
    keys,
  }:
    if !isAttrs attrs
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "omit";
          fn = omit;
        };
        message = "attrs must be an attrset";
        input = attrs;
      })
    else if !isList keys
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "omit";
          fn = omit;
        };
        message = "keys must be a list of strings";
        input = keys;
      })
    else filterAttrs (key: _: !(builtins.elem key keys)) attrs;

  /**
  Rename a single key in an attrset, preserving all other keys.

  A no-op if `from` does not exist.

  # Type
  ```nix
  renameKey :: { attrs :: AttrSet, from :: string, to :: string } -> AttrSet
  ```

  # Examples
  ```nix
  renameKey { attrs = { foo = 1; bar = 2; }; from = "foo"; to = "baz"; }
  # => { baz = 1; bar = 2; }

  renameKey { attrs = { a = 1; }; from = "x"; to = "y"; }
  # => { a = 1; }   (no-op — "x" didn't exist)
  ```
  */
  renameKey = {
    attrs,
    from,
    to,
  }:
    if !isAttrs attrs
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "renameKey";
          fn = renameKey;
        };
        message = "attrs must be an attrset";
        input = attrs;
      })
    else if !(hasAttr from attrs)
    then attrs
    else
      (omit {
        inherit attrs;
        keys = [from];
      })
      // {"${to}" = attrs.${from};};

  /**
  Transform all keys in an attrset using a function.

  # Type
  ```nix
  mapKeys :: (string -> string) -> AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  mapKeys (key: "prefix_" + key) { foo = 1; bar = 2; }
  # => { prefix_foo = 1; prefix_bar = 2; }
  ```
  */
  mapKeys = fn: attrs:
    if !isAttrs attrs
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "mapKeys";
          fn = mapKeys;
        };
        message = "attrs must be an attrset";
        input = attrs;
      })
    else
      builtins.listToAttrs
      (mapAttrsToList (key: value: {
          name = fn key;
          value = value;
        })
        attrs);

  /**
  Remove all keys whose value is null.

  # Type
  ```nix
  compact :: AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  compact { a = 1; b = null; c = "x"; }
  # => { a = 1; c = "x"; }
  ```
  */
  compact = attrs:
    if !isAttrs attrs
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "compact";
          fn = compact;
        };
        message = "attrs must be an attrset";
        input = attrs;
      })
    else filterAttrs (_: value: value != null) attrs;
in {
  inherit
    compact
    getIn
    getOr
    mapKeys
    omit
    pick
    renameKey
    ;

  _rootAliases = {
    attrGetOr = getOr;
    attrGetIn = getIn;
    attrPick = pick;
    attrOmit = omit;
    attrRename = renameKey;
    attrMapKeys = mapKeys;
    attrCompact = compact;
  };

  _tests = runTests {
    getOr = {
      existingKey = mkTest {
        desired = "bar";
        command = ''getOr { attrs = { foo = "bar"; }; key = "foo"; default = "?"; }'';
        outcome = getOr {
          attrs = {foo = "bar";};
          key = "foo";
          default = "?";
        };
      };
      missingKey = mkTest {
        desired = "?";
        command = ''getOr { attrs = {}; key = "foo"; default = "?"; }'';
        outcome = getOr {
          attrs = {};
          key = "foo";
          default = "?";
        };
      };
      nullValuePreserved = mkTest {
        desired = null;
        command = ''getOr { attrs = { foo = null; }; key = "foo"; default = "?"; }'';
        outcome = getOr {
          attrs = {foo = null;};
          key = "foo";
          default = "?";
        };
      };
    };

    getIn = {
      deepPath = mkTest {
        desired = 1;
        command = ''getIn { attrs = { a.b.c = 1; }; path = ["a" "b" "c"]; default = 0; }'';
        outcome = getIn {
          attrs = {a.b.c = 1;};
          path = ["a" "b" "c"];
          default = 0;
        };
      };
      missingMiddle = mkTest {
        desired = 0;
        command = ''getIn { attrs = { a.b = 1; }; path = ["a" "x" "c"]; default = 0; }'';
        outcome = getIn {
          attrs = {a.b = 1;};
          path = ["a" "x" "c"];
          default = 0;
        };
      };
      emptyAttrs = mkTest {
        desired = 0;
        command = ''getIn { attrs = {}; path = ["a"]; default = 0; }'';
        outcome = getIn {
          attrs = {};
          path = ["a"];
          default = 0;
        };
      };
    };

    pick = {
      selectsKeys = mkTest {
        desired = {
          a = 1;
          c = 3;
        };
        command = ''pick { attrs = { a = 1; b = 2; c = 3; }; keys = ["a" "c"]; }'';
        outcome = pick {
          attrs = {
            a = 1;
            b = 2;
            c = 3;
          };
          keys = ["a" "c"];
        };
      };
      missingKeysIgnored = mkTest {
        desired = {a = 1;};
        command = ''pick { attrs = { a = 1; }; keys = ["a" "z"]; }'';
        outcome = pick {
          attrs = {a = 1;};
          keys = ["a" "z"];
        };
      };
    };

    omit = {
      removesKeys = mkTest {
        desired = {
          a = 1;
          c = 3;
        };
        command = ''omit { attrs = { a = 1; b = 2; c = 3; }; keys = ["b"]; }'';
        outcome = omit {
          attrs = {
            a = 1;
            b = 2;
            c = 3;
          };
          keys = ["b"];
        };
      };
      missingKeysIgnored = mkTest {
        desired = {a = 1;};
        command = ''omit { attrs = { a = 1; }; keys = ["z"]; }'';
        outcome = omit {
          attrs = {a = 1;};
          keys = ["z"];
        };
      };
    };

    renameKey = {
      renamesExisting = mkTest {
        desired = {
          baz = 1;
          bar = 2;
        };
        command = ''renameKey { attrs = { foo = 1; bar = 2; }; from = "foo"; to = "baz"; }'';
        outcome = renameKey {
          attrs = {
            foo = 1;
            bar = 2;
          };
          from = "foo";
          to = "baz";
        };
      };
      noopIfMissing = mkTest {
        desired = {a = 1;};
        command = ''renameKey { attrs = { a = 1; }; from = "x"; to = "y"; }'';
        outcome = renameKey {
          attrs = {a = 1;};
          from = "x";
          to = "y";
        };
      };
    };

    mapKeys = {
      prefixesKeys = mkTest {
        desired = {
          prefix_foo = 1;
          prefix_bar = 2;
        };
        command = ''mapKeys (key: "prefix_" + key) { foo = 1; bar = 2; }'';
        outcome = mapKeys (key: "prefix_" + key) {
          foo = 1;
          bar = 2;
        };
      };
    };

    compact = {
      removesNulls = mkTest {
        desired = {
          a = 1;
          c = "x";
        };
        command = ''compact { a = 1; b = null; c = "x"; }'';
        outcome = compact {
          a = 1;
          b = null;
          c = "x";
        };
      };
      keepsZeroAndFalse = mkTest {
        desired = {
          a = 0;
          b = false;
        };
        command = ''compact { a = 0; b = false; }'';
        outcome = compact {
          a = 0;
          b = false;
        };
      };
    };
  };
}
