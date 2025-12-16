{lib, ...}: let
  inherit (lib.strings) typeOf;

  # Normalize various aliases to a canonical type key
  normalizeType = t:
    {
      attrset = "set";
      attr = "set";
      set = "set";

      str = "string";

      num = "int";
      number = "int";
    }.${
      t
    } or t;

  # Canonical type key -> bare noun
  typeNouns = {
    set = "attribute set";
    list = "list";
    string = "string";
    int = "integer";
    bool = "boolean";
    binary = "binary value";
    float = "float";
    path = "path";
    null = "null";
  };

  withArticle = noun:
    if lib.lists.elem noun ["attribute set" "integer" "array" "object"]
    then "an ${noun}"
    else "a ${noun}";

  describeType = tag: let
    canon = normalizeType tag;
    noun = typeNouns.${canon} or canon;
  in
    withArticle noun;

  mkError = {
    fnName,
    argName,
    expected, # accepts "attrset" | "set" | "string" | "str" | "num" | "int" | ...
    actual,
  }: let
    expectedPretty = describeType expected;
    actualTypeRaw = typeOf actual;
    actualPretty = describeType actualTypeRaw;

    shownValue =
      if actualTypeRaw == "string"
      then "\"${actual}\""
      else if actualTypeRaw == "int"
      then toString actual
      else if actualTypeRaw == "bool"
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
