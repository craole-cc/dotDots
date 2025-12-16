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

  # Single-argument mkTest: always takes { expected; expr; }
  mkTest = {
    expected,
    expr,
  }: let
    value = deepSeq expr expr;
    passed = expected == value;
  in {
    inherit expected;
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
