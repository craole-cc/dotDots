{lib, ...}: let
  inherit (lib.strings) typeOf;

  # Single source of truth: type tag -> phrase (with article if needed)
  typePhrases = {
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

    binary = "a binary value";

    float = "a float";
    path = "a path";
    null = "null";
  };

  describeType = tag:
    typePhrases.${tag} or ("a " + tag);

  mkError = {
    fnName,
    argName,
    expected, # "set" | "attrset" | "list" | "string" | ...
    actual,
  }: let
    expectedPretty = describeType expected;
    actualPretty = describeType (typeOf actual);
  in "${fnName}: `${argName}` must be ${expectedPretty}, but ${actualPretty} was given.";

  validate = {
    fnName,
    argName,
    expected,
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
