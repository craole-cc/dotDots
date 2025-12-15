{
  lib,
  _,
  ...
}: let
  inherit (lib.strings) hasPrefix;
  inherit (_.lists.predicates) isIn isInExact;

  /**
  Create a validator that checks if values are in an allowed list.

  # Type
  ```nix
  mkListValidator :: { list :: [a], exact :: Bool? } -> { check :: a -> Bool, list :: [a] }
  ```

  # Arguments
  - list: List of allowed values
  - exact: Whether to use case-sensitive matching (default: false)

  # Returns
  An attribute set with:
  - check: Function that validates a value
  - list: The allowed list

  # Examples
  ```nix
  validator = mkListValidator { list = ["foo" "bar"]; };
  validator.check "foo"  # => true
  validator.check "FOO"  # => true (case-insensitive by default)
  validator.check "baz"  # => false

  exactValidator = mkListValidator { list = ["foo" "bar"]; exact = true; };
  exactValidator.check "FOO"  # => false (case-sensitive)
  ```
  */
  mkListValidator = {
    list,
    exact ? false,
  }: {
    check = name:
      if exact
      then isInExact name list
      else isIn name list;
    inherit list;
  };

  /**
  Create a case-insensitive validator that checks if values are in an allowed list.

  Convenience wrapper for mkListValidator with exact = false.

  # Type
  ```nix
  mkCaseInsensitiveListValidator :: [a] -> { check :: a -> Bool, list :: [a] }
  ```

  # Arguments
  - list: List of allowed values

  # Returns
  An attribute set with:
  - check: Function that validates a value (case-insensitive)
  - list: The allowed list

  # Examples
  ```nix
  validator = mkCaseInsensitiveListValidator ["foo" "bar"];
  validator.check "FOO"  # => true
  validator.check "Foo"  # => true
  validator.check "baz"  # => false
  ```
  */
  mkCaseInsensitiveListValidator = list:
    mkListValidator {
      inherit list;
      exact = false;
    };

  /**
  Create a case-sensitive validator that checks if values are in an allowed list.

  Convenience wrapper for mkListValidator with exact = true.

  # Type
  ```nix
  mkCaseSensitiveListValidator :: [a] -> { check :: a -> Bool, list :: [a] }
  ```

  # Arguments
  - list: List of allowed values

  # Returns
  An attribute set with:
  - check: Function that validates a value (case-sensitive)
  - list: The allowed list

  # Examples
  ```nix
  validator = mkCaseSensitiveListValidator ["foo" "bar"];
  validator.check "foo"  # => true
  validator.check "FOO"  # => false
  ```
  */
  mkCaseSensitiveListValidator = list:
    mkListValidator {
      inherit list;
      exact = true;
    };

  /**
  Create a validator that checks if values are NOT in a denylist.

  # Type
  ```nix
  mkDenylistValidator :: { list :: [a], exact :: Bool? } -> { check :: a -> Bool, list :: [a] }
  ```

  # Arguments
  - list: List of denied values
  - exact: Whether to use case-sensitive matching (default: false)

  # Returns
  An attribute set with:
  - check: Function that validates a value (returns true if NOT in denylist)
  - list: The denylist

  # Examples
  ```nix
  validator = mkDenylistValidator { list = ["admin" "root"]; };
  validator.check "user"   # => true
  validator.check "admin"  # => false
  validator.check "ADMIN"  # => false (case-insensitive by default)

  exactValidator = mkDenylistValidator { list = ["admin" "root"]; exact = true; };
  exactValidator.check "ADMIN"  # => true (case-sensitive, so ADMIN != admin)
  ```
  */
  mkDenylistValidator = {
    list,
    exact ? false,
  }: {
    check = name:
      if exact
      then !(isInExact name list)
      else !(isIn name list);
    inherit list;
  };

  /**
  Create a validator that uses a custom predicate function.

  # Type
  ```nix
  mkPredicateValidator :: (a -> Bool) -> { check :: a -> Bool, predicate :: (a -> Bool) }
  ```

  # Arguments
  - predicate: Function that takes a value and returns a boolean

  # Returns
  An attribute set with:
  - check: Function that validates a value using the predicate
  - predicate: The original predicate function

  # Examples
  ```nix
  validator = mkPredicateValidator (name: lib.strings.hasPrefix "user_" name);
  validator.check "user_alice"  # => true
  validator.check "admin_bob"   # => false

  lengthValidator = mkPredicateValidator (s: builtins.stringLength s >= 3);
  lengthValidator.check "ab"   # => false
  lengthValidator.check "abc"  # => true
  ```
  */
  mkPredicateValidator = predicate: {
    check = name: predicate name;
    inherit predicate;
  };

  /**
  Combine multiple validators with AND logic.

  Returns true only if ALL validators pass.

  # Type
  ```nix
  combineValidators :: [Validator] -> { check :: a -> Bool, validators :: [Validator] }
  ```

  # Arguments
  - validators: List of validator objects (must have a `check` function)

  # Returns
  An attribute set with:
  - check: Function that returns true if all validators pass
  - validators: The list of validators

  # Examples
  ```nix
  allowlist = mkListValidator { list = ["user_alice" "user_bob"]; };
  prefix = mkPredicateValidator (hasPrefix "user_");

  combined = combineValidators [allowlist prefix];
  combined.check "user_alice"  # => true
  combined.check "user_charlie"  # => false (not in allowlist)
  combined.check "admin_alice"  # => false (no user_ prefix)
  ```
  */
  combineValidators = validators: {
    check = name: builtins.all (v: v.check name) validators;
    inherit validators;
  };

  /**
  Combine multiple validators with OR logic.

  Returns true if ANY validator passes.

  # Type
  ```nix
  combineValidatorsOr :: [Validator] -> { check :: a -> Bool, validators :: [Validator] }
  ```

  # Arguments
  - validators: List of validator objects (must have a `check` function)

  # Returns
  An attribute set with:
  - check: Function that returns true if any validator passes
  - validators: The list of validators

  # Examples
  ```nix
  allowlist1 = mkListValidator { list = ["alice" "bob"]; };
  allowlist2 = mkListValidator { list = ["charlie" "dave"]; };

  combined = combineValidatorsOr [allowlist1 allowlist2];
  combined.check "alice"    # => true (in first list)
  combined.check "charlie"  # => true (in second list)
  combined.check "eve"      # => false (in neither)
  ```
  */
  combineValidatorsOr = validators: {
    check = name: builtins.any (v: v.check name) validators;
    inherit validators;
  };
