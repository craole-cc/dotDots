{
  _,
  lib,
  ...
}: let
  inherit (lib.strings) concatStringsSep;
  inherit (lib.attrsets) attrNames;
  inherit (lib.lists) take length;
  inherit (_.types.predicates) typeOf isAttrs isBool isInt;
  inherit (_.trivial.tests) mkTest runTests mkThrows;

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
      + concatStringsSep ", " (map showValue preview)
      + (
        if length v > 5
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
      + concatStringsSep ", " preview
      + (
        if length keys > 5
        then ", …"
        else ""
      )
      + " }"
    else "<" + t + ">";

  mkError = {
    fnName,
    argName,
    desired,
    outcome,
  }: let
    expectedPretty = describeType desired;
    actualTypeRaw = typeOf outcome;
    actualPretty = describeType actualTypeRaw;
    valuePreview = showValue outcome;
  in "${fnName}: `${argName}` must be ${expectedPretty}, but ${actualPretty} was given (value: ${valuePreview}).";

  validate = {
    fnName,
    argName,
    desired,
    predicate,
    outcome,
  }:
    if !predicate outcome
    then throw (mkError {inherit fnName argName desired outcome;})
    else outcome;
in {
  inherit mkError validate;

  _rootAliases = {
    mkTypeError = mkError;
    validateType = validate;
  };

  _tests = runTests {
    mkError = {
      stringExpectedSetGotString =
        mkTest
        "waylandEnabled: `config` must be an attribute set, but a string was given (value: \"cfg\")."
        (mkError {
          fnName = "waylandEnabled";
          argName = "config";
          desired = "attrset";
          outcome = "cfg";
        });

      stringExpectedSetGotInt =
        mkTest
        "waylandEnabled: `config` must be an attribute set, but an integer was given (value: 1)."
        (mkError {
          fnName = "waylandEnabled";
          argName = "config";
          desired = "attrset";
          outcome = 1;
        });

      stringExpectedListGotSet =
        mkTest
        "foo: `bar` must be a list, but an attribute set was given (value: { a, b })."
        (mkError {
          fnName = "foo";
          argName = "bar";
          desired = "list";
          outcome = {
            a = 1;
            b = 2;
          };
        });

      stringExpectedStringGotListPreview =
        mkTest
        "fn: `val` must be a string, but a list was given (value: [1, 2, 3, …])."
        (mkError {
          fnName = "fn";
          argName = "val";
          desired = "string";
          outcome = [1 2 3 4 5 6];
        });

      # Demonstrate alias normalization: desired = "set"
      stringExpectedSetAlias =
        mkTest
        "fn: `cfg` must be an attribute set, but a string was given (value: \"x\")."
        (mkError {
          fnName = "fn";
          argName = "cfg";
          desired = "set";
          outcome = "x";
        });

      # Demonstrate desired = "str" alias
      stringExpectedStrAlias =
        mkTest
        "fn: `name` must be a string, but an integer was given (value: 5)."
        (mkError {
          fnName = "fn";
          argName = "name";
          desired = "str";
          outcome = 5;
        });

      # Demonstrate desired = "num" alias
      stringExpectedNumAlias =
        mkTest
        "fn: `n` must be an integer, but a string was given (value: \"7\")."
        (mkError {
          fnName = "fn";
          argName = "n";
          desired = "num";
          outcome = "7";
        });

      # Demonstrate desired = "binary"
      stringExpectedBinary =
        mkTest
        "fn: `blob` must be a binary value, but a string was given (value: \"abc\")."
        (mkError {
          fnName = "fn";
          argName = "blob";
          desired = "binary";
          outcome = "abc";
        });

      # Demonstrate float outcome
      stringExpectedIntGotFloat =
        mkTest
        "fn: `x` must be an integer, but a float was given (value: <float>)."
        (mkError {
          fnName = "fn";
          argName = "x";
          desired = "int";
          outcome = 1.5;
        });

      # Demonstrate path outcome
      stringExpectedPathGotSet =
        mkTest
        "fn: `p` must be a path, but an attribute set was given (value: { a })."
        (mkError {
          fnName = "fn";
          argName = "p";
          desired = "path";
          outcome = {a = 1;};
        });

      # Demonstrate null outcome
      stringExpectedSetGotNull =
        mkTest
        "fn: `cfg` must be an attribute set, but null was given (value: <null>)."
        (mkError {
          fnName = "fn";
          argName = "cfg";
          desired = "attrset";
          outcome = null;
        });

      # List-of-sets preview
      stringExpectedListOfSetsPreview =
        mkTest
        "fn: `xs` must be a list, but a list was given (value: [{ a }, { b }, { c }, { d }, { e }, …])."
        (mkError {
          fnName = "fn";
          argName = "xs";
          desired = "list";
          outcome = [
            {a = 1;}
            {b = 2;}
            {c = 3;}
            {d = 4;}
            {e = 5;}
            {f = 6;}
          ];
        });
    };

    validate = {
      acceptsCorrectType = mkTest {x = 1;} (
        validate {
          fnName = "testFn";
          argName = "x";
          desired = "int";
          predicate = isInt;
          outcome = {x = 1;}.x;
        }
      );

      # Also show validate with desired "string"/isString pattern
      acceptsString = mkTest "ok" (
        validate {
          fnName = "testFn";
          argName = "name";
          desired = "string";
          predicate = lib.strings.isString;
          outcome = "ok";
        }
      );

      rejectsWrongTypeString = mkThrows (
        validate {
          fnName = "testFn";
          argName = "x";
          desired = "attrset";
          predicate = isAttrs;
          outcome = "oops";
        }
      );

      rejectsWrongTypeList = mkThrows (
        validate {
          fnName = "testFn";
          argName = "x";
          desired = "attrset";
          predicate = isAttrs;
          outcome = ["pop" 1];
        }
      );

      rejectsWrongTypeBool = mkThrows (
        validate {
          fnName = "testFn";
          argName = "flag";
          desired = "bool";
          predicate = isBool;
          outcome = 42;
        }
      );

      rejectsWrongTypeBinary = mkThrows (
        validate {
          fnName = "binFn";
          argName = "blob";
          desired = "binary";
          predicate = lib.strings.isString; # pretend "binary" stored as string for demo
          outcome = 10;
        }
      );
    };

    acceptsBinaryString0 = mkTest "0" (
      validate {
        fnName = "testFn";
        argName = "flag";
        desired = "binary";
        predicate = lib.strings.isBinaryString;
        outcome = "0";
      }
    );

    acceptsBinaryString1 = mkTest "1" (
      validate {
        fnName = "testFn";
        argName = "flag";
        desired = "binary";
        predicate = lib.strings.isBinaryString;
        outcome = "1";
      }
    );

    rejectsNonBinaryString = mkThrows (
      validate {
        fnName = "testFn";
        argName = "flag";
        desired = "binary";
        predicate = lib.strings.isBinaryString;
        outcome = "yes";
      }
    );

    rejectsBinaryInt = mkThrows (
      validate {
        fnName = "testFn";
        argName = "flag";
        desired = "binary";
        predicate = lib.strings.isBinaryString;
        outcome = 1;
      }
    );
  };
}
