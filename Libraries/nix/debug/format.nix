# Error message formatting and value rendering.
# Provides the string-building primitives used by debug/module.nix and debug/trace.nix.
{lib, ...}: let
  inherit (lib.attrsets) isAttrs hasAttr;
  inherit (lib.strings) typeOf concatStringsSep toJSON;

  /**
  Convert a path list to a dotted namespace string.

  # Type
  ```nix
  mkNamespace :: [string] -> string
  ```

  # Examples
  ```nix
  mkNamespace ["debug" "format"]  # => "debug.format"
  ```
  */
  mkNamespace = concatStringsSep ".";

  /**
  Build a fully-qualified reference string for a function.

  # Type
  ```nix
  mkRef :: { path :: [string]?, name :: string?, function :: string } -> string
  ```

  # Examples
  ```nix
  mkRef { path = ["lix" "strings"]; function = "normalize"; }
  # => "lix.strings.normalize"

  mkRef { name = "lix"; function = "normalize"; }
  # => "lix.normalize"
  ```
  */
  mkRef = {
    path ? [],
    name ? null,
    function,
  }:
    if name != null
    then concatStringsSep "." [name function]
    else if path != []
    then concatStringsSep "." (path ++ [function])
    else throw "mkRef: either `path` or `name` must be provided";

  /**
  Create a typed example record for use in usage hints.

  Must be passed to `mkUsage` / `withDoc` — raw attrsets are rejected at
  render time.

  # Type
  ```nix
  mkExample :: { command :: string, result :: string } -> Example
  ```

  # Examples
  ```nix
  mkExample {
    command = ''normalize ["Zen Twilight" "zen_beta"]'';
    result = ''["zen-twilight" "zen-beta"]'';
  }
  ```
  */
  mkExample = {
    command,
    result,
  }: {
    inherit command result;
    _type = "example";
  };

  # Internal
  isExample = v: isAttrs v && hasAttr "_type" v && v._type == "example";

  renderExample = ex:
    if isExample ex
    then "${ex.command}  # => ${ex.result}"
    else throw "debug.format.renderExample: value must be created with mkExample";

  /**
  Build a formatted error/usage message string.

  Appends a full usage block (signature + example) when both are provided.

  # Type
  ```nix
  mkUsage :: {
    path      :: [string]?,
    name      :: string?,
    function  :: string,
    message   :: string,
    input     :: any,
    signature :: string?,
    example   :: Example?,
  } -> string
  ```
  */
  mkUsage = {
    path ? [],
    name ? null,
    function,
    message,
    input,
    signature ? null,
    example ? null,
  }: let
    ref = mkRef {inherit path name function;};
    body = "${ref}\nerror: ${message}\ninput: ${toJSON input}";
    ex =
      if example != null
      then renderExample example
      else null;
  in
    if signature == null || ex == null
    then body
    else "${body}\nusage:\n <{info}> repl> :doc ${ref}\n <{type}> ${signature}\n <{demo}> ${ex}";

  # Used by debug/module.nix after the ref is already resolved
  mkThrownUsage = {
    ref,
    message,
    input,
    signature ? null,
    example ? null,
  }: let
    ex =
      if example != null
      then renderExample example
      else null;
  in
    if signature == null || ex == null
    then "${message}\ninput: ${toJSON input}"
    else "${message}\ninput: ${toJSON input}\nusage:\n <{info}> repl> :doc ${ref}\n <{type}> ${signature}\n <{demo}> ${ex}";

  /**
  Render a Nix value as a human-readable string, safe for all types.

  Functions become `<function>`, paths their string form, everything else JSON.

  # Type
  ```nix
  renderDebugValue :: any -> string
  ```
  */
  renderDebugValue = value: let
    t = typeOf value;
  in
    if t == "lambda"
    then "<function>"
    else if t == "path"
    then toString value
    else if t == "string"
    then value
    else if t == "null"
    then "null"
    else toJSON value;

  exports = {
    inherit
      isExample
      mkExample
      mkNamespace
      mkRef
      mkThrownUsage
      mkUsage
      renderDebugValue
      renderExample
      ;
  };
in
  exports // {_rootAliases = exports;}
