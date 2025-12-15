{lib, ...}: {
  # Create a test case
  mkTest = expected: actual: {
    inherit expected;
    result = actual;
    passed = expected == actual;
  };

  # Run all tests and format results
  runTests = tests:
    lib.attrsets.mapAttrs (name: test: {
      inherit (test) expected result passed;
      error =
        if !test.passed
        then "Expected ${toString test.expected}, got ${toString test.result}"
        else null;
    })
    tests;
}
