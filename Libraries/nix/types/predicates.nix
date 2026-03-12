{
  _,
  lib,
  ...
}: let
  /**
  Return the Nix type of a value as a string.

  Delegates to `builtins.typeOf`.

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
  typeOf = builtins.typeOf;

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
  isBool = lib.trivial.isBool;

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
  isFloat = lib.trivial.isFloat;

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
  isFunction = lib.trivial.isFunction;

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
  isInt = lib.trivial.isInt;

  exports = {
    inherit
      isBool
      isFloat
      isFunction
      isInt
      typeOf
      ;
  };
in
  exports
  // {
    inherit
      (_)
      #~@ Strings
      isBinaryString
      isString
      isStringConvertible
      isStringLike
      isList
      #~@ Attrsets
      isAttrs
      isDerivation
      isTypedAttrs
      isAllEnabledAttrs
      isAnyEnabledAttrs
      isWaylandEnabledAttrs
      #~@ Filesystem
      isPath
      isPOSIXString
      isStorePath
      #~@ Debug
      isTest
      ;
    _rootAliases = exports;
  }
