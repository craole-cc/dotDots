{lib, ...}: let
  inherit (lib.strings) concatStringsSep toJSON;
  inherit (lib.debug) trace;

  #~@ Namespace Utilities

  /**
  Convert a namespace path list to a dotted string.

  # Type
  ```nix
  mkNamespace :: { namespacePath :: [string] } -> string
  ```

  # Examples
  ```nix
  mkNamespace { namespacePath = ["strings" "transform"]; }  # => "strings.transform"
  mkNamespace { namespacePath = ["trivial" "debug"]; }      # => "trivial.debug"
  ```
  */
  mkNamespace = {namespacePath}:
    concatStringsSep "." namespacePath;

  /**
  Create a fully qualified reference to a function.

  # Type
  ```nix
  mkRef :: { name :: string, namespacePath :: [string], fnName :: string } -> string
  ```

  # Examples
  ```nix
  mkRef { name = "lix"; namespacePath = ["strings" "transform"]; fnName = "normalize"; }
  # => "lix.strings.transform.normalize"
  ```
  */
  mkRef = {name, namespacePath, fnName}:
    "${name}.${mkNamespace { inherit namespacePath; }}.${fnName}";

  /**
  Create a usage hint string with type signature and :doc reference.

  # Type
  ```nix
  mkUsage :: { name :: string, namespacePath :: [string], fnName :: string, sign :: string } -> string
  ```

  # Examples
  ```nix
  mkUsage { name = "lix"; namespacePath = ["strings" "transform"]; fnName = "normalize"; sign = "string | [string] | null -> string | [string] | null"; }
  # => "string | [string] | null -> string | [string] | null
  #     repl> :doc lix.strings.transform.normalize"
  ```
  */
  mkUsage = {name, namespacePath, fnName, sign}:
    "${sign}\n repl> :doc ${mkRef { inherit name namespacePath fnName; }}";

  #~@ Module Debug

  /**
  Create a set of debug helpers bound to a module's namespace path.

  Provides consistent error formatting, tracing, and throwing helpers
  that automatically include the fully qualified function reference.

  # Type
  ```nix
  mkModuleDebug :: { name :: string, namespacePath :: [string] } -> ModuleDebug
  ```

  # Usage
  ```nix
  {_, name, __moduleNamespacePath, ...}: let
    debug = _.trivial.debug.mkModuleDebug { inherit name; namespacePath = __moduleNamespacePath; };
  in {
    myFn = value:
      if badCondition
      then throw (debug.traceLoc { fnName = "myFn"; msg = "bad input"; inherit value; })
      else ...;

    myOtherFn = value:
      if badCondition
      then throw (debug.traceDoc { fnName = "myOtherFn"; msg = "bad input"; sign = "string -> string"; inherit value; })
      else ...;
  }
  ```
  */
  mkModuleDebug = {name, namespacePath}: let
    ref = fnName: mkRef { inherit name namespacePath fnName; };
    usage = fnName: sign: mkUsage { inherit name namespacePath fnName sign; };
  in {
    /**
    Trace type signature and :doc reference to stderr, return error message for caller to throw.

    # Arguments
    - fnName: Name of the function where the error originates
    - msg: Human-readable error description
    - sign: Type signature string
    - value: The invalid value that caused the error (serialized via toJSON)
    */
    traceDoc = {fnName, msg, sign, value}:
      trace "${usage fnName sign}"
      "${msg}, got: ${toJSON value}";

    /**
    Trace just the qualified reference to stderr, return error message for caller to throw.

    # Arguments
    - fnName: Name of the function where the error originates
    - msg: Human-readable error description
    - value: The invalid value that caused the error (serialized via toJSON)
    */
    traceLoc = {fnName, msg, value}:
      trace "[${ref fnName}]"
      "${msg}, got: ${toJSON value}";

    /**
    Format an error string with fully qualified location, without throwing or tracing.

    # Arguments
    - fnName: Name of the function where the error originates
    - msg: Human-readable error description

    # Examples
    ```nix
    debug.mkError { fnName = "normalize"; msg = "unexpected null"; }
    # => "lix.strings.transform.normalize: unexpected null"
    ```
    */
    mkError = {fnName, msg}: "${ref fnName}: ${msg}";

    #> Expose ref and usage for manual composition
    inherit ref usage;
  };

  exports = {
    inherit
      mkNamespace
      mkRef
      mkUsage
      mkModuleDebug
      ;
  };
in
  exports // {_rootAliases = exports;}
