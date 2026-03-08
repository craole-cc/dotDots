{lib, ...}: let
  inherit (lib.attrsets) isAttrs hasAttr;
  inherit (lib.debug) addErrorContext trace;
  inherit (lib.strings) concatStringsSep toJSON;

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
  Create a typed example value for use in usage hints.

  Type-locks the example shape to { cmd, res } so all examples are consistent
  and can be formatted uniformly. Must be used with mkUsage — raw strings are
  rejected at render time.

  # Type
  ```nix
  mkExample :: { cmd :: string, res :: string } -> Example
  ```

  # Examples
  ```nix
  mkExample {
    cmd = ''normalize ["Zen Twilight" "zen_beta"]'';
    res = ''["zen-twilight" "zen-beta"]'';
  }
  # => { _type = "example"; cmd = "..."; res = "..."; }
  ```
  */
  mkExample = {
    cmd,
    res,
  }: {
    inherit cmd res;
    _type = "example";
  };

  #| Internal: check if a value is a valid mkExample output
  _isExample = v: isAttrs v && hasAttr "_type" v && v._type == "example";

  #| Internal: render an example to a string
  _renderExample = ex:
    if _isExample ex
    then "${ex.cmd}  # => ${ex.res}"
    else throw "debug: example must be created with mkExample";

  /**
  Build a formatted error/usage message string.

  When both `signature` and `example` are provided, a full usage block is appended.
  When either is missing, only the location and error are shown.

  The `tracing` flag controls whether the library reference appears as a plain
  string (tracing = true, for trace output) or prefixed with "trace:" (tracing = false).

  # Type
  ```nix
  mkUsage :: {
    library   :: string,
    namespace :: [string],
    function  :: string,
    message   :: string,
    input     :: any,
    signature :: string | null,   # optional
    example   :: Example | null,  # optional, must use mkExample
    tracing   :: bool,            # default true
  } -> string
  ```

  # Examples
  ```nix
  # Without signature/example — shows location + error only
  mkUsage {
    library = "lix"; namespace = ["strings" "transform"]; function = "normalize";
    message = "nested lists are not supported";
    input   = [["a"] "b"];
  }
  # => "lix.strings.transform.normalize
  #     error: nested lists are not supported
  #     input: [[\"a\"],\"b\"]"

  # With signature and example — shows full usage block
  mkUsage {
    library   = "lix"; namespace = ["strings" "transform"]; function = "normalize";
    message   = "nested lists are not supported";
    input     = [["a"] "b"];
    signature = "string | [string] | null -> string | [string] | null";
    example   = mkExample {
      cmd = ''normalize ["Zen Twilight" "zen_beta"]'';
      res = ''["zen-twilight" "zen-beta"]'';
    };
  }
  # => "lix.strings.transform.normalize
  #     error: nested lists are not supported
  #     input: [[\"a\"],\"b\"]
  #     usage:
  #      <{info}> repl> :doc lix.strings.transform.normalize
  #      <{type}> string | [string] | null -> string | [string] | null
  #      <{demo}> normalize [\"Zen Twilight\" \"zen_beta\"]  # => [\"zen-twilight\" \"zen-beta\"]"
  ```
  */
  mkUsage = {
    library,
    namespace,
    function,
    message,
    input,
    signature ? null,
    example ? null,
    tracing ? true,
  }: let
    fn = mkRef {inherit library namespace function;};
    loc =
      if tracing
      then "${fn}"
      else "\ntrace: ${fn}";
    msg = "${loc}\nerror: ${message}\ninput: ${toJSON input}";
    ex =
      if example != null
      then _renderExample example
      else null;
    sig = signature;
  in
    if sig == null || ex == null
    then "${msg}"
    else "${msg}\nusage:\n <{info}> repl> :doc ${fn}\n <{type}> ${sig}\n <{demo}> ${ex}";

  #~@ Module Debug

  /**
  Create a set of debug helpers bound to a module's library name and namespace path.

  All helpers automatically include the fully qualified function reference in
  errors and context, derived from the bound library and namespace.

  # Type
  ```nix
  mkModuleDebug :: { library :: string, namespace :: [string] } -> ModuleDebug
  ```

  # Usage
  ```nix
  {_, name, __moduleNamespacePath, ...}: let
    _debug = _.trivial.debug.mkModuleDebug {
      library   = name;
      namespace = __moduleNamespacePath;
    };
  in {
    myFn = input:
      if badCondition
      then throw (_debug.withDoc {
        function  = "myFn";
        message   = "bad input";
        signature = "string -> string";
        example   = _.trivial.debug.mkExample {
          cmd = "myFn \"hello\"";
          res = "\"HELLO\"";
        };
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
      message,
      input,
      tracing ? false,
      signature ? null,
      example ? null,
    }:
      mkUsage {inherit library namespace function message tracing input signature example;};
  in {
    /**
    Eagerly print error context to stderr via trace, return the message string
    for the caller to throw.

    The trace fires immediately — even if the caller never throws. The returned
    string is intended to be passed directly to `throw` at the call site, which
    points the error trace to the user's module rather than debug.nix.

    Includes the full usage block (type signature + example) when both are provided.

    # Arguments
    - function:  Name of the function where the error originates
    - message:   Human-readable error description
    - signature: Type signature string
    - input:     The invalid value (serialized via toJSON)
    - example:   Optional Example, must be created with mkExample

    # Usage
    ```nix
    then throw (_debug.withDoc {
      function  = "normalize";
      message   = "nested lists are not supported";
      signature = "string | [string] | null -> string | [string] | null";
      example   = mkExample {
        cmd = ''normalize ["Zen Twilight" "zen_beta"]'';
        res = ''["zen-twilight" "zen-beta"]'';
      };
      inherit input;
    })
    ```
    */
    withDoc = {
      function,
      message,
      signature,
      input,
      example ? null,
    }:
      trace
      "${usage {
        inherit function message input signature example;
        tracing = true;
      }}"
      "${message}";

    /**
    Eagerly print location-only error context to stderr via trace, return the
    message string for the caller to throw.

    Lighter alternative to withDoc when a type signature is not needed.

    # Arguments
    - function: Name of the function where the error originates
    - message:  Human-readable error description
    - input:    The invalid value (serialized via toJSON)

    # Usage
    ```nix
    then throw (_debug.withLoc {
      function = "trimStart";
      message  = "chars must be a string or null";
      input    = chars;
    })
    ```
    */
    withLoc = {
      function,
      message,
      input,
    }:
      trace
      "${usage {
        inherit function message input;
        tracing = true;
      }}"
      "${message}";

    /**
    Throw with full usage context using addErrorContext.

    The error trace points to debug.nix rather than the call site.
    Prefer withDoc + throw at the call site when trace location matters.

    # Arguments
    - function:  Name of the function where the error originates
    - message:   Human-readable error description
    - signature: Type signature string
    - input:     The invalid value (serialized via toJSON)
    - example:   Optional Example, must be created with mkExample

    # Usage
    ```nix
    then _debug.throwDoc {
      function  = "normalize";
      message   = "nested lists are not supported";
      signature = "string | [string] | null -> string | [string] | null";
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
      "${usage {inherit function message input signature example;}}"
      (throw "${message}");

    /**
    Throw with location-only context using addErrorContext.

    The error trace points to debug.nix rather than the call site.
    Prefer withLoc + throw at the call site when trace location matters.

    # Arguments
    - function: Name of the function where the error originates
    - message:  Human-readable error description
    - input:    The invalid value (serialized via toJSON)

    # Usage
    ```nix
    then _debug.throwLoc {
      function = "trimStart";
      message  = "chars must be a string or null";
      inherit input;
    }
    ```
    */
    throwLoc = {
      function,
      message,
      input,
    }:
      addErrorContext
      "${usage {inherit function message input;}}"
      (throw "${message}");

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
      mkExample
      mkUsage
      mkModuleDebug
      ;
  };
in
  exports // {_rootAliases = exports;}
