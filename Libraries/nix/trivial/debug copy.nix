{lib, ...}: let
  inherit (lib.strings) concatStringsSep toJSON;
  inherit (lib.debug) trace;

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
  Create a usage hint string with a usage example and :doc reference.

  # Type
  ```nix
  mkUsage :: { library :: string, namespace :: [string], function :: string, example :: string } -> string
  ```

  # Examples
  ```nix
  mkUsage {
    library = "lix";
    namespace = ["strings" "transform"];
    function = "normalize";
    example = ''normalize ["Zen Twilight" "zen_beta"]  # => ["zen-twilight" "zen-beta"]'';
  }
  # => "string | [string] | null -> string | [string] | null
  #     repl> :doc lix.strings.transform.normalize"
  ```
  */
  mkUsage = {
    library,
    namespace,
    function,
    example,
  }: "${example}\n repl> :doc ${mkRef {inherit library namespace function;}}";

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
    #> Simple error with location bracket
    myFn = input:
      if badCondition
      then throw (_debug.traceLoc { function = "myFn"; message = "bad input"; inherit input; })
      else ...;

    #> Error with a usage example and :doc hint
    myOtherFn = input:
      if badCondition
      then throw (_debug.traceDoc { function = "myOtherFn"; message = "bad input"; example = "string -> string"; inherit input; })
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
    usage = function: example:
      mkUsage {inherit library namespace function example;};
  in {
    /**
    Trace with usage example and :doc reference to stderr, return message for caller to throw.

    The trace fires at the debug.nix callsite (printing the a usage eample and repl hint),
    while the returned string is thrown at the call site — pointing the error trace to the
    user's module rather than debug.nix.

    # Arguments
    - function: Name of the function where the error originates
    - message: Human-readable error description
    - signature: Type signature string
    - input: The invalid input that caused the error (serialized via toJSON)

    # Usage
    ```nix
    then throw (_debug.traceDoc {
      function = "normalize";
      message = "nested lists are not supported";
      example = ''normalize ["Zen Twilight" "zen_beta"]  # => ["zen-twilight" "zen-beta"]'';
      inherit input;
    })
    ```
    */
    traceDoc = {
      function,
      message,
      example,
      input,
    }:
      trace "${usage function example}"
      "${message}, got: ${toJSON input}";

    /**
    Trace just the qualified reference to stderr, return message for caller to throw.

    Lighter alternative to traceDoc when an example is not needed.

    # Arguments
    - function: Name of the function where the error originates
    - message: Human-readable error description
    - input: The invalid input that caused the error (serialized via toJSON)

    # Usage
    ```nix
    then throw (_debug.traceLoc {
      function = "trimStart";
      message = "chars must be a string or null";
      input = chars;
    })
    ```
    */
    traceLoc = {
      function,
      message,
      input,
    }:
      trace "[${ref function}]"
      "${message}, got: ${toJSON input}";

    /**
    Throw immediately with an example and :doc reference in the message.

    Unlike traceDoc, the error trace will point to debug.nix rather than the
    call site. Prefer traceDoc + throw at the call site for better traces.

    # Arguments
    - function: Name of the function where the error originates
    - message: Human-readable error description
    - example: Usage demonstration

    # Usage
    ```nix
    then _debug.throwDoc {
      function = "normalize";
      message = "nested lists are not supported";
      example = ''normalize ["Zen Twilight" "zen_beta"]  # => ["zen-twilight" "zen-beta"]'';
    }
    ```
    */
    throwDoc = {
      function,
      message,
      example,
      input,
    }:
      throw "${message}\ninput: ${toJSON input}\n\nUsage: ${usage function example}";

    /**
    Throw immediately with the qualified reference in brackets.

    Unlike traceLoc, the error trace will point to debug.nix rather than the
    call site. Prefer traceLoc + throw at the call site for better traces.

    # Arguments
    - function: Name of the function where the error originates
    - message: Human-readable error description

    # Usage
    ```nix
    then _debug.throwLoc {
      function = "trimStart";
      message = "chars must be a string or null";
    }
    ```
    */
    throwLoc = {
      function,
      message,
      input,
    }:
      throw "${message}\ninput: ${toJSON input}\n repl> :doc ${ref function}";

    /**
    Format an error string with fully qualified location, without throwing or tracing.

    Useful for building error messages to pass to other functions or log manually.

    # Arguments
    - function: Name of the function where the error originates
    - message: Human-readable error description

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
