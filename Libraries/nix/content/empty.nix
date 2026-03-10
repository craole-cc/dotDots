{
  _,
  lib,
  ...
}: let
  inherit (_.debug.assertions) mkTest;
  inherit (_.debug.runners) runTests;
  inherit (lib.lists) isList;
  inherit (lib.attrsets) isAttrs;
  inherit (lib.strings) isString trim stringLength;

  /**
  Check if a value is considered "empty" for defaulting purposes.

  # Emptiness Rules
  - `null`:             always empty
  - Strings:            empty when `""` or whitespace-only
  - Lists:              empty when `[]`
  - Attrsets:           empty when `{}`
  - Numbers, booleans, paths, functions: **never** empty

  # Type
  ```nix
  isEmpty :: a -> Bool
  ```

  # Examples
  ```nix
  isEmpty null        # => true
  isEmpty ""          # => true
  isEmpty "  "        # => true
  isEmpty []          # => true
  isEmpty {}          # => true
  isEmpty 0           # => false
  isEmpty false       # => false
  isEmpty "hello"     # => false
  isEmpty [1 2 3]     # => false
  ```
  */
  isEmpty = value:
    if isNull value
    then true
    else if isString value
    then stringLength (trim value) == 0
    else if isList value
    then value == []
    else if isAttrs value
    then value == {}
    else false;

  /**
  Check if a value is not empty. Convenience negation of `isEmpty`.

  # Type
  ```nix
  isNotEmpty :: a -> Bool
  ```

  # Examples
  ```nix
  isNotEmpty "hello"  # => true
  isNotEmpty 0        # => true
  isNotEmpty false    # => true
  isNotEmpty null     # => false
  isNotEmpty ""       # => false

  # Common use in filters
  validItems = filter isNotEmpty rawList;
  ```
  */
  isNotEmpty = value: !isEmpty value;

  exports = {inherit isEmpty isNotEmpty;};
in
  exports
  // {
    _rootAliases = exports;

    _tests = runTests {
      isEmpty = {
        nullIsEmpty = mkTest {
          desired = true;
          command = "isEmpty null";
          outcome = isEmpty null;
        };
        emptyStringIsEmpty = mkTest {
          desired = true;
          command = ''isEmpty ""'';
          outcome = isEmpty "";
        };
        whitespaceIsEmpty = mkTest {
          desired = true;
          command = ''isEmpty "   "'';
          outcome = isEmpty "   ";
        };
        tabsAndNewlinesAreEmpty = mkTest {
          desired = true;
          command = ''isEmpty "\t\n"'';
          outcome = isEmpty "\t\n";
        };
        emptyListIsEmpty = mkTest {
          desired = true;
          command = "isEmpty []";
          outcome = isEmpty [];
        };
        emptyAttrsIsEmpty = mkTest {
          desired = true;
          command = "isEmpty {}";
          outcome = isEmpty {};
        };
        zeroIsNotEmpty = mkTest {
          desired = false;
          command = "isEmpty 0";
          outcome = isEmpty 0;
        };
        falseIsNotEmpty = mkTest {
          desired = false;
          command = "isEmpty false";
          outcome = isEmpty false;
        };
        trueIsNotEmpty = mkTest {
          desired = false;
          command = "isEmpty true";
          outcome = isEmpty true;
        };
        nonEmptyStringIsNotEmpty = mkTest {
          desired = false;
          command = ''isEmpty "hello"'';
          outcome = isEmpty "hello";
        };
        stringWithContentAndSpaceIsNotEmpty = mkTest {
          desired = false;
          command = ''isEmpty "  x  "'';
          outcome = isEmpty "  x  ";
        };
        nonEmptyListIsNotEmpty = mkTest {
          desired = false;
          command = "isEmpty [1 2 3]";
          outcome = isEmpty [1 2 3];
        };
        nonEmptyAttrsIsNotEmpty = mkTest {
          desired = false;
          command = ''isEmpty { a = 1; }'';
          outcome = isEmpty {a = 1;};
        };
        functionIsNotEmpty = mkTest {
          desired = false;
          command = "isEmpty (x: x)";
          outcome = isEmpty (x: x);
        };
      };

      isNotEmpty = {
        stringIsNotEmpty = mkTest {
          desired = true;
          command = ''isNotEmpty "hello"'';
          outcome = isNotEmpty "hello";
        };
        zeroIsNotEmpty = mkTest {
          desired = true;
          command = "isNotEmpty 0";
          outcome = isNotEmpty 0;
        };
        falseIsNotEmpty = mkTest {
          desired = true;
          command = "isNotEmpty false";
          outcome = isNotEmpty false;
        };
        nullIsEmpty = mkTest {
          desired = false;
          command = "isNotEmpty null";
          outcome = isNotEmpty null;
        };
        emptyStringIsEmpty = mkTest {
          desired = false;
          command = ''isNotEmpty ""'';
          outcome = isNotEmpty "";
        };
        whitespaceIsEmpty = mkTest {
          desired = false;
          command = ''isNotEmpty "  "'';
          outcome = isNotEmpty "  ";
        };
        emptyListIsEmpty = mkTest {
          desired = false;
          command = "isNotEmpty []";
          outcome = isNotEmpty [];
        };
        emptyAttrsIsEmpty = mkTest {
          desired = false;
          command = "isNotEmpty {}";
          outcome = isNotEmpty {};
        };
      };
    };
  }
