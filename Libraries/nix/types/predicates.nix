{_, ...}: let
  __exports = {
    internal =
      {}
      // attrsets
      // lists
      // debug
      // filesystem
      // strings
      // trivial
      // {};
    external = trivial;
  };

  attrsets = with _.attrsets.predicates; {
    isAllEnabledAttrs = allEnabled;
    isAnyEnabledAttrs = anyEnabled;
    isTypedAttrs = isTyped;
    isWaylandEnabledAttrs = waylandEnabled;
  };

  lists = with _.lists.predicates; {
    inherit isEnum;
  };

  debug = with _.debug.predicates; {
    inherit isTest;
  };

  filesystem = with _.filesystem.predicates; {
    isPathLike = isLike;
    isPath' = isPath;
    isStorePath' = isStorePath;
    inherit
      isExcludedFile
      isFlakePath
      isInExcludedFolder
      isNixFile
      pathExists
      isPathlike
      ;
  };

  strings = with _.strings.predicates; {
    isBinaryString = isBinary;
    isStringLike = isLike;
    isStringConvertible = isConvertible;
    isPOSIXString = isPOSIX;
  };

  inherit (_.types.access) typeOf;

  trivial = {
    inherit isBool isFloat isFunction isInt typeOf;
  };

  /**
  Return the Nix type of a value as a string.

  Delegates to `_.types.access.typeOf`.

  # Type
  ```nix
  typeOf :: any -> string
  ```

  # Examples
  ```nix
  typeOf "hello"      # => "string"
  typeOf 42           # => "int"
  typeOf true         # => "bool"
  typeOf []           # => "list"
  typeOf { a = 1; }  # => "set"
  typeOf null         # => "null"
  ```
  */

  /**
  Check whether a value is a boolean.

  # Type
  ```nix
  isBool :: any -> bool
  ```

  # Examples
  ```nix
  isBool true   # => true
  isBool false  # => true
  isBool 1      # => false
  ```
  */
  isBool = input: typeOf input == "bool";

  /**
  Check whether a value is a floating point number.

  # Type
  ```nix
  isFloat :: any -> bool
  ```

  # Examples
  ```nix
  isFloat 1.5  # => true
  isFloat 1    # => false
  ```
  */
  isFloat = input: typeOf input == "float";

  /**
  Check whether a value is a function.

  # Type
  ```nix
  isFunction :: any -> bool
  ```

  # Examples
  ```nix
  isFunction (x: x)   # => true
  isFunction "hello"  # => false
  ```
  */
  isFunction = input: typeOf input == "lambda";

  /**
  Check whether a value is an integer.

  # Type
  ```nix
  isInt :: any -> bool
  ```

  # Examples
  ```nix
  isInt 1    # => true
  isInt 1.0  # => false
  isInt "1"  # => false
  ```
  */
  isInt = input: typeOf input == "int";
in
  __exports.internal // {__rootAliases = __exports.external;}
