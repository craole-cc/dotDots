{_, ...}: let
  meta = let
    doc = ''
      Source registry I/O helpers.

      Provides the reusable filesystem importer used by higher-level source
      registry libraries. This layer stays intentionally small: it exposes the
      importer with a predictable name and keeps the rest of the registry logic
      in the construction/resolution helpers.

      Depends on: filesystem.importers.importRegistry.
    '';

    exports = let
      internal = let
        functions = {inherit importRegistry;};
        aliases = {
          import = importRegistry;
          read = importRegistry;
        };
      in
        {inherit functions aliases;} // functions // aliases;

      external = {inherit importRegistry;};
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
