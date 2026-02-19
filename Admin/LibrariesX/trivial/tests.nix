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
            then "Test `${name}` failed"
            else null;
        in {
          inherit (test) desired result passed;
          inherit error;
        }
        else if isAttrs test
        then runTests test
        else test
    )
    tests;

  mkTest = {
    desired,
    outcome,
  }: let
    value = deepSeq outcome outcome;
    passed = desired == value;
  in {
    inherit desired;
    result = value;
    inherit passed;
  };

  mkThrows = outcome:
    mkTest {
      desired = {
        success = false;
        value = false;
      };
      outcome = tryEval outcome;
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
