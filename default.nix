{...} @ args: let
  paths.core = {
    src.store = args.paths.src.store or ./.;
    api.default.store = args.paths.api.default.store or ./API/nix;
    lib.default.store = args.paths.lib.default.store or ./Libraries/nix;
  };

  init =
    import paths.core.lib.default.store
    (args // {inherit paths;});

  schema =
    init.libraries.default.schema.construction.mkSchema
    {inherit args;};

  eval =
    import paths.core.lib.default.store
    (args // {inherit paths schema;});
in
  eval
