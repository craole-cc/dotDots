{_, ...}: let
  __exports = {
    internal =
      {}
      // attrsets
      // lists
      // debug
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

  strings = with _.strings.predicates; {
    isBinaryString = isBinary;
    isStringLike = isLike;
    isStringConvertible = isConvertible;
    isPOSIXString = isPOSIX;
  };

  debug = with _.debug.predicates; {
    inherit isTest;
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

  std = _.types.predicates;

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
  typeOf = input: std.typeOf input;

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
  isBool = input: std.isBool input;

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
  isFloat = input: std.isFloat input;

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
  isFunction = input: std.isFunction input;

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
  isInt = input: std.isInt input;
in
  __exports.internal // {_rootAliases = __exports.external;}
