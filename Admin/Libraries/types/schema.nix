# Libraries/types/schema.nix
# Advanced type system that bridges predicates, generators, and schema validation
{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) attrNames attrValues mapAttrs recursiveUpdate;
  inherit (lib.lists) elem filter foldl';
  inherit (lib.strings) concatStringsSep;
  inherit (lib.types) nullOr;
  inherit (_.types) generators;

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
  validate = schema: config: let
    # Check for unknown keys
    schemaKeys = attrNames schema;
    configKeys = attrNames config;
    unknownKeys = filter (k: !elem k schemaKeys) configKeys;
  in
    if unknownKeys != []
    then throw "Unknown fields: ${concatStringsSep ", " unknownKeys}"
    else
      mapAttrs (
        name: spec:
          if config ? ${name}
          then validateField name config.${name} spec
          else if spec ? default
          then spec.default
          else throw "Required field '${name}' is missing"
      )
      schema;

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

    errors = filter (r: !r.success) (attrValues results);
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
    foldl' recursiveUpdate {} schemas;

  # Make all fields optional
  makeOptional = schema:
    mapAttrs (_name: spec: nullOr spec) schema;

  # Make specific fields required (remove nullOr wrapper)
  makeRequired = fields: schema:
    mapAttrs (
      name: spec:
        if elem name fields && spec.type == "nullOr"
        then spec.subtype
        else spec
    )
    schema;

  mkFunction = {
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
  inherit
    applyDefaults
    extractDefaults
    makeOptional
    makeRequired
    mergeSchemas
    mkFunction
    validate
    validateSoft
    validateField
    ;

  _rootAliases = {
    validateSchema = validate;
    applyTypeDefaults = applyDefaults;
    mkTypedFunction = mkFunction;
  };
}
