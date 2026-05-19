{_, ...}: let
  meta = let
    doc = ''
      Style registry data (Layer 0).

      Provides normalized style records from `./data`, with consistent
      `categories` fields. Supplies primitive tree inspection for recursive
      processing, validated registry lookup, registry-derived identification
      metadata, and shared resolver helpers used by higher style layers.

      Depends on: filesystem.importers.
    '';
    functions = {
      inherit
        mkFilters
        normalizeList
        importRegistry
        isRegistryAttrset
        lookup
        mkRegistry
        mkPolarity
        normalize
        mkData
        ;
    };
    exports = {
      local = functions // data.seed;
      alias = {};
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.attrsets.access) attrNames attrValues getAttr;
  inherit (_.attrsets.construction) genAttrs listToAttrs;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs;
  inherit (_.content.emptiness) isEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.filesystem.importers) importRegistry;
  inherit (_.lists.access) elemAt head length;
  inherit (_.lists.aggregation) concatMap foldl';
  inherit (_.lists.construction) optionals;
  inherit (_.lists.predicates) elem isList isIn;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.strings.transformation) toLowerCase;
  inherit (_.types.access) typeOf;
  inherit (_.types.predicates) isAttrs isFunction isString;

  normalizeList = values:
    optionals (isList values) (filter (value: value != null && value != "") values);

  mkRegistry = {
    group,
    entries,
  }: let
    names = attrNames entries;

    aliases =
      foldl'
      (
        acc: value:
          acc
          // {${toLowerCase value} = value;}
          // listToAttrs (
            map
            (name: {inherit name value;})
            (
              map
              toLowerCase
              (entries.${value}.aliases or [])
            )
          )
      )
      {}
      names;

    lookup' = input: let
      fn = {
        name = "${group}.lookup";
        context = "looking up ${group}";
      };
      value = toLowerCase input;
      resolved = aliases.${value} or value;
    in
      assert withContext {
        inherit (fn) name context;
        assertion = isIn resolved names;
        message = "unknown ${group} `${input}` - valid: ${toString names}";
      };
        entries.${resolved};
  in {
    inherit entries names aliases;
    lookup = lookup';
  };

  mkPolarity = {
    pair = input: let
      spec =
        if isFunction input
        then {
          fn = input;
          args = [];
        }
        else input;

      fn = assert withContext {
        name = "mkPolarity.pair";
        context = "building polarity pair wrapper";
        assertion =
          isAttrs spec
          && spec ? fn
          && isFunction spec.fn
          && ((spec.args or []) == [] || isList (spec.args or []));
        message = "expected a function or an attrset with `fn` as a function and optional `args` as a list";
      };
        spec.fn;

      allowed = (spec.args or []) ++ ["polarity"];

      validate = args: let
        invalid =
          filter
          (name: !(isIn name allowed))
          (attrNames args);
      in
        assert withContext {
          name = "mkPolarity.pair";
          context = "validating polarity pair arguments";
          assertion = invalid == [];
          message = "unexpected arguments `${toString invalid}` - allowed: ${toString (spec.args or [])}";
        }; args;
    in
      args: let
        checked = validate args;
      in {
        light = fn (checked // {polarity = "light";});
        dark = fn (checked // {polarity = "dark";});
      };

    selection = {
      value,
      polarity,
      group ? "value",
    }: let
      fn = {
        name = "${group}.selectByPolarity";
        context = "selecting ${polarity} ${group} input";
      };

      isConcrete =
        isAttrs value && ((value ? package) || (value ? name));

      isPolarized =
        isAttrs value && !isConcrete;
    in
      if value == null
      then null
      else if isString value
      then value
      else if isList value
      then
        assert withContext {
          inherit (fn) name context;
          assertion = length value == 2;
          message = "list input must have exactly 2 elements [darkVal lightVal], got ${toString (length value)}";
        };
          if polarity == "dark"
          then elemAt value 0
          else elemAt value 1
      else if isConcrete
      then value
      else if isPolarized
      then
        assert withContext {
          inherit (fn) name context;
          assertion = builtins.hasAttr polarity value;
          message = "${group} attrset input is missing `${polarity}` key";
        };
          getAttr polarity value
      else
        assert withContext {
          inherit (fn) name context;
          assertion = false;
          message = "expected null, string, list, or attrset, got `${typeOf value}`";
        }; null;
  };

  normalize = {
    value,
    polarity,
    resolver,
    group ? "value",
    fallback ? null,
  }: let
    selected =
      if isEmpty value && fallback != null
      then fallback
      else
        mkPolarity.selection {
          inherit value polarity group;
        };
  in
    if isString selected
    then resolver.lookup selected
    else selected;

  resolveSource = {
    entries ? null,
    groups ? null,
    queries ? null,
    from ? null,
  }: let
    sources =
      filter
      (x: x != null)
      [entries groups queries from];
  in
    assert withContext {
      name = "mkData.resolveSource";
      context = "resolving mkData source";
      assertion = length sources == 1;
      message = "expected exactly one of `entries`, `groups`, `queries`, or `from`";
    };
      if entries != null
      then entries
      else if from != null
      then from
      else if groups != null
      then groups
      else queries;

  mkData = {
    group,
    seed ? {},
    entries ? null,
    groups ? null,
    queries ? null,
    from ? null,
    withFamilies ? true,
  }: let
    source = resolveSource {
      inherit entries groups queries from;
    };

    resolvedEntries = assert withContext {
      name = "mkData";
      context = "constructing data for ${group}";
      assertion = isAttrs source;
      message = "resolved mkData source for `${group}` must be an attrset";
    }; source;

    resolver = mkRegistry {
      inherit group;
      entries = resolvedEntries;
    };

    families =
      if withFamilies
      then {
        byFamily = family:
          filter
          (name: (resolvedEntries.${name}.family or null) == family)
          resolver.names;
      }
      else {};

    normalizeValue = {
      value,
      polarity,
      fallback ? null,
    }:
      normalize {
        inherit value polarity fallback;
        inherit resolver group;
      };
  in {
    entries = resolvedEntries;
    inherit seed resolver families;
    normalize = normalizeValue;
  };

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

  flatRegistry = registry:
    foldl' (acc: ns: acc // registry.${ns}) {} (attrNames registry);

  groupByFieldFlat = field: flat: let
    keys = unique (filter isString (map (e: e.${field} or null) (attrValues flat)));
  in
    genAttrs keys (
      k:
        filterAttrs (_: e: (e.${field} or null) == k) flat
    );

  groupByField = field: registry: let
    allEntries = concatMap (ns: attrValues registry.${ns}) (attrNames registry);
    keys = unique (filter isString (map (e: e.${field} or null) allEntries));
  in
    genAttrs keys (
      k:
        filterAttrs (_: ns: ns != {}) (
          mapAttrs (
            ns: entries':
              filterAttrs (_: e: (e.${field} or null) == k) entries'
          )
          registry
        )
    );

  mkSection = {
    set,
    queries ? {},
  }:
    {all = set;} // queries;

  mkFilters = {
    registry ? data.raw,
    extraGroups ? {},
    extraQueries ? {},
  }: let
    entries' = flatRegistry registry;

    groups' = let
      mk = field: groupByField field registry;
    in
      {
        byCategory =
          genAttrs
          (unique (
            concatMap
            (e: e.categories or [])
            (attrValues entries')
          ))
          (
            category:
              filterAttrs
              (_: e: isIn category (e.categories or []))
              entries'
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
