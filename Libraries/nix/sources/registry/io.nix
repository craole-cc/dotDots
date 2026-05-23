{_, ...}: let
  meta = let
    doc = ''
      Source registry I/O helpers.

      Exposes the low-level registry importer used to read source trees into
      attribute sets for higher source-registry layers.

      Depends on: filesystem.importers.importRegistry.

    '';

    exports = let
      internal = let
        functions = {import = importRegistry;};
        aliases = {inherit importRegistry;};
      in
        {inherit functions aliases;} // functions // aliases;

      external = {inherit (internal) importRegistry;};
    in {inherit internal external;};
  in {inherit doc exports;};

  inherit (_.filesystem.importers) importRegistry;
in
  with meta.exports;
    internal
    // {
      __rootAliases = external;
      __docs = meta.doc;
    }
