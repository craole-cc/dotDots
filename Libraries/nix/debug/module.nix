# debug/module.nix
#
# Per-module debug helper factory.
# Binds a namespace path to a set of error-formatting functions so every
# throw/trace in a module automatically includes its fully-qualified location.
{
  _,
  lib,
  ...
}: let
  inherit (_.debug.format) mkRef mkThrownUsage mkExample;
  inherit (_.debug.trace) traceFn;
  inherit (_.types.predicates) isList;
  inherit (lib.attrsets) isAttrs;
  inherit (lib.debug) addErrorContext;
  inherit (lib.strings) isString splitString toJSON;

  /**
  Tag a function value with its name so `withDoc` / `withLoc` can both
  build the qualified ref string and trace the function value.

  Pass the result as `function =` — the helpers detect whether they
  received a plain string or a NamedFn and behave accordingly.

  # Type
  ```nix
  mkFn :: { name :: string, fn :: function } -> NamedFn
  ```

  # Examples
  ```nix
  # With function tracing
  throw (_debug.withDoc {
    function  = mkFn { name = "normalize"; fn = normalize; };
    message   = "nested lists are not supported";
    ...
  })

  # Plain string — no function tracing, always works
  throw (_debug.withLoc {
    function = "trimStart";
    message  = "chars must be a string or null";
    inherit input;
  })
  ```
  */
  mkFn = {
    name,
    fn,
  }: {
    inherit name fn;
    _type = "namedFn";
  };

  _isNamedFn = v: isAttrs v && v._type or null == "namedFn";

  # Extract the name string from either a NamedFn or a plain string
  _name = function:
    if _isNamedFn function
    then function.name
    else if isString function
    then function
    else throw "debug.module: `function` must be a string or mkFn result";

  /**
  Create a set of debug helpers bound to a module's namespace path.

  Accepts a dotted string (from `__libraryPath`), a path list, or an
  attrset `{ path?, name? }`.

  # Type
  ```nix
  mkModuleDebug :: string | [string] | { path :: [string]?, name :: string? } -> ModuleDebug
  ```

  # Usage
  ```nix
  {_, __libraryPath, ...}: let
    _debug = _.debug.module.mkModuleDebug __libraryPath;
    inherit (_debug) mkFn mkExample;
  in {
    myFn = input:
      if bad
      then throw (_debug.withDoc {
        function  = mkFn { name = "myFn"; fn = myFn; };
        message   = "bad input";
        signature = "string -> string";
        example   = mkExample { command = ''myFn "x"''; result = ''"X"''; };
        inherit input;
      })
      else ...;
  }
  ```
  */
  mkModuleDebug = pathOrArgs: let
    normalized =
      if isString pathOrArgs
      then {
        path = splitString "." pathOrArgs;
        name = null;
      }
      else if isList pathOrArgs
      then {
        path = pathOrArgs;
        name = null;
      }
      else {
        path = pathOrArgs.path or [];
        name = pathOrArgs.name or null;
      };

    modulePath = normalized.path;
    moduleName = normalized.name;

    ref = fname:
      mkRef {
        path = modulePath;
        name = moduleName;
        function = fname;
      };

    # Resolve ref string and optionally emit a traceFn, then return msg
    _emit = function: msg:
      if _isNamedFn function
      then
        traceFn {
          name = ref function.name;
          fn = function.fn;
          result = msg;
        }
      else msg;
  in rec {
    inherit mkFn mkExample;

    /**
    Return a throw-ready error string with full usage context.

    `function` accepts either a plain string or a `mkFn` result.
    When a `mkFn` result is passed the function value is traced to stderr.

    # Usage
    ```nix
    then throw (_debug.withDoc {
      function  = mkFn { name = "normalize"; fn = normalize; };
      message   = "nested lists are not supported";
      signature = "string | [string] | null -> string | [string] | null";
      example   = mkExample { command = "..."; result = "..."; };
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
    }: let
      fnRef = ref (_name function);
      thrown = mkThrownUsage {
        ref = fnRef;
        inherit message input signature example;
      };
    in
      _emit function thrown;

    /**
    Return a throw-ready error string with location only (no signature/example).

    # Usage
    ```nix
    then throw (_debug.withLoc {
      function = mkFn { name = "trimStart"; fn = trimStart; };
      message  = "chars must be a string or null";
      inherit input;
    })
    ```
    */
    withLoc = {
      function,
      message,
      input,
    }: let
      thrown = "${message}\ninput: ${toJSON input}";
    in
      _emit function thrown;

    /**
    Throw with full usage context via `addErrorContext`.

    Stack trace points into debug/module.nix. Prefer `withDoc + throw`
    when call-site trace location matters.
    */
    throwDoc = {
      function,
      message,
      signature,
      input,
      example ? null,
    }: let
      fnRef = ref (_name function);
      thrown = mkThrownUsage {
        ref = fnRef;
        inherit message input signature example;
      };
    in
      addErrorContext "from call site" (throw (_emit function thrown));

    /**
    Throw with location-only context via `addErrorContext`.
    */
    throwLoc = {
      function,
      message,
      input,
    }: let
      thrown = "${message}\ninput: ${toJSON input}";
    in
      addErrorContext "from call site" (throw (_emit function thrown));

    /**
    Format a plain error string without throwing or tracing.

    # Examples
    ```nix
    _debug.mkError { function = "normalize"; message = "unexpected null"; }
    # => "lix.strings.transform.normalize: unexpected null"
    ```
    */
    mkError = {
      function,
      message,
    }: "${ref (_name function)}: ${message}";

    inherit ref;
  };

  exports = {inherit mkModuleDebug mkFn;};
in
  exports // {_rootAliases = exports;}
