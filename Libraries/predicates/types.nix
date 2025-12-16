{lib, ...}: let
  inherit (lib.strings) typeOf;

  prettyExpected = expected:
    {
      attrset = "an attribute set";
      attr = "an attribute set";
      set = "an attribute set";
      list = "a list";
      string = "a string";
      str = "a string";
      int = "an integer";
      num = "an integer";
      number = "an integer";
      bool = "a boolean";
      binary = "a binary check";
    }.${
      expected
    } or expected;

  mkError = {
    fnName,
    argName,
    expected, # "set" | "list" | "string" | ...
    actual,
  }: "${fnName}: `${argName}` expected to be ${prettyExpected expected}, got ${typeOf actual}";

  validate = {
    fnName,
    argName,
    expected, # "set" | "list" | "string" | ...
    predicate,
    actual,
  }:
    if !predicate actual
    then throw (mkError {inherit fnName argName expected actual;})
    else actual;
in {
  inherit mkError validate;
  _rootAliases = {
    mkTypeError = mkError;
    validateType = validate;
  };
}
