# attrsets/merge.nix
#
# Attrset merging strategies.
{
  __moduleRef,
  _,
  lib,
  ...
}: let
  inherit (_.debug.module) mkModuleDebug;
  inherit (_.debug.assertions) mkTest;
  inherit (_.debug.runners) runTests;
  inherit (_debug) mkFn;
  inherit (_.types.predicates) isAttrs isFunction;
  inherit (lib.attrsets) mapAttrs recursiveUpdate;

  _debug = mkModuleDebug __moduleRef;

  /**
  Merge two attrsets, with `override` winning on key conflicts.

  Equivalent to `base // override` but with type guards and a named
  interface that reads clearly at the call site.

  # Type
  ```nix
  merge :: { base :: AttrSet, override :: AttrSet } -> AttrSet
  ```

  # Examples
  ```nix
  merge { base = { a = 1; b = 2; }; override = { b = 99; c = 3; }; }
  # => { a = 1; b = 99; c = 3; }
  ```
  */
  merge = {
    base,
    override,
  }:
    if !isAttrs base
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "merge";
          fn = merge;
        };
        message = "base must be an attrset";
        input = base;
      })
    else if !isAttrs override
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "merge";
          fn = merge;
        };
        message = "override must be an attrset";
        input = override;
      })
    else base // override;

  /**
  Merge two attrsets using a resolver function for key conflicts.

  The resolver receives `{ key, base, override }` and returns the value
  to use for that key.

  # Type
  ```nix
  mergeWith :: { resolver :: { key :: string, base :: a, override :: a } -> a, base :: AttrSet, override :: AttrSet } -> AttrSet
  ```

  # Examples
  ```nix
  # Sum conflicting numeric values
  mergeWith {
    resolver = { key, base, override }: base + override;
    base     = { a = 1; b = 2; };
    override = { b = 10; c = 3; };
  }
  # => { a = 1; b = 12; c = 3; }

  # Concatenate conflicting list values
  mergeWith {
    resolver = { key, base, override }: base ++ override;
    base     = { tags = ["a"]; };
    override = { tags = ["b"]; };
  }
  # => { tags = ["a" "b"]; }
  ```
  */
  mergeWith = {
    resolver,
    base,
    override,
  }:
    if !isFunction resolver
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "mergeWith";
          fn = mergeWith;
        };
        message = "resolver must be a function";
        input = resolver;
      })
    else if !isAttrs base
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "mergeWith";
          fn = mergeWith;
        };
        message = "base must be an attrset";
        input = base;
      })
    else if !isAttrs override
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "mergeWith";
          fn = mergeWith;
        };
        message = "override must be an attrset";
        input = override;
      })
    else
      (base // override)
      // mapAttrs
      (key: value:
        if base ? ${key} && override ? ${key}
        then
          resolver {
            inherit key;
            base = base.${key};
            override = override.${key};
          }
        else value)
      (base // override);

  /**
  Recursively merge two attrsets.

  Nested attrsets are merged deeply rather than replaced wholesale.
  Non-attrset values in `override` win over those in `base`.

  # Type
  ```nix
  mergeDeep :: { base :: AttrSet, override :: AttrSet } -> AttrSet
  ```

  # Examples
  ```nix
  mergeDeep {
    base     = { a.b = 1; a.c = 2; x = 0; };
    override = { a.b = 99; y = 1; };
  }
  # => { a.b = 99; a.c = 2; x = 0; y = 1; }
  ```
  */
  mergeDeep = {
    base,
    override,
  }:
    if !isAttrs base
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "mergeDeep";
          fn = mergeDeep;
        };
        message = "base must be an attrset";
        input = base;
      })
    else if !isAttrs override
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "mergeDeep";
          fn = mergeDeep;
        };
        message = "override must be an attrset";
        input = override;
      })
    else recursiveUpdate base override;

  /**
  Apply defaults: fill in missing keys from `defaults` without overriding
  any keys already present in `attrs`.

  Equivalent to `defaults // attrs`, named for clarity.

  # Type
  ```nix
  withDefaults :: { attrs :: AttrSet, defaults :: AttrSet } -> AttrSet
  ```

  # Examples
  ```nix
  withDefaults {
    attrs    = { color = "red"; };
    defaults = { color = "blue"; size = "medium"; };
  }
  # => { color = "red"; size = "medium"; }
  ```
  */
  withDefaults = {
    attrs,
    defaults,
  }:
    if !isAttrs attrs
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "withDefaults";
          fn = withDefaults;
        };
        message = "attrs must be an attrset";
        input = attrs;
      })
    else if !isAttrs defaults
    then
      throw (_debug.withLoc {
        function = mkFn {
          name = "withDefaults";
          fn = withDefaults;
        };
        message = "defaults must be an attrset";
        input = defaults;
      })
    else defaults // attrs;
