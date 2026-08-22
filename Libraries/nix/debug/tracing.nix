# Trace helpers - print debug info to stderr during evaluation, return a value.
# All functions are lazy: they only fire if the result is actually demanded.
# TODO: Update the function docs to match the style and detail of `traceIfNot`
{
  _,
  lib,
  ...
}: let
  exports = {
    inherit
      trace'
      traceRaw
      traceValue
      traceValueIfNot
      traceFn
      traceIfNot
      ;
  };

  inherit (_.debug.format) renderDebugValue;
  inherit (lib.strings) typeOf;
  inherit (lib.debug) trace traceIf;

  renderType = value:
    if typeOf value == "lambda"
    then "function"
    else typeOf value;

  /**
  Trace the type and rendered value of a labeled input, then return `result`.

  Use when you want to inspect one value mid-expression without changing
  what gets returned.

  # Type
  ```nix
  trace :: { label :: string?, value :: any, result :: any } -> any
  ```

  # Examples
  ```nix
  trace { label = "cfg"; value = config; result = config.enable; }
  # stderr: "cfg type = set, value = {..."
  # => config.enable
  ```
  */
  trace' = {
    label ? null,
    value,
    result,
    displayType ? null,
    displayValue ? null,
  }: let
    prefix =
      if label == null || label == ""
      then ""
      else "${label} ";
    shownType =
      if displayType != null
      then displayType
      else renderType value;
    shownValue =
      if displayValue != null
      then displayValue
      else renderDebugValue value;
  in
    trace "${prefix}type = ${shownType}, value = ${shownValue}" result;

  /**
  Trace a raw string, then return `result`.

  # Type
  ```nix
  traceRaw :: { value :: string, result :: any } -> any
  ```
  */
  traceRaw = {
    value,
    result,
  }:
    trace value result;

  /**
  Trace the type and rendered value of a labeled input, then return that same value.

  Useful as an inline probe in let-bindings and transformation pipelines.

  # Type
  ```nix
  traceValue :: { label :: string?, value :: any } -> any
  ```

  # Examples
  ```nix
  result = traceValue { label = "input"; value = rawInput; };
  # Returns rawInput and traces it
  ```
  */
  traceValue = {
    label ? null,
    value,
  }:
    trace' {
      inherit label value;
      result = value;
    };

  /**
  Trace the type and rendered value of a labeled input if the given condition is false, then return the value.

  Useful as a conditional inline probe to catch unexpected values without spamming normal runs.

  # Inputs
  `cond`
  : boolean predicate

  `label`
  : optional string label to prefix the trace message

  `value`
  : value to trace and return

  # Type
  > traceValueIfNot :: { cond :: bool, value :: any, label :: string? } -> any

  # Examples
  - traceValueIfNot { cond = isDerivation pkg; label = "invalid-pkg"; value = pkg; };

  ```nix
  trace: invalid-pkg type = set, value = {...}
  ```
  */
  traceValueIfNot = {
    cond,
    label ? null,
    value,
  }:
    if cond
    then value
    else traceValue {inherit label value;};

  /**
  Trace a function value by name, then return `result`.

  Used internally by `debug/module.nix` to annotate function-related traces.

  # Inputs
  `name`
  : string name of the function

  `fn`
  : function value to trace

  `result`
  : value to return

  `label`
  : optional string label to prefix the trace message

  # Type
  > traceFn :: { name :: string, fn :: function, result :: any, label :: string? } -> any

  # Examples
  > traceFn { name = "normalize"; fn = normalize; result = normalize input; label = "normalizing"; }

  ```nix
  trace: normalizing type = function, value = normalize
  trace: normalizing type = set, value = {...}
  ```
  */
  traceFn = {
    name,
    fn,
    result,
    label ? null,
  }:
    trace' {
      inherit label result;
      value = fn;
      displayType = "function";
      displayValue = name;
    };

  /**
  Conditionally trace the supplied message if the predicate is false.

  # Inputs
  `pred`
  : boolean predicate

  `msg`
  : string message to trace if predicate is false

  `value`
  : value to return

  # Type
  > traceIfNot :: bool -> string -> a -> a

  # Examples
  - traceIfNot false "hello" 3

  ```nix
  trace: hello
  3
  ```

  - traceIfNot true "hello" 3

  ```nix
  3
  ```
  */
  traceIfNot = pred: msg: value:
    traceIf (!pred) msg value;
in
  exports // {__rootAliases = exports;}
