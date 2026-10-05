{lix, ...}: let
  inherit (lix.attrsets) attrNames mapAttrs;
  inherit (lix.lists) filter;
  inherit (lix.debug) requireThat;

  deriveApplications = {
    default,
    defined,
  }: let
    args = defined.applications or {};
    names = attrNames args;
    unknown =
      filter
      (name: !(default.applications ? ${name}))
      names;
    context = "deriveApplications";
  in
    assert requireThat {
      inherit context;
      condition = unknown == [];
      message = "unknown application roles: ${toString unknown}";
    }; args;

  fields = {
    declare = fields: mapAttrs (_: field: field.default) fields;
    resolve = domain: fields: mapAttrs (_: field: field.resolve domain) fields;
  };
in {
  inherit
    deriveApplications
    # deriveFunctionalities
    # resolveUserPackages
    # expandName
    # resolveNames
    # expandNames
    # fields
    ;
  #? Re-exported under their own names, since the public spelling
  #? (`resolveFields`/`declareFields`) differs from the private one.
  resolveFields = fields.resolve;
  declareFields = fields.declare;
}
