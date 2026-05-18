{_, ...}: let
  meta = let
    doc = ''
      Style filters (Layer 4).

      Partitions the style registry into typed, queryable subsets.
      Each top-level key maps to a domain section exposing
      { all, default, groups, queries } via mkSection.

      Also provides fuzzy `lookup` - resolves a name or alias to a
      { key, entry } pair by searching the filtered registry subset.

      Top-level queries:
        icons    - icon themes
        cursors  - cursor themes
        flavors  - catppuccin flavors
        accents  - catppuccin accents

      Depends on: style.registry.
    '';
    functions = {
      inherit lookup mkFilters mkSection;
    };
    aliases = {
      mkStyleFilterSection = mkSection;
      toStyleFilters = mkFilters;
      lookupStyle = lookup;
    };
    exports = {
      local = default // functions // aliases;
      alias = aliases;
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.construction) genAttrs;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.content.emptiness) isEmpty isNotEmpty;
  inherit (_.lists.access) findFirst;
  inherit (_.lists.aggregation) concatMap;
  inherit (_.lists.predicates) elem isIn isList;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;

  registry = _.styles.registry.entries;

  default = mkFilters {
    inherit registry;
    queries = {byCategory, ...}: let
      icons = mkSection {set = byCategory.icons or {};};
      cursors = mkSection {set = byCategory.cursors or {};};
      flavors = mkSection {set = byCategory.flavors or {};};
      accents = mkSection {set = byCategory.accents or {};};
    in {
      inherit icons cursors flavors accents;
    };
  };

  keysFromMembers = field: set:
    unique (
      concatMap (entry: let
        val = entry.${field} or [];
      in
        if isList val
        then val
        else [])
      (attrValues set)
    );

  mkSection = {
    set,
    groupArgs ? {},
    queryArgs ? {},
  }: {
    all = set;
    default = set;
    groups = {};
    queries = {};
  };

  mkFilters = {
    registry,
    groups ? {},
    queries ? (_: {}),
  }: let
    byCategory =
      genAttrs
      (keysFromMembers "categories" registry)
      (category: filterAttrs (_: entry: isIn category (entry.categories or [])) registry);
    ofCategory = category: byCategory.${category} or {};
  in {
    default = registry;
    groups = {inherit byCategory ofCategory;} // groups;
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
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
