{
  lib,
  _,
  ...
}: let
  inherit (lib.strings) hasPrefix;
  inherit (_.lists.predicates) isIn isInExact;
  inherit (_.testing.unit) mkTest runTests;

  /**
  Create a validator that checks if values are in an allowed list.

  # Type
  ```nix
  mkValidator :: { list :: [a], exact :: Bool? } -> { check :: a -> Bool, list :: [a] }
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
  validator = mkValidator { list = ["foo" "bar"]; };
  validator.check "foo"  # => true
  validator.check "FOO"  # => true (case-insensitive by default)
  validator.check "baz"  # => false

  exactValidator = mkValidator { list = ["foo" "bar"]; exact = true; };
  exactValidator.check "FOO"  # => false (case-sensitive)
  ```
  */
  mkValidator = {
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

  Convenience wrapper for mkValidator with exact = false.

  # Type
  ```nix
  mkCaseInsensitiveValidator :: [a] -> { check :: a -> Bool, list :: [a] }
  ```

  # Arguments
  - list: List of allowed values

  # Returns
  An attribute set with:
  - check: Function that validates a value (case-insensitive)
  - list: The allowed list

  # Examples
  ```nix
  validator = mkCaseInsensitiveValidator ["foo" "bar"];
  validator.check "FOO"  # => true
  validator.check "Foo"  # => true
  validator.check "baz"  # => false
  ```
  */
  mkCaseInsensitiveValidator = list:
    mkValidator {
      inherit list;
      exact = false;
    };

  /**
  Create a case-sensitive validator that checks if values are in an allowed list.

  Convenience wrapper for mkValidator with exact = true.

  # Type
  ```nix
  mkCaseSensitiveValidator :: [a] -> { check :: a -> Bool, list :: [a] }
  ```

  # Arguments
  - list: List of allowed values

  # Returns
  An attribute set with:
  - check: Function that validates a value (case-sensitive)
  - list: The allowed list

  # Examples
  ```nix
  validator = mkCaseSensitiveValidator ["foo" "bar"];
  validator.check "foo"  # => true
  validator.check "FOO"  # => false
  ```
  */
  mkCaseSensitiveValidator = list:
    mkValidator {
      inherit list;
      exact = true;
    };

  /**
  Create a validator that checks if values are NOT in a denylist.

  # Type
  ```nix
  mkDenyValidator :: { list :: [a], exact :: Bool? } -> { check :: a -> Bool, list :: [a] }
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
  validator = mkDenyValidator { list = ["admin" "root"]; };
  validator.check "user"   # => true
  validator.check "admin"  # => false
  validator.check "ADMIN"  # => false (case-insensitive by default)

  exactValidator = mkDenyValidator { list = ["admin" "root"]; exact = true; };
  exactValidator.check "ADMIN"  # => true (case-sensitive, so ADMIN != admin)
  ```
  */
  mkDenyValidator = {
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
  allowlist = mkValidator { list = ["user_alice" "user_bob"]; };
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
  allowlist1 = mkValidator { list = ["alice" "bob"]; };
  allowlist2 = mkValidator { list = ["charlie" "dave"]; };

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

  /**
    Create an enum with optional aliases.

    # Type
  ```nix
    mkEnum :: [a] | { values :: [a], aliases :: AttrSet } -> Enum
  ```

    # Arguments
    - values: Either a list of values, or an attrset with:
      - values: List of canonical values
      - aliases: Attrset mapping alias -> canonical value

    # Returns
    {
      values: List of canonical values
      aliases: Alias mapping (if provided)
      allValues: Combined list (values ++ alias keys)
      validator: Case-insensitive validator accepting any value or alias
    }

    # Examples
  ```nix
    # Simple enum
    colors = mkEnum ["red" "green" "blue"];
    colors.values      # => ["red" "green" "blue"]
    colors.validator.check "RED"  # => true

    # Enum with aliases
    roles = mkEnum {
      values = ["administrator" "developer" "user"];
      aliases = { admin = "administrator"; dev = "developer"; };
    };
    roles.values       # => ["administrator" "developer" "user"]
    roles.allValues    # => ["administrator" "developer" "user" "admin" "dev"]
    roles.aliases      # => { admin = "administrator"; dev = "developer"; }
    roles.validator.check "admin"  # => true (alias)
    roles.validator.check "developer"  # => true (canonical)
  ```
  */
  mkEnum = input: let
    # Normalize input to handle both list and attrset forms
    normalized =
      if builtins.isList input
      then {
        values = input;
        aliases = {};
      }
      else input;

    values = normalized.values;
    aliases = normalized.aliases or {};
    aliasKeys = builtins.attrNames aliases;
    allValues = values ++ aliasKeys;
  in {
    inherit values aliases allValues;
    validator = mkCaseInsensitiveValidator allValues;

    # Optional: Add a resolve function to get canonical value from alias
    resolve = value:
      if builtins.hasAttr value aliases
      then aliases.${value}
      else value;
  };
in {
  inherit
    mkEnum
    mkValidator
    mkCaseInsensitiveValidator
    mkCaseSensitiveValidator
    mkDenyValidator
    mkPredicateValidator
    combineValidators
    combineValidatorsOr
    ;

  _rootAliases = {
    inherit mkEnum;
    mkListValidator = mkValidator;
    mkCaseInsensitiveListValidator = mkCaseInsensitiveValidator;
    mkCaseSensitiveListValidator = mkCaseSensitiveValidator;
    mkDenyListValidator = mkDenyValidator;
    mkPredicateListValidator = mkPredicateValidator;
    combineListValidators = combineValidators;
    combineListValidatorsOr = combineValidatorsOr;
  };

  _tests = runTests {
    mkValidator = {
      caseInsensitiveByDefault = let
        validator = mkValidator {list = ["foo" "bar"];};
      in
        mkTest true (validator.check "FOO");

      caseSensitiveWithExact = let
        validator = mkValidator {
          list = ["foo" "bar"];
          exact = true;
        };
      in
        mkTest false (validator.check "FOO");

      allowsValueInList = let
        validator = mkValidator {list = ["foo" "bar"];};
      in
        mkTest true (validator.check "foo");

      deniesValueNotInList = let
        validator = mkValidator {list = ["foo" "bar"];};
      in
        mkTest false (validator.check "baz");

      exportsListAttribute = let
        validator = mkValidator {list = ["foo" "bar"];};
      in
        mkTest ["foo" "bar"] validator.list;
    };

    mkCaseInsensitiveValidator = {
      allowsCaseVariations = let
        validator = mkCaseInsensitiveValidator ["foo" "bar"];
      in
        mkTest true (validator.check "FOO");

      allowsLowerCase = let
        validator = mkCaseInsensitiveValidator ["foo" "bar"];
      in
        mkTest true (validator.check "foo");

      allowsMixedCase = let
        validator = mkCaseInsensitiveValidator ["foo" "bar"];
      in
        mkTest true (validator.check "FoO");

      deniesValueNotInList = let
        validator = mkCaseInsensitiveValidator ["foo" "bar"];
      in
        mkTest false (validator.check "baz");
    };

    mkCaseSensitiveValidator = {
      deniesWrongCase = let
        validator = mkCaseSensitiveValidator ["foo" "bar"];
      in
        mkTest false (validator.check "FOO");

      allowsExactMatch = let
        validator = mkCaseSensitiveValidator ["foo" "bar"];
      in
        mkTest true (validator.check "foo");

      deniesValueNotInList = let
        validator = mkCaseSensitiveValidator ["foo" "bar"];
      in
        mkTest false (validator.check "baz");
    };

    mkDenyValidator = {
      allowsValueNotInDenylist = let
        validator = mkDenyValidator {list = ["admin" "root"];};
      in
        mkTest true (validator.check "user");

      deniesValueInDenylist = let
        validator = mkDenyValidator {list = ["admin" "root"];};
      in
        mkTest false (validator.check "admin");

      caseInsensitiveByDefault = let
        validator = mkDenyValidator {list = ["admin" "root"];};
      in
        mkTest false (validator.check "ADMIN");

      caseSensitiveWithExact = let
        validator = mkDenyValidator {
          list = ["admin" "root"];
          exact = true;
        };
      in
        mkTest true (validator.check "ADMIN");

      exportsListAttribute = let
        validator = mkDenyValidator {list = ["admin" "root"];};
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
        allowlist = mkValidator {list = ["user_alice" "user_bob"];};
        prefix = mkPredicateValidator (hasPrefix "user_");
        combined = combineValidators [allowlist prefix];
      in
        mkTest true (combined.check "user_alice");

      failsIfAnyValidatorFails = let
        allowlist = mkValidator {list = ["user_alice" "user_bob"];};
        prefix = mkPredicateValidator (hasPrefix "user_");
        combined = combineValidators [allowlist prefix];
      in
        mkTest false (combined.check "user_charlie");

      failsIfPrefixWrong = let
        allowlist = mkValidator {list = ["user_alice" "admin_alice"];};
        prefix = mkPredicateValidator (hasPrefix "user_");
        combined = combineValidators [allowlist prefix];
      in
        mkTest false (combined.check "admin_alice");
    };

    combineValidatorsOr = {
      passesIfAnyValidatorPasses = let
        allowlist1 = mkValidator {list = ["alice" "bob"];};
        allowlist2 = mkValidator {list = ["charlie" "dave"];};
        combined = combineValidatorsOr [allowlist1 allowlist2];
      in
        mkTest true (combined.check "alice");

      passesWithSecondList = let
        allowlist1 = mkValidator {list = ["alice" "bob"];};
        allowlist2 = mkValidator {list = ["charlie" "dave"];};
        combined = combineValidatorsOr [allowlist1 allowlist2];
      in
        mkTest true (combined.check "charlie");

      failsIfNoValidatorPasses = let
        allowlist1 = mkValidator {list = ["alice" "bob"];};
        allowlist2 = mkValidator {list = ["charlie" "dave"];};
        combined = combineValidatorsOr [allowlist1 allowlist2];
      in
        mkTest false (combined.check "eve");
    };
  };
}
