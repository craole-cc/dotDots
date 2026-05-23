{
  _,
  __moduleDirectory,
  ...
}: let
  meta = let
    doc = ''
      Style registry namespace entrypoint.

      Imports the style subtree and exposes it as a registry namespace for the
      library assembly.

      Depends on: sources.registry.io.importRegistry.
    '';

    exports = let
      aliases = {"${alias}" = registry;};
      internal = registry // {inherit title;};
      external = aliases;
    in {inherit internal external;};
  in {inherit doc exports;};

  inherit (_.strings.transformation) toCamel toTitle;

  registry = _.sources.registry.io.import ./.;
  label = ["registry" "of" __moduleDirectory];
  alias = toCamel label;
  title = toTitle label;
in
  with meta.exports;
    internal
    // {
      __rootAliases = external;
      __docs = meta.doc;
    }
