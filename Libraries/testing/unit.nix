{lib, ...}: let
  inherit (lib.attrsets) mapAttrs isAttrs;

  # Create a test case
  mkTest = expected: actual: {
    inherit expected;
    result = actual;
    passed = expected == actual;
  };

  # Check if something is a test result (has expected/result/passed)
  isTest = test:
    isAttrs test
    && test ? expected
    && test ? result
    && test ? passed;

  # Run all tests and format results (handles nested structures)
  runTests = tests:
    mapAttrs (
      name: test:
        if isTest test
        then {
          inherit (test) expected result passed;
          error =
            if !test.passed
            then "Expected ${toString test.expected}, got ${toString test.result}"
            else null;
        }
        else runTests test # Recursively handle nested test groups
    )
    tests;
  testLibs = {inherit mkTest isTest runTests;};
in
  testLibs
  // {
    _rootAliases = testLibs;
  }
