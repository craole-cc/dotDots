{
  _,
  __moduleRef,
  __modulePath,
  __moduleFile,
  __moduleName,
  ...
}: let
  meta = let
    doc = ''
      Source registry I/O helpers.

      Exposes the low-level registry importer used to read source trees into
      attribute sets for higher source-registry layers.

      Depends on: filesystem.importers.importRegistry.

    '';

    exports = let
      internal = {
        inherit __moduleRef __modulePath __moduleName;
        ref = __moduleRef;
        path = __modulePath;
        name = __moduleName;
        file = __moduleFile;
      };
      # internal = registry // {inherit __moduleRef __modulePath __moduleName;};
      external = {registryOfStyles = registry;};
    in {inherit internal external;};
  in {inherit doc exports;};

  registry = _.sources.registry.io.import ./.;
in
  with meta.exports;
    internal
    // {
      __rootAliases = external;
      __docs = meta.doc;
    }
