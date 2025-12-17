{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs isAttrs;
  inherit (lib) deepSeq;
  inherit (builtins) tryEval;
  inherit (_.types.predicates) isTest;

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
        else if isAttrs test
        then runTests test
        else test
    )
    tests;

  # Backwards‑compatible mkTest:
  # - mkTest expected expr
  # - mkTest { expected = ...; expr = ...; }
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

  exports = {
    inherit
      mkTest
      mkThrows
      mkDefaultStub
      mkEnableOptionStub
      mkForceStub
      runTests
      ;
    inherit tryEval;
  };
in
  exports
  // {
    _rootAliases = exports;
  }
