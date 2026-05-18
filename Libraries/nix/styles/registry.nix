{_, ...}: let
  meta = let
    doc = ''
      Style registry data (Layer 0).

      Provides normalized style records from `./data`, with consistent
      `categories` (list) fields. Supplies primitive tree inspection for
      recursive processing, validated registry lookup, and registry-derived
      identification metadata.

      Depends on: filesystem.importers.
    '';
    functions = {
      inherit
        entries
        mkRegistry
        importRegistry
        isRegistryAttrset
        lookup
        ;
    };
    exports = {
      local = functions;
      alias = {};
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.attrsets.access) attrValues;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.filesystem.importers) importRegistry;
  inherit (_.lists.access) head;
  inherit (_.lists.predicates) elem isList;
  inherit (_.lists.selection) filter;
  inherit (_.types.predicates) isAttrs;

  normalizeList = values:
    if isList values
    then filter (value: value != null && value != "") values
    else [];

  # mkRegistry = data:
  #   mapAttrs (
  #     section: set:
  #       mapAttrs (
  #         _: entry:
  #           entry
  #           // {
  #             categories = normalizeList ((entry.categories or []) ++ [section]);
  #           }
  #       )
  #       set
  #   )
  #   data;
  # importRegistry = path: mkRegistry (importAllMerged path {});
  entries = importRegistry {root = ./.;};

  isRegistryAttrset = tree:
    (tree != {})
    && (
      let
        firstVal = head (attrValues tree);
      in
        isAttrs firstVal && firstVal ? categories
    );

  lookup = name: category: let
    entry = entries.${name} or (throw "Unknown style entry '${name}' in registry.");
  in
    if elem category (entry.categories or [])
    then entry
    else throw "'${name}' does not satisfy category '${category}'. Its categories: ${toString (entry.categories or [])}";
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
