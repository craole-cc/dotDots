# Libraries/types/schema.nix
# Advanced type system that bridges predicates, generators, and schema validation
{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) attrNames attrValues mapAttrs;
  inherit (lib.lists) elem all head;
  inherit (lib.types) anything oneOf;
  inherit (lib.strings) concatStringsSep match;
  inherit
    (_.types.predicates)
    isAttrs
    isBinaryString
    isBool
    isFloat
    isInt
    isList
    isPath
    isString
    typeOf
    ;
  inherit (_.types.generators) validate;
  inherit (_.types) schema;

  #~@ Basic types with predicates
  str = {
    type = "string";
    check = isString;
    validate = value:
      validate {
        fnName = "type.str";
        argName = "value";
        desired = "string";
        predicate = isString;
        outcome = value;
      };
    default = "";
    description = "A string value";
  };

  bool = {
    type = "bool";
    check = isBool;
    validate = value:
      validate {
        fnName = "type.bool";
        argName = "value";
        desired = "bool";
        predicate = isBool;
        outcome = value;
      };
    default = false;
    description = "A boolean value";
  };

  int = {
    type = "int";
    check = isInt;
    validate = value:
      validate {
        fnName = "type.int";
        argName = "value";
        desired = "int";
        predicate = isInt;
        outcome = value;
      };
    default = 0;
    description = "An integer value";
  };

  float = {
    type = "float";
    check = isFloat;
    validate = value:
      validate {
        fnName = "type.float";
        argName = "value";
        desired = "float";
        predicate = v: isFloat v || isInt v;
        outcome = value;
      };
    default = 0.0;
    description = "A floating point value";
  };

  path = {
    type = "path";
    check = isPath;
    validate = value:
      validate {
        fnName = "type.path";
        argName = "value";
        desired = "path";
        predicate = isPath;
        outcome = value;
      };
    default = null;
    description = "A filesystem path";
  };

  binary = {
    type = "binary";
    check = isBinaryString;
    validate = value:
      validate {
        fnName = "type.binary";
        argName = "value";
        desired = "binary";
        predicate = isBinaryString;
        outcome = value;
      };
    default = "0";
    description = "A binary string ('0' or '1')";
  };

  #~@ Composite types
  nullOr = subtype: {
    type = "nullOr";
    subtype = subtype;
    check = v: v == null || subtype.check v;
    validate = value:
      if value == null
      then value
      else subtype.validate value;
    default = null;
    description = "Either ${subtype.description or subtype.type} or null";
  };

  listOf = subtype: {
    type = "listOf";
    subtype = subtype;
    check = v: isList v && all subtype.check v;
    validate = value: let
      validated = validate {
        fnName = "type.listOf";
        argName = "value";
        desired = "list";
        predicate = isList;
        outcome = value;
      };
    in
      map subtype.validate validated;
    default = [];
    description = "A list of ${subtype.description or subtype.type}";
  };

  attrsOf = subtype: {
    type = "attrsOf";
    subtype = subtype;
    check = v: isAttrs v && all subtype.check (attrValues v);
    validate = value: let
      validated = validate {
        fnName = "type.attrsOf";
        argName = "value";
        desired = "attrset";
        predicate = isAttrs;
        outcome = value;
      };
    in
      mapAttrs (_: subtype.validate) validated;
    default = {};
    description = "An attribute set of ${subtype.description or subtype.type}";
  };

  enum = values: {
    type = "enum";
    inherit values;
    check = v: elem v values;
    validate = value:
      if elem value values
      then value
      else throw "type.enum: expected one of [${concatStringsSep ", " (map toString values)}], got ${toString value}";
    default = head values;
    description = "One of: ${concatStringsSep ", " (map toString values)}";
  };

  #~@ Submodule with nested schema
  submodule = schema: {
    type = "submodule";
    inherit schema;
    check = isAttrs;
    validate = value: schema.validate schema value;
    default = schema.extractDefaults schema;
    description = "A submodule with fields: ${concatStringsSep ", " (attrNames schema)}";
  };

  either = a: b: {
    type = "either";
    types = [a b];
    check = v: a.check v || b.check v;
    validate = value:
      if a.check value
      then a.validate value
      else if b.check value
      then b.validate value
      else throw "type.either: expected ${a.description or a.type} or ${b.description or b.type}, got ${typeOf value}";
    default = a.default;
    description = "${a.description or a.type} or ${b.description or b.type}";
  };

  # oneOf = types: {
  #   type = "oneOf";
  #   inherit types;
  #   check = v: any (t: check v) types;
  #   validate = value: let
  #     matches = filter (t: check value) types;
  #   in
  #     if matches == []
  #     then throw "type.oneOf: no matching type for value ${generators.showValue value}"
  #     else (head matches).validate value;
  #   default = (head types).default;
  #   description = "One of: ${concatStringsSep " | " (map (t: description or type) types)}";
  # };

  # any = {
  #   type = "any";
  #   check = _: true;
  #   validate = value: value;
  #   default = null;
  #   description = "Any value";
  # };

  # Lazy type (for recursive structures)
  lazy = schemaFn: {
    type = "lazy";
    schemaFn = schemaFn;
    check = isAttrs;
    validate = value: schema.validate (schemaFn {}) value;
    default = null;
    description = "A lazily evaluated submodule";
  };

  # String with constraints
  strMatching = pattern: {
    type = "strMatching";
    inherit pattern;
    check = v: isString v && match pattern v != null;
    validate = value:
      if isString value && match pattern value != null
      then value
      else throw "type.strMatching: string must match pattern '${pattern}', got '${value}'";
    default = "";
    description = "A string matching pattern '${pattern}'";
  };

  # Integer with constraints
  intBetween = min: max: {
    type = "intBetween";
    inherit min max;
    check = v: isInt v && v >= min && v <= max;
    validate = value:
      if isInt value && value >= min && value <= max
      then value
      else throw "type.intBetween: integer must be between ${toString min} and ${toString max}, got ${toString value}";
    default = min;
    description = "An integer between ${toString min} and ${toString max}";
  };

  # Non-empty list
  nonEmptyListOf = subtype: {
    type = "nonEmptyListOf";
    subtype = subtype;
    check = v: isList v && v != [] && all subtype.check v;
    validate = value: let
      validated = validate {
        fnName = "type.nonEmptyListOf";
        argName = "value";
        desired = "list";
        predicate = v: isList v && v != [];
        outcome = value;
      };
    in
      map subtype.validate validated;
    default = [];
    description = "A non-empty list of ${subtype.description or subtype.type}";
  };

  # Attribute set with specific required keys
  attrsWith = requiredKeys: {
    type = "attrsWith";
    inherit requiredKeys;
    check = v:
      isAttrs v && all (key: v ? ${key}) requiredKeys;
    validate = value:
      if isAttrs value && all (key: value ? ${key}) requiredKeys
      then value
      else throw "type.attrsWith: attribute set must have keys [${concatStringsSep ", " requiredKeys}]";
    default = {};
    description = "An attribute set with required keys: ${concatStringsSep ", " requiredKeys}";
  };

  # Port number
  port =
    intBetween 1 65535
    // {
      type = "port";
      description = "A valid port number (1-65535)";
    };

  # Positive integer
  positiveInt = {
    type = "positiveInt";
    check = v: isInt v && v > 0;
    validate = value:
      if isInt value && value > 0
      then value
      else throw "type.positiveInt: must be a positive integer, got ${toString value}";
    default = 1;
    description = "A positive integer";
  };

  # Non-negative integer
  nonNegativeInt = {
    type = "nonNegativeInt";
    check = v: isInt v && v >= 0;
    validate = value:
      if isInt value && value >= 0
      then value
      else throw "type.nonNegativeInt: must be non-negative, got ${toString value}";
    default = 0;
    description = "A non-negative integer";
  };
in {
  any = anything;
  inherit
    oneOf
    attrsOf
    attrsWith
    binary
    bool
    either
    enum
    float
    int
    intBetween
    lazy
    listOf
    nonEmptyListOf
    nonNegativeInt
    nullOr
    path
    port
    positiveInt
    str
    strMatching
    submodule
    ;
}
