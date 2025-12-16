{lib, ...}: let
  inherit (lib.attrsets) mapAttrs isAttrs;
  inherit (lib) deepSeq;
  inherit (builtins) tryEval;

  mkTest = expectedOrAttrs: exprOrNull: let
    args =
      if isAttrs expectedOrAttrs && expectedOrAttrs ? expected && expectedOrAttrs ? expr
      then expectedOrAttrs
      else {
        expected = expectedOrAttrs;
        expr = exprOrNull;
      };

    value = deepSeq args.expr args.expr;
    passed = args.expected == value;
  in {
    expected = args.expected;
    result = value;
    inherit passed;
  };

  isTest = test:
    isAttrs test
    && test ? expected
    && test ? result
    && test ? passed;

  runTests = tests:
    mapAttrs
    (
      name: test:
        if isTest test
        then let
          error =
            if !test.passed
            then "Test `${name}` failed: expected ${toString test.expected}, got ${toString test.result}"
            else null;
        in {
          inherit (test) expected result passed;
          inherit error;
        }
        else runTests test
    )
    tests;

  # Convenience: assert that an expression throws
  mkThrows = expr:
    mkTest {
      expr = tryEval expr;
      expected = {
        success = false;
        value = false;
      };
    };

  mkDefaultStub = v: {
    _type = "override";
    content = v;
    priority = 1000;
  };

  mkEnableOptionStub = desc: {
    _type = "option";
    description = desc;
  };

  mkForceStub = v: {
    _type = "override";
    content = v;
    priority = 50;
  };

  testLibs = {
    inherit
      mkTest
      mkThrows
      mkDefaultStub
      mkEnableOptionStub
      mkForceStub
      isTest
      runTests
      ;
    inherit tryEval;
  };
in
  testLibs
  // {
    _rootAliases = testLibs;
  }
