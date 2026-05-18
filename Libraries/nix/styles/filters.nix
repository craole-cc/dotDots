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
  in {
    inherit doc exports functions;
  };

  inherit (_.attrsets.access) attrNames;
  inherit (_.content.emptiness) isEmpty isNotEmpty;
  inherit (_.lists.access) findFirst;
  inherit (_.lists.predicates) elem;

  registry = _.styles.registry.entries;

  mkSection = {
    set,
    groups ? {},
    queries ? {},
  }: {
    all = set;
    default = set;
    inherit groups queries;
  };

  mkFilters = {registry}: {
    default = registry;
    groups = {};
    queries = {
      icons = mkSection {set = registry.icons or {};};
      cursors = mkSection {set = registry.cursors or {};};
      flavors = mkSection {set = registry.flavors or {};};
      accents = mkSection {set = registry.accents or {};};
    };
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

  default = mkFilters {inherit registry;};
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
