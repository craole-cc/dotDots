{lib, ...}: let
  /**
  Check whether a value is an attribute set.

  # Type
  ```nix
  isAttrs :: any -> bool
  ```

  # Examples
  ```nix
  isAttrs { foo = "bar"; }  # => true
  isAttrs "foo"             # => false
  isAttrs []                # => false
  ```
  */
  isAttrs = lib.attrsets.isAttrs;

  /**
  Check whether a string is a binary digit — exactly `"0"` or `"1"`.

  # Type
  ```nix
  isBinaryString :: any -> bool
  ```

  # Examples
  ```nix
  isBinaryString "0"    # => true
  isBinaryString "1"    # => true
  isBinaryString "yes"  # => false
  isBinaryString 1      # => false
  ```
  */
  isBinaryString = s:
    lib.strings.typeOf s == "string" && (s == "0" || s == "1");

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

  /**
  Check whether a value is a list.

  # Type
  ```nix
  isList :: any -> bool
  ```

  # Examples
  ```nix
  isList []         # => true
  isList ["a" "b"]  # => true
  isList "foo"      # => false
  ```
  */
  isList = lib.lists.isList;

  /**
  Check whether a value is a path.

  # Type
  ```nix
  isPath :: any -> bool
  ```

  # Examples
  ```nix
  isPath /etc/hosts  # => true
  isPath "/etc"      # => false (string, not path)
  ```
  */
  isPath = lib.strings.isPath;

  /**
  Check whether a string is a valid POSIX filename component.

  A valid POSIX name contains only alphanumerics, hyphens, underscores, and dots,
  and does not start with a hyphen.

  # Type
  ```nix
  isPOSIX :: string -> bool
  ```

  # Examples
  ```nix
  isPOSIX "foo-bar"   # => true
  isPOSIX "foo bar"   # => false (space not allowed)
  isPOSIX "-foo"      # => false (cannot start with hyphen)
  ```
  */
  isPOSIX = lib.strings.isValidPosixName;

  /**
  Check whether a value is a valid Nix store path.

  # Type
  ```nix
  isStorePath :: any -> bool
  ```

  # Examples
  ```nix
  isStorePath "/nix/store/abc123-foo"  # => true
  isStorePath "/etc/hosts"             # => false
  isStorePath "foo"                    # => false
  ```
  */
  isStorePath = lib.strings.isStorePath;

  /**
  Check whether a value is a string.

  # Type
  ```nix
  isString :: any -> bool
  ```

  # Examples
  ```nix
  isString "foo"  # => true
  isString 42     # => false
  isString null   # => false
  ```
  */
  isString = lib.strings.isString;

  /**
  Check whether a value can be converted to a string via `toString`.

  Includes strings, paths, numbers, booleans, and attrsets with a `__toString`
  or `outPath` attribute.

  # Type
  ```nix
  isStringConvertible :: any -> bool
  ```

  # Examples
  ```nix
  isStringConvertible "foo"         # => true
  isStringConvertible 42            # => true
  isStringConvertible /etc/hosts    # => true
  isStringConvertible { a = 1; }    # => false
  ```
  */
  isStringConvertible = lib.strings.isConvertibleWithToString;

  /**
  Check whether a value is string-like — a string or a value with `outPath`.

  Useful for accepting both strings and derivations/packages wherever a path
  or string is expected.

  # Type
  ```nix
  isStringLike :: any -> bool
  ```

  # Examples
  ```nix
  isStringLike "foo"                 # => true
  isStringLike { outPath = "..."; }  # => true
  isStringLike 42                    # => false
  ```
  */
  isStringLike = lib.strings.isStringLike;

  /**
  Check whether a value is a "special" typed attrset — one with a `_type` attribute.

  Used internally to detect tagged union values produced by `lib.types`.

  # Type
  ```nix
  isSpecial :: any -> bool
  ```

  # Examples
  ```nix
  isSpecial { _type = "option"; }  # => true
  isSpecial { foo = "bar"; }       # => false
  isSpecial "foo"                  # => false
  ```
  */
  isSpecial = v: lib.attrsets.isAttrs v && (v._type or null) != null;

  /**
  Check whether a value is a test result record produced by `mkTest`.

  A test record has `expected`, `result`, and `passed` fields.

  # Type
  ```nix
  isTest :: any -> bool
  ```

  # Examples
  ```nix
  isTest { expected = 1; result = 1; passed = true; }  # => true
  isTest { expected = 1; result = 2; passed = false; }  # => true
  isTest { foo = "bar"; }                               # => false
  ```
  */
  isTest = test:
    lib.attrsets.isAttrs test
    && test ? expected
    && test ? result
    && test ? passed;

  /**
  Return the Nix type of a value as a string.

  Delegates to `builtins.typeOf` via `lib.strings.typeOf`.

  # Type
  ```nix
  typeOf :: any -> string
  ```

  # Examples
  ```nix
  typeOf "hello"       # => "string"
  typeOf 42            # => "int"
  typeOf true          # => "bool"
  typeOf []            # => "list"
  typeOf { a = 1; }   # => "set"
  typeOf null          # => "null"
  ```
  */
  typeOf = lib.strings.typeOf;

  exports = {
    inherit
      isAttrs
      isBinaryString
      isBool
      isFloat
      isFunction
      isInt
      isList
      isPath
      isPOSIX
      isSpecial
      isStorePath
      isString
      isStringConvertible
      isStringLike
      isTest
      typeOf
      ;
  };
in
  exports // {_rootAliases = exports;}
