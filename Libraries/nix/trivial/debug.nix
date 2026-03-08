{lib, ...}: let
  inherit (lib.strings) concatStringsSep toJSON;
  inherit (lib.debug) addErrorContext trace;

  #~@ Namespace Utilities

  /**
  Convert a namespace path list to a dotted string.

  # Type
  ```nix
  mkNamespace :: [string] -> string
  ```

  # Examples
  ```nix
  mkNamespace ["strings" "transform"]  # => "strings.transform"
  mkNamespace ["trivial" "debug"]      # => "trivial.debug"
  ```
  */
  mkNamespace = path:
    concatStringsSep "." path;

  /**
  Create a fully qualified reference to a function.

  # Type
  ```nix
  mkRef :: { library :: string, namespace :: [string], function :: string } -> string
  ```

  # Examples
  ```nix
  mkRef { library = "lix"; namespace = ["strings" "transform"]; function = "normalize"; }
  # => "lix.strings.transform.normalize"
  ```
  */
  mkRef = {
    library,
    namespace,
    function,
  }: "${library}.${mkNamespace namespace}.${function}";

  /**
  Create a usage hint string with type signature, optional example, and :doc reference.

  # Type
  ```nix
  mkUsage :: {
    library   :: string,
    namespace :: [string],
    function  :: string,
    signature :: string,
    example   :: string | null,  # optional
  } -> string
  ```

  # Examples
  ```nix
  mkUsage {
    library   = "lix";
    namespace = ["strings" "transform"];
    function  = "normalize";
    signature = "string | [string] | null -> string | [string] | null";
  }
  # => "Usage: string | [string] | null -> string | [string] | null
  #     repl> :doc lix.strings.transform.normalize"

  mkUsage {
    library   = "lix";
    namespace = ["strings" "transform"];
    function  = "normalize";
    signature = "string | [string] | null -> string | [string] | null";
    example   = ''normalize ["Zen Twilight" "zen_beta"]  # => ["zen-twilight" "zen-beta"]'';
  }
  # => "Usage: string | [string] | null -> string | [string] | null
  #        eg: normalize ["Zen Twilight" "zen_beta"]  # => ["zen-twilight" "zen-beta"]
  #     repl> :doc lix.strings.transform.normalize"
  ```
  */
  mkUsage = {
    library,
    namespace,
    function,
    signature,
    example ? null,
  }: let
    exampleLine =
      if example != null
      then "\n     eg: ${example}"
      else "";
  in "Usage: ${signature}${exampleLine}\n   repl> :doc ${mkRef {inherit library namespace function;}}";

  #~@ Module Debug

  /**
  Create a set of debug helpers bound to a module's library name and namespace path.

  All helpers automatically include the fully qualified function reference in
  errors and traces, derived from the bound library and namespace.

  # Type
  ```nix
  mkModuleDebug :: { library :: string, namespace :: [string] } -> ModuleDebug
  ```

  # Usage
  ```nix
  {_, name, __moduleNamespacePath, ...}: let
    _debug = _.trivial.debug.mkModuleDebug {
      library = name;
      namespace = __moduleNamespacePath;
    };
  in {
    myFn = input:
      if badCondition
      then throw (_debug.traceLoc {
        function = "myFn";
        message  = "bad input";
        inherit input;
      })
      else ...;

    myOtherFn = input:
      if badCondition
      then throw (_debug.traceDoc {
        function  = "myOtherFn";
        message   = "bad input";
        signature = "string -> string";
        example   = "myOtherFn \"hello\"  # => \"HELLO\"";
        inherit input;
      })
      else ...;
  }
  ```
  */
  mkModuleDebug = {
    library,
    namespace,
  }: let
    ref = function:
      mkRef {inherit library namespace function;};
    usage = {
      function,
      signature,
      example ? null,
    }:
      mkUsage {inherit library namespace function signature example;};
  in {
    withDoc = {
      function,
      message,
      signature,
      input,
      example ? null,
    }:
      addErrorContext
      "${usage {inherit function signature example;}}"
      (throw "${message}\ninput: ${toJSON input}");

    withLoc = {
      function,
      message,
      input,
    }:
      addErrorContext
      "[${ref function}]"
      (throw "${message}\ninput: ${toJSON input}");

    /**
    Trace type signature, optional example, and :doc reference to stderr.
    Returns the error message string for the caller to throw.

    The trace fires at the debug.nix callsite, while the returned string is thrown
    at the call site — pointing the error trace to the user's module.

    # Arguments
    - function:  Name of the function where the error originates
    - message:   Human-readable error description
    - signature: Type signature string
    - example:   Optional concrete usage example
    - input:     The invalid value that caused the error (serialized via toJSON)

    # Usage
    ```nix
    then throw (_debug.traceDoc {
      function  = "normalize";
      message   = "nested lists are not supported";
      signature = "string | [string] | null -> string | [string] | null";
      example   = ''normalize ["Zen Twilight" "zen_beta"]  # => ["zen-twilight" "zen-beta"]'';
      inherit input;
    })
    ```
    */
    traceDoc = {
      function,
      message,
      signature,
      input,
      example ? null,
    }:
      trace "\n  ${usage {inherit function signature example;}}"
      "${message}\ninput: ${toJSON input}";

    # trace "${message}\ninput: ${toJSON input}\n\n${usage {inherit function signature example;}}";

    /**
    Trace just the qualified reference to stderr, return message for caller to throw.

    Lighter alternative to traceDoc when a type signature is not needed.

    # Arguments
    - function: Name of the function where the error originates
    - message:  Human-readable error description
    - input:    The invalid value that caused the error (serialized via toJSON)

    # Usage
    ```nix
    then throw (_debug.traceLoc {
      function = "trimStart";
      message  = "chars must be a string or null";
      input    = chars;
    })
    ```
    */
    traceLoc = {
      function,
      message,
      input,
    }:
      trace "[${ref function}]"
      "${message}\ninput: ${toJSON input}";

    /**
    Throw immediately with type signature, optional example, and :doc reference.

    Unlike traceDoc, the error trace points to debug.nix rather than the call site.
    Prefer traceDoc + throw at the call site for better traces.

    # Arguments
    - function:  Name of the function where the error originates
    - message:   Human-readable error description
    - signature: Type signature string
    - example:   Optional concrete usage example
    - input:     The invalid value that caused the error (serialized via toJSON)

    # Usage
    ```nix
    then _debug.throwDoc {
      function  = "normalize";
      message   = "nested lists are not supported";
      signature = "string | [string] | null -> string | [string] | null";
      example   = ''normalize ["Zen Twilight" "zen_beta"]  # => ["zen-twilight" "zen-beta"]'';
      inherit input;
    }
    ```
    */
    throwDoc = {
      function,
      message,
      signature,
      input,
      example ? null,
    }:
      addErrorContext
      "${usage {inherit function signature example;}}"
      (throw "${message}\ninput: ${toJSON input}");

    /**
    Throw immediately with the qualified reference in brackets.

    Unlike traceLoc, the error trace points to debug.nix rather than the call site.
    Prefer traceLoc + throw at the call site for better traces.

    # Arguments
    - function: Name of the function where the error originates
    - message:  Human-readable error description
    - input:    The invalid value that caused the error (serialized via toJSON)

    # Usage
    ```nix
    then _debug.throwLoc {
      function = "trimStart";
      message  = "chars must be a string or null";
      input    = chars;
    }
    ```
    */
    throwLoc = {
      function,
      message,
      input,
    }:
      throw "${message}\ninput: ${
        toJSON input
      }\n repl> :doc ${ref function}";

    /**
    Format an error string with fully qualified location, without throwing or tracing.

    Useful for building error messages to pass to other functions or log manually.

    # Arguments
    - function: Name of the function where the error originates
    - message:  Human-readable error description

    # Examples
    ```nix
    _debug.mkError { function = "normalize"; message = "unexpected null"; }
    # => "lix.strings.transform.normalize: unexpected null"
    ```
    */
    mkError = {
      function,
      message,
    }: "${ref function}: ${message}";

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
