{
  _,
  __moduleDirectory,
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
      aliases = {"${alias}" = registry;};
      internal = registry // {inherit title;};
      external = aliases;
    in {inherit internal external;};
  in {inherit doc exports;};

  inherit (_.strings.transformation) toCamel toTitle;

  registry = _.sources.registry.io.import ./.;
  label = ["registy" "of" __moduleDirectory];
  alias = toCamel label;
  title = toTitle label;
in
  with meta.exports;
    internal
    // {
      __rootAliases = external;
      __docs = meta.doc;
    }
