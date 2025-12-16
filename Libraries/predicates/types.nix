{lib, ...}: let
  inherit (lib.strings) typeOf;

  # Base nouns per type tag
  typeNouns = {
    attrset = "attribute set";
    attr = "attribute set";
    set = "attribute set";

    list = "list";

    string = "string";
    str = "string";

    int = "integer";
    num = "integer";
    number = "integer";

    bool = "boolean";

    binary = "binary value";

    float = "float";
    path = "path";
    null = "null";
  };

  withArticle = noun:
    if
      noun
      == "attribute set"
      || noun == "integer"
      || noun == "array"
      || noun == "object"
    then "an ${noun}"
    else "a ${noun}";

  describeType = tag: let
    noun = typeNouns.${tag} or tag;
  in
    withArticle noun;

  mkError = {
    fnName,
    argName,
    expected, # "attrset" | "set" | "list" | "string" | ...
    actual,
  }: let
    expectedPretty = describeType expected;
    actualType = typeOf actual;
    actualPretty = describeType actualType;
    shownValue =
      # avoid huge blobs; simple pretty-print primitives and small sets/lists
      if actualType == "string"
      then "\"${actual}\""
      else if actualType == "int"
      then toString actual
      else if actualType == "bool"
      then
        (
          if actual
          then "true"
          else "false"
        )
      else "<value elided>";
  in "${fnName}: `${argName}` must be ${expectedPretty}, but ${actualPretty} was given (value: ${shownValue}).";

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