in {
  inherit
    merge
    mergeWith
    mergeDeep
    withDefaults
    ;

  _rootAliases = {
    attrMerge = merge;
    attrMergeWith = mergeWith;
    attrMergeDeep = mergeDeep;
    attrWithDefaults = withDefaults;
  };

  _tests = runTests {
    merge = {
      overrideWins = mkTest {
        desired = {
          a = 1;
          b = 99;
          c = 3;
        };
        command = ''merge { base = { a = 1; b = 2; }; override = { b = 99; c = 3; }; }'';
        outcome = merge {
          base = {
            a = 1;
            b = 2;
          };
          override = {
            b = 99;
            c = 3;
          };
        };
      };
      emptyOverride = mkTest {
        desired = {a = 1;};
        command = ''merge { base = { a = 1; }; override = {}; }'';
        outcome = merge {
          base = {a = 1;};
          override = {};
        };
      };
    };

    mergeWith = {
      sumsConflicts = mkTest {
        desired = {
          a = 1;
          b = 12;
          c = 3;
        };
        command = ''mergeWith { resolver = { base, override, ... }: base + override; base = { a = 1; b = 2; }; override = { b = 10; c = 3; }; }'';
        outcome = mergeWith {
          resolver = {
            base,
            override,
            ...
          }:
            base + override;
          base = {
            a = 1;
            b = 2;
          };
          override = {
            b = 10;
            c = 3;
          };
        };
      };
      concatenatesLists = mkTest {
        desired = {tags = ["a" "b"];};
        command = ''mergeWith { resolver = { base, override, ... }: base ++ override; base = { tags = ["a"]; }; override = { tags = ["b"]; }; }'';
        outcome = mergeWith {
          resolver = {
            base,
            override,
            ...
          }:
            base ++ override;
          base = {tags = ["a"];};
          override = {tags = ["b"];};
        };
      };
    };

    mergeDeep = {
      preservesUnconflicted = mkTest {
        desired = {
          a = {
            b = 99;
            c = 2;
          };
          x = 0;
          y = 1;
        };
        command = ''mergeDeep { base = { a.b = 1; a.c = 2; x = 0; }; override = { a.b = 99; y = 1; }; }'';
        outcome = mergeDeep {
          base = {
            a.b = 1;
            a.c = 2;
            x = 0;
          };
          override = {
            a.b = 99;
            y = 1;
          };
        };
      };
    };

    withDefaults = {
      existingKeyUnchanged = mkTest {
        desired = {
          color = "red";
          size = "medium";
        };
        command = ''withDefaults { attrs = { color = "red"; }; defaults = { color = "blue"; size = "medium"; }; }'';
        outcome = withDefaults {
          attrs = {color = "red";};
          defaults = {
            color = "blue";
            size = "medium";
          };
        };
      };
      missingKeyFilled = mkTest {
        desired = {
          color = "blue";
          size = "medium";
        };
        command = ''withDefaults { attrs = {}; defaults = { color = "blue"; size = "medium"; }; }'';
        outcome = withDefaults {
          attrs = {};
          defaults = {
            color = "blue";
            size = "medium";
          };
        };
      };
    };
  };
}