in {
  inherit
    mkListValidator
    mkCaseInsensitiveListValidator
    mkCaseSensitiveListValidator
    mkDenylistValidator
    mkPredicateValidator
    combineValidators
    combineValidatorsOr
    ;

  _rootAliases = {
    inherit
      mkListValidator
      mkCaseInsensitiveListValidator
      mkCaseSensitiveListValidator
      mkDenylistValidator
      mkPredicateValidator
      combineValidators
      combineValidatorsOr
      ;
  };

  _tests = let
    inherit (_.testing.unit) mkTest runTests;
  in
    runTests {
      mkListValidator = {
        caseInsensitiveByDefault = let
          validator = mkListValidator {list = ["foo" "bar"];};
        in
          mkTest true (validator.check "FOO");

        caseSensitiveWithExact = let
          validator = mkListValidator {
            list = ["foo" "bar"];
            exact = true;
          };
        in
          mkTest false (validator.check "FOO");

        allowsValueInList = let
          validator = mkListValidator {list = ["foo" "bar"];};
        in
          mkTest true (validator.check "foo");

        deniesValueNotInList = let
          validator = mkListValidator {list = ["foo" "bar"];};
        in
          mkTest false (validator.check "baz");

        exportsListAttribute = let
          validator = mkListValidator {list = ["foo" "bar"];};
        in
          mkTest ["foo" "bar"] validator.list;
      };

      mkCaseInsensitiveListValidator = {
        allowsCaseVariations = let
          validator = mkCaseInsensitiveListValidator ["foo" "bar"];
        in
          mkTest true (validator.check "FOO");

        allowsLowerCase = let
          validator = mkCaseInsensitiveListValidator ["foo" "bar"];
        in
          mkTest true (validator.check "foo");

        allowsMixedCase = let
          validator = mkCaseInsensitiveListValidator ["foo" "bar"];
        in
          mkTest true (validator.check "FoO");

        deniesValueNotInList = let
          validator = mkCaseInsensitiveListValidator ["foo" "bar"];
        in
          mkTest false (validator.check "baz");
      };

      mkCaseSensitiveListValidator = {
        deniesWrongCase = let
          validator = mkCaseSensitiveListValidator ["foo" "bar"];
        in
          mkTest false (validator.check "FOO");

        allowsExactMatch = let
          validator = mkCaseSensitiveListValidator ["foo" "bar"];
        in
          mkTest true (validator.check "foo");

        deniesValueNotInList = let
          validator = mkCaseSensitiveListValidator ["foo" "bar"];
        in
          mkTest false (validator.check "baz");
      };

      mkDenylistValidator = {
        allowsValueNotInDenylist = let
          validator = mkDenylistValidator {list = ["admin" "root"];};
        in
          mkTest true (validator.check "user");

        deniesValueInDenylist = let
          validator = mkDenylistValidator {list = ["admin" "root"];};
        in
          mkTest false (validator.check "admin");

        caseInsensitiveByDefault = let
          validator = mkDenylistValidator {list = ["admin" "root"];};
        in
          mkTest false (validator.check "ADMIN");

        caseSensitiveWithExact = let
          validator = mkDenylistValidator {
            list = ["admin" "root"];
            exact = true;
          };
        in
          mkTest true (validator.check "ADMIN");

        exportsListAttribute = let
          validator = mkDenylistValidator {list = ["admin" "root"];};
        in
          mkTest ["admin" "root"] validator.list;
      };

      mkPredicateValidator = {
        usesCustomPredicate = let
          validator = mkPredicateValidator (name: hasPrefix "user_" name);
        in
          mkTest true (validator.check "user_alice");

        failsWhenPredicateFails = let
          validator = mkPredicateValidator (name: hasPrefix "user_" name);
        in
          mkTest false (validator.check "admin_bob");

        worksWithLengthCheck = let
          validator = mkPredicateValidator (s: builtins.stringLength s >= 3);
        in
          mkTest true (validator.check "abc");

        exportsPredicateAttribute = let
          pred = name: hasPrefix "user_" name;
          validator = mkPredicateValidator pred;
        in
          mkTest pred validator.predicate;
      };

      combineValidators = {
        requiresAllValidatorsToPass = let
          allowlist = mkListValidator {list = ["user_alice" "user_bob"];};
          prefix = mkPredicateValidator (hasPrefix "user_");
          combined = combineValidators [allowlist prefix];
        in
          mkTest true (combined.check "user_alice");

        failsIfAnyValidatorFails = let
          allowlist = mkListValidator {list = ["user_alice" "user_bob"];};
          prefix = mkPredicateValidator (hasPrefix "user_");
          combined = combineValidators [allowlist prefix];
        in
          mkTest false (combined.check "user_charlie");

        failsIfPrefixWrong = let
          allowlist = mkListValidator {list = ["user_alice" "admin_alice"];};
          prefix = mkPredicateValidator (hasPrefix "user_");
          combined = combineValidators [allowlist prefix];
        in
          mkTest false (combined.check "admin_alice");
      };

      combineValidatorsOr = {
        passesIfAnyValidatorPasses = let
          allowlist1 = mkListValidator {list = ["alice" "bob"];};
          allowlist2 = mkListValidator {list = ["charlie" "dave"];};
          combined = combineValidatorsOr [allowlist1 allowlist2];
        in
          mkTest true (combined.check "alice");

        passesWithSecondList = let
          allowlist1 = mkListValidator {list = ["alice" "bob"];};
          allowlist2 = mkListValidator {list = ["charlie" "dave"];};
          combined = combineValidatorsOr [allowlist1 allowlist2];
        in
          mkTest true (combined.check "charlie");

        failsIfNoValidatorPasses = let
          allowlist1 = mkListValidator {list = ["alice" "bob"];};
          allowlist2 = mkListValidator {list = ["charlie" "dave"];};
          combined = combineValidatorsOr [allowlist1 allowlist2];
        in
          mkTest false (combined.check "eve");
      };
    };
}
