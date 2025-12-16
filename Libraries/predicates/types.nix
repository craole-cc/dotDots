{lib, ...}: let
  inherit (lib.strings) typeOf;
  inherit (lib.attrsets) attrNames;
  inherit (lib.lists) take;

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

  showValue = v: let
    t = typeOf v;
  in
    if t == "string"
    then "\"${v}\""
    else if t == "int"
    then toString v
    else if t == "bool"
    then
      (
        if v
        then "true"
        else "false"
      )
    else if t == "list"
    then let
      preview = take 5 v;
    in
      "["
      + builtins.concatStringsSep ", " (map showValue preview)
      + (
        if builtins.length v > 5
        then ", …"
        else ""
      )
      + "]"
    else if t == "set"
    then let
      keys = attrNames v;
      preview = take 5 keys;
    in
      "{ "
      + builtins.concatStringsSep ", " preview
      + (
        if builtins.length keys > 5
        then ", …"
        else ""
      )
      + " }"
    else "<" + t + ">";

  mkError = {
    fnName,
    argName,
    expected,
    actual,
  }: let
    expectedPretty = describeType expected;
    actualTypeRaw = typeOf actual;
    actualPretty = describeType actualTypeRaw;
    valuePreview = showValue actual;
  in "${fnName}: `${argName}` must be ${expectedPretty}, but ${actualPretty} was given (value: ${valuePreview}).";

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
