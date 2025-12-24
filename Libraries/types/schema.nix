# Libraries/types/schema.nix
# Advanced type system that bridges predicates, generators, and schema validation
{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs recursiveUpdate;
  inherit (lib.lists) elem all;
  inherit (lib.strings) concatStringsSep;
  inherit (builtins) typeOf isAttrs isBool isInt isFloat;

  # Import existing type utilities
  predicates = _.types.predicates;
  generators = _.types.generators;

  # ============================================================================
  # TYPE CONSTRUCTORS (building on your existing system)
  # ============================================================================

  t = rec {
    # Basic types with predicates from your existing system
    str = {
      type = "string";
      check = predicates.isString;
      validate = value:
        generators.validate {
          fnName = "type.str";
          argName = "value";
          desired = "string";
          predicate = predicates.isString;
          outcome = value;
        };
      default = "";
      description = "A string value";
    };

    bool = {
      type = "bool";
      check = predicates.isBool;
      validate = value:
        generators.validate {
          fnName = "type.bool";
          argName = "value";
          desired = "bool";
          predicate = predicates.isBool;
          outcome = value;
        };
      default = false;
      description = "A boolean value";
    };

    int = {
      type = "int";
      check = predicates.isInt;
      validate = value:
        generators.validate {
          fnName = "type.int";
          argName = "value";
          desired = "int";
          predicate = predicates.isInt;
          outcome = value;
        };
      default = 0;
      description = "An integer value";
    };

    float = {
      type = "float";
      check = predicates.isFloat;
      validate = value:
        generators.validate {
          fnName = "type.float";
          argName = "value";
          desired = "float";
          predicate = v: predicates.isFloat v || predicates.isInt v;
          outcome = value;
        };
      default = 0.0;
      description = "A floating point value";
    };

    path = {
      type = "path";
      check = predicates.isPath;
      validate = value:
        generators.validate {
          fnName = "type.path";
          argName = "value";
          desired = "path";
          predicate = predicates.isPath;
          outcome = value;
        };
      default = null;
      description = "A filesystem path";
    };

    binary = {
      type = "binary";
      check = predicates.isBinaryString;
      validate = value:
        generators.validate {
          fnName = "type.binary";
          argName = "value";
          desired = "binary";
          predicate = predicates.isBinaryString;
          outcome = value;
        };
      default = "0";
      description = "A binary string ('0' or '1')";
    };

    # Composite types
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
      check = v: predicates.isList v && all subtype.check v;
      validate = value: let
        validated = generators.validate {
          fnName = "type.listOf";
          argName = "value";
          desired = "list";
          predicate = predicates.isList;
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
      check = v: isAttrs v && all subtype.check (builtins.attrValues v);
      validate = value: let
        validated = generators.validate {
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
      default = builtins.head values;
      description = "One of: ${concatStringsSep ", " (map toString values)}";
    };

    # Submodule with nested schema
    submodule = schema: {
      type = "submodule";
      inherit schema;
      check = isAttrs;
      validate = value: validateSchema schema value;
      default = extractDefaults schema;
      description = "A submodule with fields: ${concatStringsSep ", " (builtins.attrNames schema)}";
    };

    # Either type (union)
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

    # One-of multiple types
    oneOf = types: {
      type = "oneOf";
      inherit types;
      check = v: builtins.any (t: t.check v) types;
      validate = value: let
        matches = builtins.filter (t: t.check value) types;
      in
        if matches == []
        then throw "type.oneOf: no matching type for value ${generators.showValue value}"
        else (builtins.head matches).validate value;
      default = (builtins.head types).default;
      description = "One of: ${concatStringsSep " | " (map (t: t.description or t.type) types)}";
    };

    # Any type (no validation)
    any = {
      type = "any";
      check = _: true;
      validate = value: value;
      default = null;
      description = "Any value";
    };

    # Lazy type (for recursive structures)
    lazy = schemaFn: {
      type = "lazy";
      schemaFn = schemaFn;
      check = isAttrs;
      validate = value: validateSchema (schemaFn {}) value;
      default = null;
      description = "A lazily evaluated submodule";
    };

    # String with constraints
    strMatching = pattern: {
      type = "strMatching";
      inherit pattern;
      check = v: predicates.isString v && builtins.match pattern v != null;
      validate = value:
        if predicates.isString value && builtins.match pattern value != null
        then value
        else throw "type.strMatching: string must match pattern '${pattern}', got '${value}'";
      default = "";
      description = "A string matching pattern '${pattern}'";
    };

    # Integer with constraints
    intBetween = min: max: {
      type = "intBetween";
      inherit min max;
      check = v: predicates.isInt v && v >= min && v <= max;
      validate = value:
        if predicates.isInt value && value >= min && value <= max
        then value
        else throw "type.intBetween: integer must be between ${toString min} and ${toString max}, got ${toString value}";
      default = min;
      description = "An integer between ${toString min} and ${toString max}";
    };

    # Non-empty list
    nonEmptyListOf = subtype: {
      type = "nonEmptyListOf";
      subtype = subtype;
      check = v: predicates.isList v && v != [] && all subtype.check v;
      validate = value: let
        validated = generators.validate {
          fnName = "type.nonEmptyListOf";
          argName = "value";
          desired = "list";
          predicate = v: predicates.isList v && v != [];
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
      check = v: predicates.isInt v && v > 0;
      validate = value:
        if predicates.isInt value && value > 0
        then value
        else throw "type.positiveInt: must be a positive integer, got ${toString value}";
      default = 1;
      description = "A positive integer";
    };

    # Non-negative integer
    nonNegativeInt = {
      type = "nonNegativeInt";
      check = v: predicates.isInt v && v >= 0;
      validate = value:
        if predicates.isInt value && value >= 0
        then value
        else throw "type.nonNegativeInt: must be non-negative, got ${toString value}";
      default = 0;
      description = "A non-negative integer";
    };
  };

  # ============================================================================
  # SCHEMA UTILITIES
  # ============================================================================

  # Extract default values from a schema
  extractDefaults = schema:
    mapAttrs (
      _name: spec:
        if spec ? default
        then spec.default
        else if spec.type == "submodule"
        then extractDefaults spec.schema
        else if spec.type == "lazy"
        then null
        else null
    )
    schema;

  # Validate a single field
  validateField = name: value: spec:
    if spec ? validate
    then spec.validate value
    else if spec.check value
    then value
    else throw "Field '${name}': validation failed for type ${spec.type}";

  # Validate entire config against schema
  validateSchema = schema: config: let
    # Check for unknown keys
    schemaKeys = builtins.attrNames schema;
    configKeys = builtins.attrNames config;
    unknownKeys = builtins.filter (k: !elem k schemaKeys) configKeys;

    # Validate each field
    validated =
      mapAttrs (
        name: spec:
          if config ? ${name}
          then validateField name config.${name} spec
          else if spec ? default
          then spec.default
          else throw "Required field '${name}' is missing"
      )
      schema;
  in
    if unknownKeys != []
    then throw "Unknown fields: ${concatStringsSep ", " unknownKeys}"
    else validated;

  # Apply defaults from schema to config
  applyDefaults = schema: config:
    recursiveUpdate (extractDefaults schema) config;

  # Soft validation (returns result object instead of throwing)
  validateSoft = schema: config: let
    results =
      mapAttrs (
        name: spec:
          if config ? ${name}
          then
            if spec.check config.${name}
            then {
              success = true;
              value = config.${name};
            }
            else {
              success = false;
              error = "Field '${name}': expected ${spec.description or spec.type}";
            }
          else if spec ? default
          then {
            success = true;
            value = spec.default;
          }
          else {
            success = false;
            error = "Required field '${name}' is missing";
          }
      )
      schema;

    errors = builtins.filter (r: !r.success) (builtins.attrValues results);
  in
    if errors == []
    then {
      success = true;
      data = mapAttrs (name: _: results.${name}.value) schema;
    }
    else {
      success = false;
      errors = map (e: e.error) errors;
    };

  # Merge multiple schemas
  mergeSchemas = schemas:
    builtins.foldl' recursiveUpdate {} schemas;

  # Make all fields optional
  makeOptional = schema:
    mapAttrs (_name: spec: t.nullOr spec) schema;

  # Make specific fields required (remove nullOr wrapper)
  makeRequired = fields: schema:
    mapAttrs (
      name: spec:
        if elem name fields && spec.type == "nullOr"
        then spec.subtype
        else spec
    )
    schema;

  # ============================================================================
  # COMMON PATTERNS
  # ============================================================================

  patterns = {
    # Email-like string
    email = t.strMatching "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}";

    # URL-like string
    url = t.strMatching "https?://.*";

    # Semantic version
    semver = t.strMatching "[0-9]+\\.[0-9]+\\.[0-9]+.*";

    # Git reference (branch, tag, commit)
    gitRef = t.str;

    # Username (alphanumeric with underscores/hyphens)
    username = t.strMatching "[a-zA-Z0-9_-]+";

    # Hostname
    hostname = t.strMatching "[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*";

    # IPv4 address
    ipv4 = t.strMatching "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}";

    # Color hex code
    color = t.strMatching "#[0-9a-fA-F]{6}";

    # UUID
    uuid = t.strMatching "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}";
  };

  # ============================================================================
  # INTEGRATION WITH YOUR EXISTING SYSTEM
  # ============================================================================

  # Wrap your existing validate function with type specs
  mkTypedFunction = {
    name,
    args, # { argName = typeSpec; ... }
    impl,
  }: namedArgs: let
    # Validate all arguments
    validated =
      mapAttrs (
        argName: value:
          if args ? ${argName}
          then
            generators.validate {
              fnName = name;
              inherit argName;
              desired = args.${argName}.type;
              predicate = args.${argName}.check;
              outcome = value;
            }
          else throw "${name}: unexpected argument '${argName}'"
      )
      namedArgs;
  in
    impl validated;
in {
  inherit t patterns;
  inherit extractDefaults validateSchema validateSoft applyDefaults;
  inherit mergeSchemas makeOptional makeRequired;
  inherit mkTypedFunction;

  # Re-export your existing utilities
  inherit (predicates) typeOf isAttrs isBool isInt isFloat;
  inherit (generators) mkError validate showValue;

  _rootAliases = {
    types = t;
    typePatterns = patterns;
    validateType = validateSchema;
    applyTypeDefaults = applyDefaults;
  };
}
