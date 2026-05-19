{_, ...}: let
  meta = let
    doc = ''
      mkFilters — builds a structured filter/query surface over a registry.

      Groups auto-generated:
        byCategory — entries grouped by each category string
        byFamily   — entries grouped by family field
        byPolarity — entries grouped by polarity (string only; attrset polarity skipped)
    '';
    exports = {
      local = { inherit mkFilters; };
      alias = {};
    };
  in { inherit doc exports; };

  inherit (builtins)
    attrNames attrValues concatMap elem filter foldl'
    genAttrs isString mapAttrs unique;
  inherit (_.attrsets) filterAttrs;

  # Flatten registry into a list of entries
  allEntries = registry:
    concatMap
      (ns: map (key: registry.${ns}.${key}) (attrNames registry.${ns}))
      (attrNames registry);

  # Generic group-by: extract a scalar key from each entry, skip nulls
  groupBy = keyFn: entries:
    let
      keys = unique (filter (k: k != null) (map keyFn entries));
    in
      genAttrs keys (k:
        foldl' (acc: entry:
          if keyFn entry == k
          then acc // { ${entry._key or (throw "entry missing _key")} = entry; }
          else acc
        ) {} entries
      );

  # Actually we want to work at the registry namespace level to preserve keys.
  # Build a flat attrset of key→entry from a registry, then group.
  flatRegistry = registry:
    foldl' (acc: ns:
      acc // registry.${ns}
    ) {} (attrNames registry);

  groupByField = field: flat:
    let
      entries   = attrValues flat;
      keys      = unique (filter isString (map (e: e.${field} or null) entries));
    in
      genAttrs keys (k:
        filterAttrs (_: e: (e.${field} or null) == k) flat
      );

  mkFilters = { registry, groups ? {}, queries ? (_: {}) }: let
    flat          = flatRegistry registry;
    entries       = attrValues flat;

    # ── byCategory ──────────────────────────────────────────────────────────
    allCategories = unique (concatMap (e: e.categories or []) entries);
    byCategory    = genAttrs allCategories (category:
      filterAttrs (_: e: elem category (e.categories or [])) flat
    );

    # ── byFamily ─────────────────────────────────────────────────────────────
    byFamily = groupByField "family" flat;

    # ── byPolarity (string only) ─────────────────────────────────────────────
    byPolarity =
      let
        polarityKeys = unique (filter isString (map (e: e.polarity or null) entries));
      in
        genAttrs polarityKeys (pol:
          filterAttrs (_: e: isString (e.polarity or null) && e.polarity == pol) flat
        );

    autoGroups = { inherit byCategory byFamily byPolarity; };
  in {
    default = registry;
    groups  = autoGroups // groups;
    queries = queries (autoGroups // groups);
  };

in meta.exports.local // { __docs = meta.doc; __rootAliases = meta.exports.alias; }
