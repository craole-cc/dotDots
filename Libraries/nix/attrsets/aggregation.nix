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
  Deep-merge two devShell-fragment attrsets, combining `env`, `lib`,
  `packages`, `shellHook`, and `helpEntries` instead of replacing them.
  Unlike `mergeShellFragments`, this does NOT strip `lib` - it is the
  step function for folding fragments where each subsequent fragment
  still needs to read the accumulated `lib` (e.g. `get`/`set`/`tag`
  helpers) via its own args. Use `mergeShellFragments` (which calls
  this internally and strips `lib` at the end) once folding is done
  and the result is headed to `mkShell`.

  # Type
  ```nix
  mergeAccumulate :: AttrSet -> AttrSet -> AttrSet
  ```
  */
  mergeAccumulate = a: b:
    (a // b)
    // {
      env = recursiveUpdate (a.env or {}) (b.env or {});
      lib = recursiveUpdate (a.lib or {}) (b.lib or {});
      packages = (a.packages or []) ++ (b.packages or []);
      shellHook = (a.shellHook or "") + "\n" + (b.shellHook or "");
      helpEntries = (a.helpEntries or []) ++ (b.helpEntries or []);
    };

  # TODO: Update hermes to use mkShellFragments instead of mergeShellFragments, so that each fragment can see the accumulated lib and env from previous fragments. Then we can remove mergeShellFragments and mergeAccumulate and just use mkShellFragments with a single call.
  mergeShellFragments = fragments:
    removeAttrs (foldl' mergeAccumulate {} fragments) ["lib"];

  /**
  Build a devShell by folding a list of fragment directories, each
  imported with the accumulated result of every fragment before it
  merged into its args - so fragment N can read env/lib/packages/etc.
  contributed by fragments 0..N-1 without the caller manually wiring
  each fragment's dependencies by hand.

  Four keys are combined instead of replaced across the fold, so a
  later fragment never silently erases an earlier one's contribution:
  - `env` is deep-merged (`recursiveUpdate`)
  - `lib` is deep-merged (`recursiveUpdate`) - each fragment's local
    helpers (e.g. get/set/tag), readable by every fragment after it,
    but stripped from the final result since `env` must contain only
    strings/bools/ints/derivations for `mkShell`/`mkDerivation`
  - `packages` is concatenated
  - `shellHook` is concatenated with a newline separator
  - `helpEntries` is concatenated

  Every other key keeps ordinary last-wins `//` semantics.

  # Inputs
  `dirs`
  : list of paths, each importable as `path (args // accumulatedSoFar)`,
    in dependency order - a fragment can only see fragments listed
    before it, never after

  `args`
  : base args passed to every fragment (pkgs, lix, env, etc.)

  # Type
  ```nix
  mkShellFragments :: { dirs :: [Path], args :: AttrSet } -> AttrSet
  ```
  */
  mkShellFragments = {
    dirs,
    args,
  }: let
    merge = a: b:
      (a // b)
      // {
        env = recursiveUpdate (a.env or {}) (b.env or {});
        lib = recursiveUpdate (a.lib or {}) (b.lib or {});
        packages = (a.packages or []) ++ (b.packages or []);
        shellHook = (a.shellHook or "") + "\n" + (b.shellHook or "");
        helpEntries = (a.helpEntries or []) ++ (b.helpEntries or []);
      };

    built =
      foldl' (acc: dir: let
        fragment = import dir (recursiveUpdate args acc);
      in
        merge acc fragment)
      {}
      dirs;
  in
    removeAttrs built ["lib"];
in {
  inherit
    merge
    mergeWith
    mergeDeep
    withDefaults
    recursiveMergeAll
    mergeShellFragments
    mkShellFragments
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
