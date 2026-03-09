# testing/_.nix
#
# Lightweight test framework for inline module tests.
# Tests live alongside the code they test in _tests attrsets and are
# evaluated lazily — never run unless explicitly inspected.
#
# Access via:  _.testing.mkTest, _.testing.runTests, etc.
#
# Calling conventions for mkTest:
#   Named:      mkTest { desired = "foo"; outcome = normalize "foo"; command = "..."; }
#   Positional: mkTest "foo" (normalize "foo")
{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs isAttrs;
  inherit (lib) deepSeq;
  inherit (builtins) tryEval;
  inherit (_.types.predicates) isTest;

  /**
  Create a test case.

  Accepts either a named-argument attrset or two positional arguments for
  brevity in simple cases.

  # Type
  ```nix
  mkTest :: { desired :: a, outcome :: a, command :: string? } -> Test
       | a -> a -> Test
  ```

  # Examples
  ```nix
  # Named (full form — recommended when documenting)
  mkTest {
    desired = "foo-bar";
    command = ''normalize "Foo Bar"'';
    outcome = normalize "Foo Bar";
  }

  # Positional (concise form — useful in enum/validator tests)
  mkTest true (validator.check "rust")
  mkTest 42   (countMatches { value = xs; check = ys; })
  ```
  */
  _mkTestFrom = desired: outcome: command: let
    value = deepSeq outcome outcome;
  in {
    inherit desired command;
    result = value;
    passed = desired == value;
  };

  mkTest = {
    desired,
    outcome,
    command ? null,
  }:
    _mkTestFrom desired outcome command;

  /**
  Positional shorthand for mkTest — no command string.

  Useful in enum and validator test blocks where the expression is obvious.

  # Type
  ```nix
  mkTest' :: a -> a -> Test
  ```

  # Examples
  ```nix
  validatesRust  = mkTest' true  (languages.validator.check "rust")
  correctCount   = mkTest' 4     (length cpuBrands.values)
  ```
  */
  mkTest' = desired: outcome:
    _mkTestFrom desired outcome null;

  /**
  Create a test case that expects evaluation to throw.

  # Type
  ```nix
  mkThrows :: a -> Test
  ```

  # Examples
  ```nix
  mkThrows (validate { fnName = "f"; argName = "x"; desired = "set"; predicate = isAttrs; outcome = "oops"; })
  ```
  */
  mkThrows = outcome:
    mkTest {
      desired = {success = false; value = false;};
      outcome = tryEval outcome;
    };

  /**
  Recursively walk a test tree and annotate each leaf test with pass/fail metadata.

  Non-test attrsets are recursed into, allowing tests to be nested by group.
  Non-attrset leaves are passed through unchanged.

  # Type
  ```nix
  runTests :: AttrSet -> AttrSet
  ```
  */
  runTests = tests:
    mapAttrs
    (name: test:
      if isTest test
      then let
        error =
          if !test.passed
          then "Test `${name}` failed: expected ${builtins.toJSON test.desired}, got ${builtins.toJSON test.result}"
          else null;
      in {
        inherit (test) desired result passed command;
        inherit error;
      }
      else if isAttrs test
      then runTests test
      else test)
    tests;

  /**
  Collect all failing tests from a runTests result tree into a flat list.

  Useful for CI or assertion-style test runners that want a single boolean.

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
    lib.lists.flatten
    (lib.attrsets.mapAttrsToList
      (name: result:
        if isTest result
        then
          if !result.passed
          then [{path = name; inherit (result) error;}]
          else []
        else if isAttrs result
        then
          map
          (f: f // {path = "${name}.${f.path}";})
          (collectFailures result)
        else [])
      results);

  #~@ NixOS option stubs — used when testing modules outside a full nixpkgs eval

  mkDefaultStub = v: {
    _type = "override";
    content = v;
    priority = 1000;
  };

  mkForceStub = v: {
    _type = "override";
    content = v;
    priority = 50;
  };

  mkEnableOptionStub = desc: {
    _type = "option";
    description = desc;
  };

  exports = {
    inherit
      collectFailures
      mkDefaultStub
      mkEnableOptionStub
      mkForceStub
      mkTest
      mkTest'
      mkThrows
      runTests
      ;
    inherit tryEval;
  };
in
  exports // {_rootAliases = exports;}
