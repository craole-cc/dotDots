{
  _,
  __moduleRef,
  ...
}: let
  meta = let
    doc = ''

      # Builders [Layer 3]

      Composable partition builders for application attribute sets.

      Each builder accepts a `field`, a source `set`, and caller-supplied
      output key names - key names are never hardcoded.  Semantic wrappers
      fix `field` for well-known registry fields (maturity, protocol, scope,
      capability, config, independence, engine).  `mkQuery` composes them
      into a single partitioned view.

      ## Dependencies

      - `applications.selection`  - withFlag, withoutFlag, withValue
      - `applications.predicates` - field accessors and membership tests
      - `applications.groups`     - pre-grouped sets consumed by builders
      - `applications.primitives` - low-level field readers
    '';
    functions = {inherit mkBool;};
    exports = {
      local = functions;
      alias = {
        mkBoolExample = mkBool;
      };
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.applications.selection) withFlag withoutFlag;
  inherit (_.debug.format) mkExample;
  inherit (_.debug.module.mkModule __moduleRef) withDoc;
  inherit (_.types.predicates) isAttrs isString;

  /**
  Partition an attribute set into two subsets based on the presence or absence
  of a boolean flag field, exposing them under caller-supplied keys.

  # Type
  ```nix
  mkBool :: {
    field    :: string,
    trueKey  :: string,
    falseKey :: string,
    set      :: AttrSet,
  } -> { ${trueKey} :: AttrSet, ${falseKey} :: AttrSet }
  ```

  # Examples
  ```nix
  mkBool {
    field    = "active";
    trueKey  = "running";
    falseKey = "stopped";
    set      = { a = { active = true; }; b = { active = false; }; };
  }
  # => { running = { a = { active = true;  }; };
  #      stopped = { b = { active = false; }; }; }
  ```
  */
  mkBool = {
    field,
    trueKey,
    falseKey,
    set,
  }:
    if !isString field
    then
      throw (withDoc {
        function = "mkBool";
        message = "field must be a string naming the boolean attribute to partition on";
        signature = "{ field :: string, trueKey :: string, falseKey :: string, set :: AttrSet } -> AttrSet";
        input = field;
        example = mkExample {
          cmd = ''mkBool { field = "active"; trueKey = "on"; falseKey = "off"; set = s; }'';
          res = "{ on = { ... }; off = { ... }; }";
        };
      })
    else if !isString trueKey
    then
      throw (withDoc {
        function = "mkBool";
        message = "trueKey must be a string - it becomes the output attribute name for flag=true items";
        signature = "{ field :: string, trueKey :: string, falseKey :: string, set :: AttrSet } -> AttrSet";
        input = trueKey;
        example = mkExample {
          cmd = ''mkBool { field = "active"; trueKey = "running"; falseKey = "stopped"; set = s; }'';
          res = "{ running = { ... }; stopped = { ... }; }";
        };
      })
    else if !isString falseKey
    then
      throw (withDoc {
        function = "mkBool";
        message = "falseKey must be a string - it becomes the output attribute name for flag=false items";
        signature = "{ field :: string, trueKey :: string, falseKey :: string, set :: AttrSet } -> AttrSet";
        input = falseKey;
        example = mkExample {
          cmd = ''mkBool { field = "active"; trueKey = "running"; falseKey = "stopped"; set = s; }'';
          res = "{ running = { ... }; stopped = { ... }; }";
        };
      })
    else if trueKey == falseKey
    then
      throw (withDoc {
        function = "mkBool";
        message = "trueKey and falseKey must be different strings - they cannot both write to the same output key";
        signature = "{ field :: string, trueKey :: string, falseKey :: string, set :: AttrSet } -> AttrSet";
        input = {inherit trueKey falseKey;};
        example = mkExample {
          cmd = ''mkBool { field = "active"; trueKey = "running"; falseKey = "stopped"; set = s; }'';
          res = "{ running = { ... }; stopped = { ... }; }";
        };
      })
    else if !isAttrs set
    then
      throw (withDoc {
        function = "mkBool";
        message = "set must be an attribute set of items to partition";
        signature = "{ field :: string, trueKey :: string, falseKey :: string, set :: AttrSet } -> AttrSet";
        input = set;
        example = mkExample {
          cmd = ''mkBool { field = "active"; trueKey = "running"; falseKey = "stopped"; set = { a = { active = true; }; }; }'';
          res = "{ running = { a = { active = true; }; }; stopped = { }; }";
        };
      })
    else {
      ${trueKey} = withFlag {inherit field set;};
      ${falseKey} = withoutFlag {inherit field set;};
    };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
    __tests = let
      inherit (_.debug.assertions) mkTest;
      inherit (_.debug.runners) runTests;

      apps = {
        alpha = {
          active = true;
          name = "alice";
        };
        beta = {
          active = false;
          name = "bob";
        };
        gamma = {
          active = true;
          name = "carol";
        };
      };

      result = mkBool {
        field = "active";
        trueKey = "running";
        falseKey = "stopped";
        set = apps;
      };
    in
      runTests {
        mkBool = {
          trueKeyContainsFlaggedItems = mkTest {
            desired = true;
            command = "result.running ? alpha && result.running ? gamma";
            outcome = result.running ? alpha && result.running ? gamma;
          };

          falseKeyContainsUnflaggedItems = mkTest {
            desired = true;
            command = "result.stopped ? beta";
            outcome = result.stopped ? beta;
          };

          trueItemsExcludedFromFalseKey = mkTest {
            desired = false;
            command = "result.stopped ? alpha";
            outcome = result.stopped ? alpha;
          };

          falseItemsExcludedFromTrueKey = mkTest {
            desired = false;
            command = "result.running ? beta";
            outcome = result.running ? beta;
          };

          usesCallerSuppliedKeys = mkTest {
            desired = true;
            command = "result ? running && result ? stopped";
            outcome = result ? running && result ? stopped;
          };

          preservesItemStructure = mkTest {
            desired = {
              active = true;
              name = "alice";
            };
            command = "result.running.alpha";
            outcome = result.running.alpha;
          };

          allTrueMakesFalseKeyEmpty = mkTest {
            desired = true;
            command = ''(mkBool { field = "on"; trueKey = "yes"; falseKey = "no"; set = allOn; }).no == {}'';
            outcome = let
              allOn = {
                x = {
                  on = true;
                };
                y = {
                  on = true;
                };
              };
            in
              (mkBool {
                field = "on";
                trueKey = "yes";
                falseKey = "no";
                set = allOn;
              }).no
              == {};
          };

          allFalseMakesTrueKeyEmpty = mkTest {
            desired = true;
            command = ''(mkBool { field = "on"; trueKey = "yes"; falseKey = "no"; set = allOff; }).yes == {}'';
            outcome = let
              allOff = {
                x = {
                  on = false;
                };
                y = {
                  on = false;
                };
              };
            in
              (mkBool {
                field = "on";
                trueKey = "yes";
                falseKey = "no";
                set = allOff;
              }).yes
              == {};
          };

          emptySetProducesBothSidesEmpty = mkTest {
            desired = true;
            command = ''let r = mkBool { field = "active"; trueKey = "running"; falseKey = "stopped"; set = {}; }; in r.running == {} && r.stopped == {}'';
            outcome = let
              r = mkBool {
                field = "active";
                trueKey = "running";
                falseKey = "stopped";
                set = {};
              };
            in
              r.running == {} && r.stopped == {};
          };
        };
      };
  }
