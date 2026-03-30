{
  __moduleRef,
  _,
  ...
}: let
  __exports = {
    internal = {
      inherit
        toList'
        mkCheckList
        mkEnum
        mkValidator
        mkCaseInsensitiveValidator
        mkCaseSensitiveValidator
        mkDenyValidator
        mkPredicateValidator
        ;
    };
    external = {
      toList = toList';
      inherit
        mkCheckList
        mkEnum
        mkValidator
        mkCaseInsensitiveValidator
        mkCaseSensitiveValidator
        mkDenyValidator
        mkPredicateValidator
        ;
    };
  };

  inherit (_.lists.attrsets.resolution) attrNames hasAttr;
  inherit (_.lists.predicates) elem isIn isInExact;
  inherit (_.lists.filtering) filter;
  inherit (_.lists.strings) hasPrefix;
  inherit (_.lists.transformation) toLower;
  inherit (_.lists.construction) toList;
  inherit (_.lists.access) stringLength;
  inherit (_.trivial.debug) mkModuleDebug mkExample;
  inherit (_.trivial.tests) mkTest runTests;
  inherit (_.types.predicates) isAttrs isFunction isList;

  _debug = mkModuleDebug __moduleRef;

  /**
  Convert a single string, or list of strings, into a cleaned list.

  Removes null values but preserves empty strings.

  # Type
  ```nix
  toList' :: string | [string | null] | null -> [string]
  ```

  # Examples
  ```nix
  toList' "foo"               # => ["foo"]
  toList' ["foo" null "bar"]  # => ["foo" "bar"]
  toList' null                # => []
  ```
  */
  toList' = value:
    filter (v: v != null) (toList value);

  /**
  Generate a membership-checking predicate for a normalized list.

  When `exact = false` (default), both the check list and tested elements
  are lowercased before comparison.

  # Type
  ```nix
  mkCheckList :: { check :: a | [a], exact :: Bool } -> (a -> Bool)
  ```

  # Examples
  ```nix
  isMember = mkCheckList { check = ["foo" "bar"]; };
  isMember "foo"  # => true
  isMember "FOO"  # => true (case-insensitive by default)
  isMember "baz"  # => false

  isMemberExact = mkCheckList { check = ["foo" "bar"]; exact = true; };
  isMemberExact "FOO"  # => false
  ```
  */
  mkCheckList = {
    check,
    exact ? false,
  }: let
    checkList = toList' check;
    normalizedList =
      if exact
      then checkList
      else map toLower checkList;
  in
    if !isList checkList
    then
      throw (_debug.withDoc {
        function = "mkCheckList";
        message = "check must be a value or list of values";
        signature = "{ check :: a | [a], exact :: Bool } -> (a -> Bool)";
        input = check;
        example = mkExample {
          cmd = ''mkCheckList { check = ["foo" "bar"]; }'';
          res = "(a -> Bool)";
        };
      })
    else if exact
    then (e: e != null && elem e normalizedList)
    else (e: e != null && elem (toLower e) normalizedList);

  /**
  Create a validator that checks if values are in an allowed list.

  # Type
  ```nix
  mkValidator :: { list :: [a], exact :: Bool? } -> { check :: a -> Bool, list :: [a] }
  ```

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
  roles.allValues                # => ["administrator" "developer" "admin" "dev"]
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
        then {values = input;}
        else if input ? values
        then
          input
          // {
            values =
              if isList input.values
              then input.values
              else attrNames input.values;
          }
        else {values = attrNames input;};

      values = normalized.values;
      aliases = normalized.aliases or {};
      nullable = normalized.nullable or false;
      allValues = values ++ (attrNames aliases);
      allValuesNullable = allValues ++ [null];
    in {
      inherit
        values
        aliases
        nullable
        allValues
        allValuesNullable
        ;
      validator = mkCaseInsensitiveValidator allValues;
      validatorNullable = mkCaseInsensitiveValidator allValuesNullable;
      resolve = value:
        if value == null
        then null
        else if hasAttr value aliases
        then aliases.${value}
        else value;
    };
in
  __exports.internal
  // {
    _rootAliases = __exports.external;

    _tests = runTests {
      mkCheckList = {
        caseInsensitiveByDefault = mkTest {
          desired = true;
          command = ''(mkCheckList { check = ["foo" "bar"]; }) "FOO"'';
          outcome = (mkCheckList {check = ["foo" "bar"];}) "FOO";
        };
        caseSensitiveWithExact = mkTest {
          desired = false;
          command = ''(mkCheckList { check = ["foo" "bar"]; exact = true; }) "FOO"'';
          outcome = (mkCheckList {
            check = ["foo" "bar"];
            exact = true;
          }) "FOO";
        };
        matchesExactValue = mkTest {
          desired = true;
          command = ''(mkCheckList { check = ["foo" "bar"]; }) "foo"'';
          outcome = (mkCheckList {check = ["foo" "bar"];}) "foo";
        };
        rejectsAbsentValue = mkTest {
          desired = false;
          command = ''(mkCheckList { check = ["foo" "bar"]; }) "baz"'';
          outcome = (mkCheckList {check = ["foo" "bar"];}) "baz";
        };
        rejectsNull = mkTest {
          desired = false;
          command = ''(mkCheckList { check = ["foo"]; }) null'';
          outcome = (mkCheckList {check = ["foo"];}) null;
        };
        singleStringCheck = mkTest {
          desired = true;
          command = ''(mkCheckList { check = "foo"; }) "FOO"'';
          outcome = (mkCheckList {check = "foo";}) "FOO";
        };
      };

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
