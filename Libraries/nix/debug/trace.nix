# Trace helpers — print debug info to stderr during evaluation, return a value.
# All functions are lazy: they only fire if the result is actually demanded.
{
  _,
  lib,
  ...
}: let
  inherit (_.debug.format) renderDebugValue;
  inherit (lib.strings) typeOf;

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
  trace = {
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
    lib.debug.trace "${prefix}type = ${shownType}, value = ${shownValue}" result;

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
    lib.debug.trace value result;

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
    trace {
      inherit label value;
      result = value;
    };

  /**
  Trace a function value by name, then return `result`.

  Used internally by `debug/module.nix` to annotate function-related traces.

  # Type
  ```nix
  traceFn :: { name :: string, fn :: function, result :: any, label :: string? } -> any
  ```
  */
  traceFn = {
    name,
    fn,
    result,
    label ? null,
  }:
    trace {
      inherit label result;
      value = fn;
      displayType = "function";
      displayValue = name;
    };

  exports = {
    inherit trace traceRaw traceValue traceFn;
  };
in
  exports // {_rootAliases = exports;}
