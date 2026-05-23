{_, ...}: let
  meta = let
    doc = ''
      Source registry construction helpers.

      This layer turns a normalized registry source into a reusable registry
      object with seed merging, lookup helpers, and light-weight analysis.
      It is intentionally generic so application registries, style registries,
      and future registry types can all build on the same source/seed contract.

      Depends on: sources.registry.resolution.
    '';

    exports = let
      internal = let
        functions = {
          inherit
            flatten
            mkAnalysis
            mkRegistry
            normalizeList
            ;
        };
        aliases = {
          mkRegistrySet = mkRegistry;
          mkRegistryAnalysis = mkAnalysis;
        };
      in
        {inherit functions aliases;} // functions // aliases;

      external = {
        inherit
          mkAnalysis
          mkRegistry
          ;
      };
    in {inherit internal external;};
  in {inherit doc exports;};

  inherit (_.attrsets.access) attrNames attrValues getAttr;
  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.attrsets.construction) listToAttrs;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs;
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.lists.aggregation) foldl';
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.strings.construction) concat;
  inherit (_.strings.transformation) wrap;
  inherit (_.types.predicates) isAttrs isString;
  inherit (_.sources.registry.resolution)
    lookup
    mkSource
    normalize
    ;

  /**
    Normalize a list-like input into a filtered list.
  */
  normalizeList = values:
    if builtins.isList values
    then filter (value: value != null && value != {}) values
    else [values];

  /**
    Flatten a one-level registry of nested attrsets.

    This is useful for registry structures grouped by namespace.
  */
  flatten = registry:
    foldl' (acc: namespace: acc // registry.${namespace}) {} (attrNames registry);

  /**
    Produce light-weight analysis groups for a flat registry attrset.

    `groupBy` and `queryBy` are lists of entry field names. For each field,
    this returns an attrset keyed by distinct field values.
  */
  mkAnalysis = {
    owner ? "mkAnalysis",
    entries,
    groupBy ? [],
    queryBy ? [],
  }: let
    entries' =
      if isAttrs entries && entries ? value && isAttrs entries.value
      then entries.value
      else entries;

    entryValues = attrValues entries';

    fieldValues = field:
      unique (filter isString (map (entry: entry.${field} or null) entryValues));

    groupByField = field:
      listToAttrs (
        map (
          value: {
            name = value;
            value = filterAttrs (_: entry: (entry.${field} or null) == value) entries';
          }
        )
        (fieldValues field)
      );

    mkGroupSet = fields:
      listToAttrs (
        map (
          field: {
            name = field;
            value = groupByField field;
          }
        )
        (unique (filter isString fields))
      );
  in {
    groups = mkGroupSet groupBy;
    queries = mkGroupSet queryBy;
  };

  /**
    Build a reusable registry object from a source record and seed data.

    The source's `value` is deep-merged with `seed` so the registry can be
    pre-populated or overridden by callers. The returned object exposes the
    merged `entries`, `lookup`, and a generic `normalize` helper.
  */
  mkRegistry = {
    owner ? "mkRegistry",
    source,
    seed ? {},
    groupBy ? [],
    queryBy ? [],
    ...
  }: let
    source' = normalize source;
    entries = recursiveUpdate seed (source'.value or source'.raw or {});
    analysis = mkAnalysis {
      inherit
        entries
        groupBy
        owner
        queryBy
        ;
    };

    lookupEntry = args@{
      default ? null,
      ...
    }:
      lookup (
        {
          registry = entries;
          inherit default;
        }
        // args
      );

    normalizeEntry = value:
      if isAttrs value && (value ? raw || value ? value || value ? path || value ? name)
      then {
        name = value.name or null;
        path = value.path or null;
        raw = value.raw or (value.value or value);
        value = value.value or value.raw or value;
      }
      else if isString value
      then {
        name = value;
        path = null;
        raw = value;
        value = value;
      }
      else {
        name = null;
        path = null;
        raw = value;
        value = value;
      };
  in {
    inherit
      analysis
      entries
      lookupEntry
      normalizeEntry
      owner
      seed
      source'
      ;
    name = source'.name;
    path = source'.path;
    raw = source'.raw;
    value = entries;
    lookup = lookupEntry;
    normalize = normalizeEntry;
    groups = analysis.groups;
    queries = analysis.queries;
  };
in
  with meta.exports;
    internal
    // {
      __rootAliases = external;
      __docs = meta.doc;
    }
