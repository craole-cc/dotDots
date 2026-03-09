# testing/runners.nix
#
# Test tree execution and failure collection.
{_, lib, ...}: let
  inherit (lib.attrsets) mapAttrs isAttrs mapAttrsToList;
  inherit (lib.lists) flatten;
  inherit (_.types.predicates) isTest;

  /**
  Recursively walk a test tree and annotate each leaf test with pass/fail metadata.

  Non-test attrsets are recursed into, allowing tests to be grouped by topic.
  Non-attrset leaves pass through unchanged.

  # Type
  ```nix
  runTests :: AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  :p _.strings.transform._tests
  # { toLower = { singleString = { passed = true; ... }; }; ... }
  ```
  */
  runTests = tests:
    mapAttrs
    (name: test:
      if isTest test
      then {
        inherit (test) desired result passed command;
        error =
          if !test.passed
          then "Test `${name}` failed: expected ${builtins.toJSON test.desired}, got ${builtins.toJSON test.result}"
          else null;
      }
      else if isAttrs test
      then runTests test
      else test)
    tests;

  /**
  Collect all failing tests from a `runTests` result tree into a flat list.

  Each entry is `{ path :: string, error :: string }`.
  An empty list means all tests passed.

  # Type
  ```nix
  collectFailures :: AttrSet -> [{ path :: string, error :: string }]
  ```

  # Examples
  ```nix
  failures = collectFailures (runTests myModule._tests);
  assert failures == []; "all tests passed"
  ```
  */
  collectFailures = results:
    flatten
    (mapAttrsToList
      (name: result:
        if isTest result
        then if !result.passed then [{path = name; inherit (result) error;}] else []
        else if isAttrs result
        then map (f: f // {path = "${name}.${f.path}";}) (collectFailures result)
        else [])
      results);

  exports = {inherit runTests collectFailures;};
in
  exports // {_rootAliases = exports;}
