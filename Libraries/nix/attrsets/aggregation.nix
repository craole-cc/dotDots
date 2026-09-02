{
  __moduleRef,
  _,
  ...
}: let
  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.aggregation) intersectAttrs recursiveUpdate;
  inherit (_.attrsets.construction) listToAttrs;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.debug.assertions) mkTest;
  inherit (_.debug.module) mkModuleDebug mkFn;
  inherit (_.debug.runners) runTests;
  inherit (_.lists.aggregation) foldl';
  inherit (_.lists.transformation) unique;
  inherit (_.types.access) typeOf;
  inherit (_.types.predicates) isAttrs isList isFunction;

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
    Recursively merge a list of attrsets or a configured merge pipeline.

    Nested attrsets are merged deeply using native `//` for non-overlapping
    keys and deep rules for collisions. Supports custom strategy functions,
    type-mismatch handling, list concatenation/deduplication, function composition,
    and recursion depth limits.

    # Type
    ```nix
    mergeDeep :: ([AttrSet] | AttrSet) -> AttrSet

  ```

  # Examples

  ```nix
  # Simple list merging
  mergeDeep [
    { a.b = 1; a.c = 2; x = 0; }
    { a.b = 99; y = 1; }
  ]
  # => { a = { b = 99; c = 2; }; x = 0; y = 1; }

  # Configured merging with type safety, list merging, and custom strategy
  mergeDeep {
    depth = 50;
    lists = { merge = true; unique = true; };
    types = { mismatch = "throw"; allowNullOverride = false; functions = "compose"; };
    strategies = {
      extraConfig = base: override: base + "\n" + override;
    };
    attrs = [
      { packages = [ "git" "vim" ]; }
      { packages = [ "curl" "vim" ]; }
    ];
  }
  # => { packages = [ "git" "vim" "curl" ]; }
  ```
  */
  mergeDeep = input: let
    # Formats exceptions using the framework's debug context
    mkError = message: inputVal:
      debug.withLoc {
        function = mkFn {
          name = "mergeDeep";
          fn = mergeDeep;
        };
        inherit message;
        input = inputVal;
      };

    # Parse inputs: direct list of attrsets or a config attrset
    args =
      if isList input
      then {attrs = input;}
      else if isAttrs input && (input ? attrs || input ? sets)
      then input
      else throw (mkError "expected a list of attrsets or a config set containing an 'attrs' list" input);

    # Structured configuration with clean B2 taxonomy
    _config = {
      depth = args.depth or 100;

      # Scoped type-handling options
      types = {
        mismatch = args.types.mismatch or args.onMismatch or "override"; # "override" | "keepBase" | "throw" | (s1: s2: ...)
        allowNullOverride = args.types.allowNullOverride or true; # bool: set to false to protect existing values from null
        functions = args.types.functions or "override"; # "override" | "compose" | "throw"
      };

      # Scoped list-handling options
      lists = {
        merge = args.lists.merge or args.mergeLists or false; # bool: concatenate lists instead of overriding
        unique = args.lists.unique or args.uniqueLists or false; # bool: deduplicate concatenated lists using lib.unique
      };

      # Custom key-specific strategy functions
      strategies = args.strategies or {};
    };

    # Optimized recursive deep merge engine
    updateWithDepth = currentDepth: s1: s2:
      if currentDepth > _config.depth
      then
        throw (mkError "maximum recursion depth of ${toString _config.depth} exceeded" {
          depth = currentDepth;
          base = s1;
          override = s2;
        })
      else if isAttrs s1 && isAttrs s2
      then let
        # Native C++ intersection: only evaluate keys that exist in BOTH sets
        commonKeys = intersectAttrs s1 s2;

        # Apply full configurable logic ONLY to colliding keys
        mergedCommon = listToAttrs (
          map (key: {
            name = key;
            value =
              if _config.strategies ? ${key}
              then _config.strategies.${key} s1.${key} s2.${key}
              else updateWithDepth (currentDepth + 1) s1.${key} s2.${key};
          }) (attrNames commonKeys)
        );
      in
        # (s1 // s2) handles all non-overlapping keys in C++ instantly;
        # mergedCommon overwrites ONLY the colliding keys with their deep results.
        (s1 // s2) // mergedCommon
      else if (s2 == null) && !_config.types.allowNullOverride
      then s1
      else if isFunction s1 && isFunction s2
      then
        if _config.types.functions == "compose"
        then x: s2 (s1 x)
        else if _config.types.functions == "throw"
        then
          throw (mkError "cannot merge functions without an explicit strategy function" {
            base = s1;
            override = s2;
          })
        else s2
      else if isList s1 && isList s2 && _config.lists.merge
      then let
        combined = s1 ++ s2;
      in
        if _config.lists.unique
        then unique combined
        else combined
      else if (typeOf s1 != typeOf s2)
      then let
        handler = _config.types.mismatch;
      in
        if isFunction handler
        then handler s1 s2
        else if handler == "throw"
        then
          throw (mkError "type mismatch encountered (${typeOf s1} vs ${typeOf s2})" {
            base = s1;
            override = s2;
          })
        else if handler == "keepBase"
        then s1
        else s2 # "override"
      else s2;

    attrsList = args.attrs or args.sets;

    mergeTwo = acc: set:
      if !isAttrs set
      then throw (mkError "expected all elements in 'attrs' to be attrsets, found ${typeOf set}" set)
      else updateWithDepth 0 acc set;
  in
    if !isList attrsList
    then throw (mkError "'attrs' must be a list of attrsets" attrsList)
    else foldl' mergeTwo {} attrsList;

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
