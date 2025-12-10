{_, ...}: let
  inherit (_.lists.membership) isInList;
  /**
  Create a validator that checks if values are in an allowed list.

  # Type
  ```nix
  mkListValidator :: [a] -> Bool -> { check :: { name :: a, ignoreCase :: Bool? } -> Bool, list :: [a] }
  ```

  # Arguments
  - allowedList: List of allowed values
  - defaultIgnoreCase: Default case sensitivity setting

  # Returns
  An attribute set with:
  - check: Function that validates a name
  - list: The allowed list

  # Examples
  ```nix
  validator = mkListValidator ["foo" "bar"] false;
  validator.check { name = "foo"; }                    # => true
  validator.check { name = "FOO"; }                    # => false
  validator.check { name = "FOO"; ignoreCase = true; } # => true
  ```
  */
  mkListValidator = allowedList: defaultIgnoreCase: {
    check = {
      name,
      ignoreCase ? defaultIgnoreCase,
    }:
      isInList name allowedList ignoreCase;
    list = allowedList;
  };

  /**
  Create a case-insensitive validator that checks if values are in an allowed list.

  # Type
  ```nix
  mkCaseInsensitiveListValidator :: [a] -> { check :: { name :: a, ignoreCase :: Bool? } -> Bool, list :: [a] }
  ```

  # Arguments
  - allowedList: List of allowed values

  # Returns
  An attribute set with:
  - check: Function that validates a name (case-insensitive by default)
  - list: The allowed list

  # Examples
  ```nix
  validator = mkCaseInsensitiveListValidator ["foo" "bar"];
  validator.check { name = "FOO"; }  # => true
  validator.check { name = "Foo"; }  # => true
  ```
  */
  mkCaseInsensitiveListValidator = allowedList:
    mkListValidator allowedList true;

  /**
  Create a validator that checks if values are NOT in a denylist.

  # Type
  ```nix
  mkDenylistValidator :: [a] -> Bool -> { check :: { name :: a, ignoreCase :: Bool? } -> Bool, list :: [a] }
  ```

  # Arguments
  - denylist: List of denied values
  - defaultIgnoreCase: Default case sensitivity setting

  # Returns
  An attribute set with:
  - check: Function that validates a name (returns true if NOT in denylist)
  - list: The denylist

  # Examples
  ```nix
  validator = mkDenylistValidator ["admin" "root"] false;
  validator.check { name = "user"; }  # => true
  validator.check { name = "admin"; } # => false
  ```
  */
  mkDenylistValidator = denylist: defaultIgnoreCase: {
    check = {
      name,
      ignoreCase ? defaultIgnoreCase,
    }:
      !(isInList name denylist ignoreCase);
    list = denylist;
  };

  /**
  Create a validator that uses a custom predicate function.

  # Type
  ```nix
  mkPredicateValidator :: (a -> Bool) -> { check :: { name :: a, ... } -> Bool, predicate :: (a -> Bool) }
  ```

  # Arguments
  - predicate: Function that takes a name and returns a boolean

  # Returns
  An attribute set with:
  - check: Function that validates a name using the predicate
  - predicate: The original predicate function

  # Examples
  ```nix
  validator = mkPredicateValidator (name: lib.strings.hasPrefix "user_" name);
  validator.check { name = "user_alice"; }  # => true
  validator.check { name = "admin_bob"; }   # => false
  ```
  */
  mkPredicateValidator = predicate: {
    check = {name, ...}: predicate name;
    predicate = predicate;
  };
in {
  inherit
    mkListValidator
    mkCaseInsensitiveListValidator
    mkDenylistValidator
    mkPredicateValidator
    ;

  _rootAliases = {
    inherit
      mkListValidator
      mkCaseInsensitiveListValidator
      mkDenylistValidator
      mkPredicateValidator
      ;
  };
}
