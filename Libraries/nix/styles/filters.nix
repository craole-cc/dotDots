{_, ...}: let
  meta = let
    doc = ''
      Style filters (Layer 4).

      Partitions the style registry into typed, queryable subsets.
      Each top-level key maps to a domain section exposing
      { all, default, groups, queries } via mkSection.

      Top-level queries:
        icons    - icon themes
        cursors  - cursor themes
        flavors  - catppuccin flavors
        accents  - catppuccin accents

      Depends on: styles.registry.
    '';
    functions = {
      inherit
        lookup
        mkFilters
        mkSection
        ;
      mkFilterSection = mkSection;
    };
    exports = {
      local = default // functions;
      alias = {
        toStyleFilters = mkFilters;
        lookupStyle = lookup;
      };
    };
  in {inherit doc exports functions;};

  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.construction) genAttrs;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs;
  inherit (_.content.emptiness) isEmpty isNotEmpty;
  inherit (_.lists.access) findFirst;
  inherit (_.lists.aggregation) concatMap foldl';
  inherit (_.lists.transformation) unique;
  inherit (_.lists.predicates) elem isIn;

  registry = _.styles.registry.entries;

  mkFilters = {
    registry,
    groups ? {},
    queries ? (_: {}),
  }: let
    allEntries =
      concatMap
      (ns: map (key: registry.${ns}.${key}) (attrNames registry.${ns}))
      (attrNames registry);

    allCategories = unique (
      concatMap (entry: entry.categories or []) allEntries
    );

    byCategory = genAttrs allCategories (
      category:
        foldl' (
          acc: ns:
            acc
            // (
              filterAttrs
              (_: entry: elem category (entry.categories or []))
              registry.${ns}
            )
        ) {} (attrNames registry)
    );
  in {
    default = registry;
    groups = {inherit byCategory;} // groups;
    queries = queries {inherit byCategory;};
  };

  registryItems = set:
    map (key: {
      inherit key;
      entry = set.${key};
    }) (attrNames set);

  lookup = name: set: let
    items = registryItems set;
    byKey =
      if set ? ${name}
      then {
        inherit name;
        key = name;
        entry = set.${name};
      }
      else null;
    byAlias =
      findFirst
      (item: elem name (item.entry.aliases or item.entry.names.aliases or []))
      null
      items;
  in
    if isEmpty name
    then null
    else if isNotEmpty byKey
    then byKey
    else byAlias;

  mkSection = {
    set,
    groups ? {},
    queries ? {},
  }: let
    # Only include queries that actually return non-empty sets
    activeQueries = filterAttrs (_: v: v != {}) queries;
  in {
    all = set;
    inherit groups;
    queries = activeQueries;
  };

  default = mkFilters {
    inherit registry;
    queries = {byCategory, ...}:
      filterAttrs (_: section: section.all != {}) (
        mapAttrs (name: set:
          mkSection {
            inherit set;
            queries = filterAttrs (_: v: v != {}) {
              hasAliases = filterAttrs (_: e: (e.aliases or e.names.aliases or []) != []) set;
              noAliases = filterAttrs (_: e: (e.aliases or e.names.aliases or []) == []) set;
              hasPackage = filterAttrs (_: e: (e.names.package or null) != null) set;
              hasVariant = filterAttrs (_: e: e ? variant) set;
              hasNames = filterAttrs (_: e: e ? names) set;
            };
          }) (filterAttrs (name: _: name != "catppuccin") byCategory)
      );
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
