{
  __moduleRef,
  _,
  ...
}: let
  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.debug.assertions) mkTest;
  inherit (_.debug.module) mkModuleDebug mkFn;
  inherit (_.debug.runners) runTests;
  inherit (_.lists.aggregation) foldl';
  inherit (_.types.predicates) isAttrs isFunction;

  debug = mkModuleDebug __moduleRef;

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
      throw (
        debug.withLoc {
          function = mkFn {
            name = "merge";
            fn = merge;
          };
          message = "base must be an attrset";
          input = base;
        }
      )
    else if !isAttrs override
    then
      throw (
        debug.withLoc {
          function = mkFn {
            name = "merge";
            fn = merge;
          };
          message = "override must be an attrset";
          input = override;
        }
      )
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
      throw (
        debug.withLoc {
          function = mkFn {
            name = "mergeWith";
            fn = mergeWith;
          };
          message = "resolver must be a function";
          input = resolver;
        }
      )
    else if !isAttrs base
    then
      throw (
        debug.withLoc {
          function = mkFn {
            name = "mergeWith";
            fn = mergeWith;
          };
          message = "base must be an attrset";
          input = base;
        }
      )
    else if !isAttrs override
    then
      throw (
        debug.withLoc {
          function = mkFn {
            name = "mergeWith";
            fn = mergeWith;
          };
          message = "override must be an attrset";
          input = override;
        }
      )
    else
      (base // override)
      // mapAttrs (
        key: value:
          if base ? ${key} && override ? ${key}
          then
            resolver {
              inherit key;
              base = base.${key};
              override = override.${key};
            }
          else value
      ) (base // override);

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
      throw (
        debug.withLoc {
          function = mkFn {
            name = "mergeDeep";
            fn = mergeDeep;
          };
          message = "base must be an attrset";
          input = base;
        }
      )
    else if !isAttrs override
    then
      throw (
        debug.withLoc {
          function = mkFn {
            name = "mergeDeep";
            fn = mergeDeep;
          };
          message = "override must be an attrset";
          input = override;
        }
      )
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
      throw (
        debug.withLoc {
          function = mkFn {
            name = "withDefaults";
            fn = withDefaults;
          };
          message = "attrs must be an attrset";
          input = attrs;
        }
      )
    else if !isAttrs defaults
    then
      throw (
        debug.withLoc {
          function = mkFn {
            name = "withDefaults";
            fn = withDefaults;
          };
          message = "defaults must be an attrset";
          input = defaults;
        }
      )
    else defaults // attrs;

  /**
  Deep-merge a list of attrsets, left-to-right, combining nested attrsets
  recursively instead of the shallow last-wins semantics of `//`/`foldl' (//)`.

  Equivalent to folding `recursiveUpdate` across `sets`, provided purely as
  the list-oriented counterpart to the pairwise `recursiveUpdate` - useful
  wherever more than two module/config fragments need combining without a
  later one silently clobbering an earlier one's nested keys (e.g. combining
  several modules that each contribute their own `env` attrset).

  # Inputs
  `sets`
  : list of attrsets to merge, in priority order (later wins on scalar
    key conflicts, recursively)

  # Type
  > recursiveMergeAll :: [AttrSet] -> AttrSet

  # Examples
  - recursiveMergeAll [ {env = {A = 1;};} {env = {B = 2;};} ]

  \```nix
    { env = { A = 1; B = 2; }; }
  \```
  */
  recursiveMergeAll = sets: foldl' recursiveUpdate {} sets;

  /**
  Deep-merge a list of devShell-fragment attrsets (each optionally
  carrying `env`, `packages`, `shellHook`, `lib`, plus arbitrary other
  keys - the shape `mkShell` consumes, plus a local-helpers escape hatch)
  into one shell-ready attrset.

  Unlike a plain `//`-fold, four keys are combined instead of replaced,
  so a later fragment never silently erases an earlier one's contribution:
  - `env` is deep-merged (`recursiveUpdate`)
  - `lib` is deep-merged (`recursiveUpdate`) - lets each fragment define
    its own local helpers (e.g. `get`/`set`/`tag`) that compose across
    fragments during construction, without those helpers ending up in
    `env` itself (where `mkShell`/`mkDerivation` would reject them, since
    `env` may only contain strings, bools, ints, or derivations)
  - `packages` is concatenated
  - `shellHook` is concatenated with a newline separator

  Every other key keeps ordinary last-wins `//` semantics.

  `lib` is merged for the benefit of fragments still being constructed
  (e.g. a later fragment reading an earlier one's `lib.tag`), but is
  never meant to reach `mkShell` - it is stripped from the final result,
  so the returned attrset never carries a `lib` key regardless of
  whether any input fragment defined one.

  # Type
  ```nix
    mergeShellFragments :: [AttrSet] -> AttrSet
  ```
  */
  mergeShellFragments = fragments: let
    merge = a: b:
      (a // b)
      // {
        env = recursiveUpdate (a.env or {}) (b.env or {});
        lib = recursiveUpdate (a.lib or {}) (b.lib or {});
        packages = (a.packages or []) ++ (b.packages or []);
        shellHook = (a.shellHook or "") + "\n" + (b.shellHook or "");
        helpEntries = (a.helpEntries or []) ++ (b.helpEntries or []);
      };
  in
    removeAttrs (foldl' merge {} fragments) ["lib"];
in {
  inherit
    merge
    mergeWith
    mergeDeep
    withDefaults
    recursiveMergeAll
    mergeShellFragments
    ;

  __rootAliases = {
    attrMerge = merge;
    attrMergeWith = mergeWith;
    attrMergeDeep = mergeDeep;
    attrWithDefaults = withDefaults;
  };

  __tests = runTests {
    merge = {
      overrideWins = mkTest {
        desired = {
          a = 1;
          b = 99;
          c = 3;
        };
        command = "merge { base = { a = 1; b = 2; }; override = { b = 99; c = 3; }; }";
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
        desired = {
          a = 1;
        };
        command = "merge { base = { a = 1; }; override = {}; }";
        outcome = merge {
          base = {
            a = 1;
          };
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
        command = "mergeWith { resolver = { base, override, ... }: base + override; base = { a = 1; b = 2; }; override = { b = 10; c = 3; }; }";
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
        desired = {
          tags = [
            "a"
            "b"
          ];
        };
        command = ''mergeWith { resolver = { base, override, ... }: base ++ override; base = { tags = ["a"]; }; override = { tags = ["b"]; }; }'';
        outcome = mergeWith {
          resolver = {
            base,
            override,
            ...
          }:
            base ++ override;
          base = {
            tags = ["a"];
          };
          override = {
            tags = ["b"];
          };
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
        command = "mergeDeep { base = { a.b = 1; a.c = 2; x = 0; }; override = { a.b = 99; y = 1; }; }";
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
          attrs = {
            color = "red";
          };
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

    mergeShellFragments = {
      envDeepMerges = mkTest {
        desired = {
          env = {
            A = "1";
            B = "2";
          };
          packages = [];
          shellHook = "\n";
          helpEntries = [];
        };
        command = ''mergeShellFragments [ {env = {A = "1";};} {env = {B = "2";};} ]'';
        outcome = mergeShellFragments [
          {env = {A = "1";};}
          {env = {B = "2";};}
        ];
      };

      packagesConcatenate = mkTest {
        desired = {
          env = {};
          packages = ["a" "b"];
          shellHook = "\n";
          helpEntries = [];
        };
        command = ''mergeShellFragments [ {packages = ["a"];} {packages = ["b"];} ]'';
        outcome = mergeShellFragments [
          {packages = ["a"];}
          {packages = ["b"];}
        ];
      };

      shellHookConcatenatesWithNewline = mkTest {
        desired = {
          env = {};
          packages = [];
          shellHook = "echo one\n\necho two\n";
          helpEntries = [];
        };
        command = ''mergeShellFragments [ {shellHook = "echo one";} {shellHook = "echo two";} ]'';
        outcome = mergeShellFragments [
          {shellHook = "echo one";}
          {shellHook = "echo two";}
        ];
      };

      helpEntriesConcatenate = mkTest {
        desired = {
          env = {};
          packages = [];
          shellHook = "\n";
          helpEntries = [
            {command = "a";}
            {command = "b";}
          ];
        };
        command = ''mergeShellFragments [ {helpEntries = [{command = "a";}];} {helpEntries = [{command = "b";}];} ]'';
        outcome = mergeShellFragments [
          {helpEntries = [{command = "a";}];}
          {helpEntries = [{command = "b";}];}
        ];
      };

      libMergesButNeverSurfaces = mkTest {
        desired = {
          env = {};
          packages = [];
          shellHook = "\n";
          helpEntries = [];
        };
        command = ''mergeShellFragments [ {lib = {get = x: x;};} {lib = {tag = x: x;};} ]'';
        outcome = mergeShellFragments [
          {lib = {get = x: x;};}
          {lib = {tag = x: x;};}
        ];
      };

      otherKeysLastWins = mkTest {
        desired = {
          env = {};
          packages = [];
          shellHook = "\n";
          helpEntries = [];
          description = "second";
        };
        command = ''mergeShellFragments [ {description = "first";} {description = "second";} ]'';
        outcome = mergeShellFragments [
          {description = "first";}
          {description = "second";}
        ];
      };
    };
  };
}
