{_, ...}: let
  meta = let
    doc = ''
      Source registry I/O helpers.

      Exposes the low-level registry importer used to read source trees into
      attribute sets for higher source-registry layers.

      Depends on: filesystem.importers.importRegistry.

    '';

    exports = let
      internal = registry;
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
