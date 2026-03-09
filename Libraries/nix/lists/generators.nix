{
  lib,
  _,
  library,
  __moduleNamespacePath,
  ...
}: let
  inherit (_.lists.predicates) isIn isInExact;
  inherit (_.trivial.debug) mkModuleDebug mkExample;
  inherit (_.trivial.predicates) isAttrs isFunction isList;
  inherit (_.trivial.tests) mkTest runTests;
  inherit (lib.attrsets) attrNames hasAttr;
  inherit (lib.lists) all any;
  inherit (lib.strings) hasPrefix stringLength;

  _debug = mkModuleDebug {
    inherit library;
    namespace = __moduleNamespacePath;
  };

  /**
  Create a validator that checks if values are in an allowed list.

  # Type
  ```nix
  mkValidator :: { list :: [a], exact :: Bool? } -> { check :: a -> Bool, list :: [a] }
  ```

  # Arguments
  - list:  List of allowed values
  - exact: Whether to use case-sensitive matching (default: false)

  # Examples
  ```nix
  validator = mkValidator { list = ["foo" "bar"]; };
  validator.check "FOO"  # => true (case-insensitive by default)
  validator.check "baz"  # => false

  exactValidator = mkValidator { list = ["foo" "bar"]; exact = true; };
  exactValidator.check "FOO"  # => false
  ```
  */
  mkValidator = {
    list,
    exact ? false,
  }:
    if !isList list
    then
      throw (_debug.withDoc {
        function = "mkValidator";
        message = "list must be a list of values";
        signature = "{ list :: [a], exact :: Bool? } -> { check :: a -> Bool, list :: [a] }";
        input = list;
        example = mkExample {
          cmd = ''mkValidator { list = ["foo" "bar"]; }'';
          res = "{ check = ...; list = [\"foo\" \"bar\"]; }";
        };
      })
    else {
      check = name:
        if exact
        then isInExact name list
        else isIn name list;
      inherit list;
    };

  /**
  Create a case-insensitive validator. Convenience wrapper for mkValidator with exact = false.

  # Type
  ```nix
  mkCaseInsensitiveValidator :: [a] -> { check :: a -> Bool, list :: [a] }
  ```

  # Examples
  ```nix
  validator = mkCaseInsensitiveValidator ["foo" "bar"];
  validator.check "FOO"  # => true
  validator.check "baz"  # => false
  ```
  */
  mkCaseInsensitiveValidator = list:
    mkValidator {
      inherit list;
      exact = false;
    };

  /**
  Create a case-sensitive validator. Convenience wrapper for mkValidator with exact = true.

  # Type
  ```nix
  mkCaseSensitiveValidator :: [a] -> { check :: a -> Bool, list :: [a] }
  ```

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

  # Examples
  ```nix
  validator = mkDenyValidator { list = ["admin" "root"]; };
  validator.check "user"   # => true
  validator.check "ADMIN"  # => false (case-insensitive by default)
  ```
  */
  mkDenyValidator = {
    list,
    exact ? false,
  }:
    if !isList list
    then
      throw (_debug.withDoc {
        function = "mkDenyValidator";
        message = "list must be a list of values";
        signature = "{ list :: [a], exact :: Bool? } -> { check :: a -> Bool, list :: [a] }";
        input = list;
        example = mkExample {
          cmd = ''mkDenyValidator { list = ["admin" "root"]; }'';
          res = "{ check = ...; list = [\"admin\" \"root\"]; }";
        };
      })
    else {
      check = name:
        if exact
        then !(isInExact name list)
        else !(isIn name list);
      inherit list;
    };

  /**
  Create a validator using a custom predicate function.

  # Type
  ```nix
  mkPredicateValidator :: (a -> Bool) -> { check :: a -> Bool, predicate :: (a -> Bool) }
  ```

  # Examples
  ```nix
  validator = mkPredicateValidator (hasPrefix "user_");
  validator.check "user_alice"  # => true
  validator.check "admin_bob"   # => false
  ```
  */
  mkPredicateValidator = predicate:
    if !isFunction predicate
    then
      throw (_debug.withDoc {
        function = "mkPredicateValidator";
        message = "predicate must be a function";
        signature = "(a -> Bool) -> { check :: a -> Bool, predicate :: (a -> Bool) }";
        input = predicate;
        example = mkExample {
          cmd = ''mkPredicateValidator (hasPrefix "user_")'';
          res = "{ check = ...; predicate = ...; }";
        };
      })
    else {
      check = name: predicate name;
      inherit predicate;
    };

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
      throw (_debug.withDoc {
        function = "combineValidators";
        message = "validators must be a list of validator objects";
        signature = "[Validator] -> { check :: a -> Bool, validators :: [Validator] }";
        input = validators;
        example = mkExample {
          cmd = "combineValidators [v1 v2]";
          res = "{ check = ...; validators = [...]; }";
        };
      })
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
      throw (_debug.withDoc {
        function = "combineValidatorsOr";
        message = "validators must be a list of validator objects";
        signature = "[Validator] -> { check :: a -> Bool, validators :: [Validator] }";
        input = validators;
        example = mkExample {
          cmd = "combineValidatorsOr [v1 v2]";
          res = "{ check = ...; validators = [...]; }";
        };
      })
    else {
      check = name: any (v: v.check name) validators;
      inherit validators;
    };

  /**
  Create an enum with optional aliases.

  # Type
  ```nix
  mkEnum :: [a] | { values :: [a], aliases :: AttrSet } -> Enum
  ```

  # Examples
  ```nix
  # Simple enum
  colors = mkEnum ["red" "green" "blue"];
  colors.validator.check "RED"  # => true

  # Enum with aliases
  roles = mkEnum {
    values  = ["administrator" "developer"];
    aliases = { admin = "administrator"; dev = "developer"; };
  };
  roles.allValues             # => ["administrator" "developer" "admin" "dev"]
  roles.validator.check "admin"  # => true
  roles.resolve "admin"          # => "administrator"
  ```
  */
  mkEnum = input:
    if !(isList input || isAttrs input)
    then
      throw (_debug.withDoc {
        function = "mkEnum";
        message = "input must be a list of values or an attrset with values and aliases";
        signature = "[a] | { values :: [a], aliases :: AttrSet } -> Enum";
        input = input;
        example = mkExample {
          cmd = ''mkEnum { values = ["admin" "user"]; aliases = { root = "admin"; }; }'';
          res = "{ values = [...]; aliases = {...}; allValues = [...]; validator = ...; resolve = ...; }";
        };
      })
    else let
      normalized =
        if isList input
        then {
          values = input;
          aliases = {};
        }
        else input;
      values = normalized.values;
      aliases = normalized.aliases or {};
      aliasKeys = attrNames aliases;
      allValues = values ++ aliasKeys;
    in {
      inherit values aliases allValues;
      validator = mkCaseInsensitiveValidator allValues;
      resolve = value:
        if hasAttr value aliases
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
      caseInsensitiveByDefault = mkTest {
        desired = true;
        command = ''(mkValidator { list = ["foo" "bar"]; }).check "FOO"'';
        outcome = (mkValidator {list = ["foo" "bar"];}).check "FOO";
      };
      caseSensitiveWithExact = mkTest {
        desired = false;
        command = ''(mkValidator { list = ["foo" "bar"]; exact = true; }).check "FOO"'';
        outcome = (mkValidator {
          list = ["foo" "bar"];
          exact = true;
        }).check "FOO";
      };
      allowsValueInList = mkTest {
        desired = true;
        command = ''(mkValidator { list = ["foo" "bar"]; }).check "foo"'';
        outcome = (mkValidator {list = ["foo" "bar"];}).check "foo";
      };
      deniesValueNotInList = mkTest {
        desired = false;
        command = ''(mkValidator { list = ["foo" "bar"]; }).check "baz"'';
        outcome = (mkValidator {list = ["foo" "bar"];}).check "baz";
      };
      exportsListAttribute = mkTest {
        desired = ["foo" "bar"];
        command = ''(mkValidator { list = ["foo" "bar"]; }).list'';
        outcome = (mkValidator {list = ["foo" "bar"];}).list;
      };
    };

    mkCaseInsensitiveValidator = {
      allowsCaseVariations = mkTest {
        desired = true;
        command = ''(mkCaseInsensitiveValidator ["foo" "bar"]).check "FOO"'';
        outcome = (mkCaseInsensitiveValidator ["foo" "bar"]).check "FOO";
      };
      allowsMixedCase = mkTest {
        desired = true;
        command = ''(mkCaseInsensitiveValidator ["foo" "bar"]).check "FoO"'';
        outcome = (mkCaseInsensitiveValidator ["foo" "bar"]).check "FoO";
      };
      deniesValueNotInList = mkTest {
        desired = false;
        command = ''(mkCaseInsensitiveValidator ["foo" "bar"]).check "baz"'';
        outcome = (mkCaseInsensitiveValidator ["foo" "bar"]).check "baz";
      };
    };

    mkCaseSensitiveValidator = {
      deniesWrongCase = mkTest {
        desired = false;
        command = ''(mkCaseSensitiveValidator ["foo" "bar"]).check "FOO"'';
        outcome = (mkCaseSensitiveValidator ["foo" "bar"]).check "FOO";
      };
      allowsExactMatch = mkTest {
        desired = true;
        command = ''(mkCaseSensitiveValidator ["foo" "bar"]).check "foo"'';
        outcome = (mkCaseSensitiveValidator ["foo" "bar"]).check "foo";
      };
      deniesValueNotInList = mkTest {
        desired = false;
        command = ''(mkCaseSensitiveValidator ["foo" "bar"]).check "baz"'';
        outcome = (mkCaseSensitiveValidator ["foo" "bar"]).check "baz";
      };
    };

    mkDenyValidator = {
      allowsValueNotInDenylist = mkTest {
        desired = true;
        command = ''(mkDenyValidator { list = ["admin" "root"]; }).check "user"'';
        outcome = (mkDenyValidator {list = ["admin" "root"];}).check "user";
      };
      deniesValueInDenylist = mkTest {
        desired = false;
        command = ''(mkDenyValidator { list = ["admin" "root"]; }).check "admin"'';
        outcome = (mkDenyValidator {list = ["admin" "root"];}).check "admin";
      };
      caseInsensitiveByDefault = mkTest {
        desired = false;
        command = ''(mkDenyValidator { list = ["admin" "root"]; }).check "ADMIN"'';
        outcome = (mkDenyValidator {list = ["admin" "root"];}).check "ADMIN";
      };
      caseSensitiveWithExact = mkTest {
        desired = true;
        command = ''(mkDenyValidator { list = ["admin" "root"]; exact = true; }).check "ADMIN"'';
        outcome = (mkDenyValidator {
          list = ["admin" "root"];
          exact = true;
        }).check "ADMIN";
      };
      exportsListAttribute = mkTest {
        desired = ["admin" "root"];
        command = ''(mkDenyValidator { list = ["admin" "root"]; }).list'';
        outcome = (mkDenyValidator {list = ["admin" "root"];}).list;
      };
    };

    mkPredicateValidator = {
      usesCustomPredicate = mkTest {
        desired = true;
        command = ''(mkPredicateValidator (hasPrefix "user_")).check "user_alice"'';
        outcome = (mkPredicateValidator (hasPrefix "user_")).check "user_alice";
      };
      failsWhenPredicateFails = mkTest {
        desired = false;
        command = ''(mkPredicateValidator (hasPrefix "user_")).check "admin_bob"'';
        outcome = (mkPredicateValidator (hasPrefix "user_")).check "admin_bob";
      };
      worksWithLengthCheck = mkTest {
        desired = true;
        command = ''(mkPredicateValidator (s: stringLength s >= 3)).check "abc"'';
        outcome = (mkPredicateValidator (s: stringLength s >= 3)).check "abc";
      };
    };

    combineValidators = {
      requiresAllValidatorsToPass = mkTest {
        desired = true;
        command = ''(combineValidators [allowlist prefix]).check "user_alice"'';
        outcome = let
          allowlist = mkValidator {list = ["user_alice" "user_bob"];};
          prefix = mkPredicateValidator (hasPrefix "user_");
        in
          (combineValidators [allowlist prefix]).check "user_alice";
      };
      failsIfAnyValidatorFails = mkTest {
        desired = false;
        command = ''(combineValidators [allowlist prefix]).check "user_charlie"'';
        outcome = let
          allowlist = mkValidator {list = ["user_alice" "user_bob"];};
          prefix = mkPredicateValidator (hasPrefix "user_");
        in
          (combineValidators [allowlist prefix]).check "user_charlie";
      };
      failsIfPrefixWrong = mkTest {
        desired = false;
        command = ''(combineValidators [allowlist prefix]).check "admin_alice"'';
        outcome = let
          allowlist = mkValidator {list = ["user_alice" "admin_alice"];};
          prefix = mkPredicateValidator (hasPrefix "user_");
        in
          (combineValidators [allowlist prefix]).check "admin_alice";
      };
    };

    combineValidatorsOr = {
      passesIfAnyValidatorPasses = mkTest {
        desired = true;
        command = ''(combineValidatorsOr [allowlist1 allowlist2]).check "alice"'';
        outcome = let
          allowlist1 = mkValidator {list = ["alice" "bob"];};
          allowlist2 = mkValidator {list = ["charlie" "dave"];};
        in
          (combineValidatorsOr [allowlist1 allowlist2]).check "alice";
      };
      passesWithSecondList = mkTest {
        desired = true;
        command = ''(combineValidatorsOr [allowlist1 allowlist2]).check "charlie"'';
        outcome = let
          allowlist1 = mkValidator {list = ["alice" "bob"];};
          allowlist2 = mkValidator {list = ["charlie" "dave"];};
        in
          (combineValidatorsOr [allowlist1 allowlist2]).check "charlie";
      };
      failsIfNoValidatorPasses = mkTest {
        desired = false;
        command = ''(combineValidatorsOr [allowlist1 allowlist2]).check "eve"'';
        outcome = let
          allowlist1 = mkValidator {list = ["alice" "bob"];};
          allowlist2 = mkValidator {list = ["charlie" "dave"];};
        in
          (combineValidatorsOr [allowlist1 allowlist2]).check "eve";
      };
    };

    mkEnum = {
      simpleEnumCheck = mkTest {
        desired = true;
        command = ''(mkEnum ["red" "green" "blue"]).validator.check "RED"'';
        outcome = (mkEnum ["red" "green" "blue"]).validator.check "RED";
      };
      aliasCheck = mkTest {
        desired = true;
        command = ''(mkEnum { values = ["administrator"]; aliases = { admin = "administrator"; }; }).validator.check "admin"'';
        outcome = (mkEnum {
          values = ["administrator"];
          aliases = {admin = "administrator";};
        }).validator.check "admin";
      };
      resolveAlias = mkTest {
        desired = "administrator";
        command = ''(mkEnum { values = ["administrator"]; aliases = { admin = "administrator"; }; }).resolve "admin"'';
        outcome = (mkEnum {
          values = ["administrator"];
          aliases = {admin = "administrator";};
        }).resolve "admin";
      };
      resolveCanonical = mkTest {
        desired = "administrator";
        command = ''(mkEnum { values = ["administrator"]; aliases = { admin = "administrator"; }; }).resolve "administrator"'';
        outcome = (mkEnum {
          values = ["administrator"];
          aliases = {admin = "administrator";};
        }).resolve "administrator";
      };
    };
  };
}
