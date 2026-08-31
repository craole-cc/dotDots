{...} @ args: let
  paths = {
    api = ./API/nix;
    lib = ./Libraries/nix;
  };

  _ =
    (import paths.lib (
      removeAttrs args ["schema" "host"]
    )).libraries.default;

  inherit (_.filesystem.traversal) importAttrs;
  inherit (_.schema.construction) mkSchema;

  api = (importAttrs paths.api).value;
  schema = mkSchema {inherit api args;};
in
  import paths.lib (args // {inherit schema;})
