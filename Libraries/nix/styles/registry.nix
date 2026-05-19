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
        mkFilters
        normalizeList
        importRegistry
        isRegistryAttrset
        lookup
        ;
    };
    exports = {
      local = functions // data.seed;
      alias = {};
    };
  in {inherit doc exports functions;};

  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.construction) genAttrs;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs;
  inherit (_.filesystem.importers) importRegistry;
  inherit (_.lists.access) head;
  inherit (_.lists.aggregation) concatMap foldl';
  inherit (_.lists.construction) optionals;
  inherit (_.lists.predicates) elem isList isIn;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.types.predicates) isAttrs isString;

  normalizeList = values: optionals (isList values) filter (value: value != null && value != "") values;

  data = {
    raw = importRegistry ./.;
    seed = mkFilters {};
  };

  isRegistryAttrset = tree:
    (tree != {})
    && (
      let
        firstVal = head (attrValues tree);
      in
        isAttrs firstVal && firstVal ? categories
    );

  lookup = name: category: let
    entry = data.raw.${name} or (throw "Unknown style entry '${name}' in registry.");
  in
    if elem category (entry.categories or [])
    then entry
    else throw "'${name}' does not satisfy category '${category}'. Its categories: ${toString (entry.categories or [])}";

  #  Helpers

  # Merge all namespace attrsets into one flat key→entry attrset.
  # Used for byCategory/byPolarity where cross-namespace collision is acceptable
  # (categories and polarity values don't collide with entry keys).
  flatRegistry = registry:
    foldl' (acc: ns: acc // registry.${ns}) {} (attrNames registry);

  # Group a flat set by a scalar field.
  # Output: { fieldVal = { key = entry } }
  groupByFieldFlat = field: flat: let
    keys = unique (filter isString (map (e: e.${field} or null) (attrValues flat)));
  in
    genAttrs keys (
      k:
        filterAttrs (_: e: (e.${field} or null) == k) flat
    );

  # Group a namespaced registry by a scalar field, preserving namespace.
  # Output: { fieldVal = { ns = { key = entry } } }
  # Empty namespaces are dropped from each group.
  groupByField = field: registry: let
    allEntries = concatMap (ns: attrValues registry.${ns}) (attrNames registry);
    keys = unique (filter isString (map (e: e.${field} or null) allEntries));
  in
    genAttrs keys (
      k:
        filterAttrs (_: ns: ns != {}) (
          mapAttrs (
            ns: entries:
              filterAttrs (_: e: (e.${field} or null) == k) entries
          )
          registry
        )
    );

  #  mkSection

  mkSection = {
    set,
    queries ? {},
  }:
    {all = set;} // queries;

  #  mkFilters

  mkFilters = {
    registry ? data.raw,
    extraGroups ? {},
    extraQueries ? {},
  }: let
    entries = flatRegistry registry;

    groups' = let
      mk = field: groupByField field registry;
    in
      {
        byCategory =
          genAttrs (unique (
            concatMap
            (e: e.categories or [])
            (attrValues entries)
          ))
          (
            category:
              filterAttrs
              (_: e: isIn category (e.categories or []))
              entries
          );
        byFamily = mk "family";
        byPolarity = mk "polarity";
      }
      // extraGroups;

    queries' = let
      mk = {byCategory, ...}:
        filterAttrs (_: section: section.all != {}) (
          mapAttrs (
            name: set:
              mkSection {
                inherit set;
                queries = filterAttrs (_: v: v != {}) {
                  hasAliases = filterAttrs (_: e: (e.aliases or []) != []) set;
                  noAliases = filterAttrs (_: e: (e.aliases or []) == []) set;
                  hasPackage = filterAttrs (_: e: (e.package or null) != null) set;
                  hasVariant = filterAttrs (_: e: e ? variant) set;
                  hasNames = filterAttrs (_: e: e ? names) set;
                  byFamily = groupByFieldFlat "family" set;
                  byPolarity = groupByFieldFlat "polarity" set;
                };
              }
          )
          byCategory
        );
    in
      (mk groups') // extraQueries;
  in {
    entries = registry;
    groups = groups';
    queries = queries';
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
