{_, ...}: let
  __exports = {
    internal =
      {}
      // std
      // attrsets
      // strings
      // trivial
      // {};
    external = trivial;
  };

  std = _.std;

  attrsets = {
    inherit
      (_)
      isAllEnabledAttrs
      isAnyEnabledAttrs
      isWaylandEnabledAttrs
      isTypedAttrs
      ;
  };

  strings = {
    inherit
      (_)
      isStringLike
      isBinaryString
      isStringConvertible
      isPOSIXString
      ;
  };

  trivial = {
    inherit
      isBool
      isFloat
      isFunction
      isInt
      typeOf
      ;
  };

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
  typeOf = x: std.typeOf x;

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
  isBool = x: std.isBool x;

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
  isFloat = x: std.isFloat x;

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
  isFunction = x: std.isFunction x;

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
  isInt = x: std.isInt x;
in
  __exports.internal // {_rootAliases = __exports.external;}
# // {
#   inherit
#     (_)
#     #~@ Strings
#     isBinaryString
#     isString
#     isStringConvertible
#     isStringLike
#     isList
#     #~@ Attrsets
#     isAttrs
#     isDerivation
#     isTypedAttrs
#     isAllEnabledAttrs
#     isAnyEnabledAttrs
#     isWaylandEnabledAttrs
#     #~@ Filesystem
#     isPath
#     isPOSIXString
#     isStorePath
#     #~@ Debug
#     isTest
#     ;
#   # _rootAliases = exports;
# }
