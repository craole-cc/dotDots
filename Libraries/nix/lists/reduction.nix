{
  __moduleRef,
  _,
  ...
}: let
  __exports = {
    internal = {inherit combineValidators combineValidatorsOr;};
    external = {
      combineValidatorsLists = combineValidators;
      combineValidatorsListsOr = combineValidatorsOr;
    };
  };

  inherit (_.lists.construction) mkPredicateValidator mkValidator;
  inherit (_.lists.predicates) all any;
  inherit (_.lists.strings) hasPrefix;
  inherit (_.trivial.debug) mkModuleDebug mkExample;
  inherit (_.trivial.tests) mkTest runTests;
  inherit (_.types.predicates) isList;

  _debug = mkModuleDebug __moduleRef;

  /**
  Combine multiple validators with AND logic. Returns true only if ALL validators pass.

  # Type
  ```nix
  combineValidators :: [Validator] -> { check :: a -> Bool, validators :: [Validator] }
  ```

  # Examples
  ```nix
  combined = combineValidators [
    (mkValidator { list = ["user_alice" "user_bob"]; })
    (mkPredicateValidator (hasPrefix "user_"))
  ];
  combined.check "user_alice"    # => true
  combined.check "user_charlie"  # => false
  ```
  */
  combineValidators = validators:
    if !isList validators
    then
      throw (
        _debug.withDoc {
          function = "combineValidators";
          message = "validators must be a list of validator objects";
          signature = "[Validator] -> { check :: a -> Bool, validators :: [Validator] }";
          input = validators;
          example = mkExample {
            cmd = "combineValidators [v1 v2]";
            res = "{ check = ...; validators = [...]; }";
          };
        }
      )
    else {
      check = name: all (v: v.check name) validators;
      inherit validators;
    };

  /**
  Combine multiple validators with OR logic. Returns true if ANY validator passes.

  # Type
  ```nix
  combineValidatorsOr :: [Validator] -> { check :: a -> Bool, validators :: [Validator] }
  ```

  # Examples
  ```nix
  combined = combineValidatorsOr [
    (mkValidator { list = ["alice" "bob"]; })
    (mkValidator { list = ["charlie" "dave"]; })
  ];
  combined.check "alice"    # => true
  combined.check "charlie"  # => true
  combined.check "eve"      # => false
  ```
  */
  combineValidatorsOr = validators:
    if !isList validators
    then
      throw (
        _debug.withDoc {
          function = "combineValidatorsOr";
          message = "validators must be a list of validator objects";
          signature = "[Validator] -> { check :: a -> Bool, validators :: [Validator] }";
          input = validators;
          example = mkExample {
            cmd = "combineValidatorsOr [v1 v2]";
            res = "{ check = ...; validators = [...]; }";
          };
        }
      )
    else {
      check = name: any (v: v.check name) validators;
      inherit validators;
    };
in
  __exports.internal
  // {
    __rootAliases = __exports.external;

    __tests = runTests {
      combineValidators = {
        requiresAllToPass = mkTest {
          desired = true;
          command = ''(combineValidators [allowlist prefix]).check "user_alice"'';
          outcome = let
            allowlist = mkValidator {
              list = [
                "user_alice"
                "user_bob"
              ];
            };
            prefix = mkPredicateValidator (hasPrefix "user_");
          in
            (combineValidators [
              allowlist
              prefix
            ]).check
            "user_alice";
        };
        failsIfAnyFails = mkTest {
          desired = false;
          command = ''(combineValidators [allowlist prefix]).check "user_charlie"'';
          outcome = let
            allowlist = mkValidator {
              list = [
                "user_alice"
                "user_bob"
              ];
            };
            prefix = mkPredicateValidator (hasPrefix "user_");
          in
            (combineValidators [
              allowlist
              prefix
            ]).check
            "user_charlie";
        };
      };

      combineValidatorsOr = {
        passesIfAnyPasses = mkTest {
          desired = true;
          command = ''(combineValidatorsOr [list1 list2]).check "alice"'';
          outcome = let
            list1 = mkValidator {
              list = [
                "alice"
                "bob"
              ];
            };
            list2 = mkValidator {
              list = [
                "charlie"
                "dave"
              ];
            };
          in
            (combineValidatorsOr [
              list1
              list2
            ]).check
            "alice";
        };
        passesWithSecondList = mkTest {
          desired = true;
          command = ''(combineValidatorsOr [list1 list2]).check "charlie"'';
          outcome = let
            list1 = mkValidator {
              list = [
                "alice"
                "bob"
              ];
            };
            list2 = mkValidator {
              list = [
                "charlie"
                "dave"
              ];
            };
          in
            (combineValidatorsOr [
              list1
              list2
            ]).check
            "charlie";
        };
        failsIfNonePasses = mkTest {
          desired = false;
          command = ''(combineValidatorsOr [list1 list2]).check "eve"'';
          outcome = let
            list1 = mkValidator {
              list = [
                "alice"
                "bob"
              ];
            };
            list2 = mkValidator {
              list = [
                "charlie"
                "dave"
              ];
            };
          in
            (combineValidatorsOr [
              list1
              list2
            ]).check
            "eve";
        };
      };
    };
  }
