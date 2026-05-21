{_, ...}: let
  meta = let
    doc = ''
      Style registry data (Layer 0).

      Provides normalized style records from `./data`, with consistent
      `categories` fields. Supplies primitive tree inspection for recursive
      processing, validated registry lookup, registry-derived identification
      metadata, and shared resolution helpers used by higher style layers.

      Depends on: filesystem.importers.
    '';
    functions = {
      inherit
        normalizeList
        flatten
        importRegistry
        isRegistry
        lookupByCategory
        mkRegistry
        mkPolarity
        mkData
        ;
    };
    exports = {
      local = functions // {inherit raw data;};
      alias = {};
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.attrsets.access) attrNames attrValues getAttr;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.attrsets.construction) genAttrs listToAttrs;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs;
  inherit (_.content.emptiness) isEmpty isNotEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.filesystem.importers) importRegistry;
  inherit (_.lists.access) elemAt head length;
  inherit (_.lists.aggregation) concatMap foldl';
  inherit (_.lists.construction) optionals toList;
  inherit (_.lists.predicates) isList isIn;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.strings.construction) concat optionalString;
  inherit (_.strings.transformation) toTitleCase wrap;
  inherit (_.types.access) typeOf;
  inherit (_.types.predicates) isAttrs isFunction isString;

  normalizeList = values:
    optionals
    (isList values)
    (filter (value: isNotEmpty value) values);

  flatten = registry:
    foldl' (acc: ns: acc // registry.${ns}) {} (attrNames registry);

  groupByFieldFlat = {
    entries,
    field,
  }: let
    entries' = flatten entries;
    keys = unique (filter isString (
      map (entry: entry.${field} or null) (attrValues entries')
    ));
  in
    genAttrs keys (
      key:
        filterAttrs
        (_: entry: (entry.${field} or null) == key)
        entries'
    );

  groupByField = field: registry: let
    entries =
      concatMap
      (domain: attrValues registry.${domain})
      (attrNames registry);

    keys =
      unique
      (filter isString (map (entry: entry.${field} or null) entries));
  in
    genAttrs keys (
      key:
        filterAttrs
        (_: domain: isNotEmpty domain)
        (
          mapAttrs
          (
            _: entries':
              filterAttrs
              (_: entry: (entry.${field} or null) == key)
              entries'
          )
          registry
        )
    );

  mkSection = {
    set,
    queries ? {},
  }:
    {all = set;} // queries;

  isRegistry = tree:
    (tree != {})
    && (
      let
        firstVal = head (attrValues tree);
      in
        isAttrs firstVal && firstVal ? categories
    );

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
        context = concat " " ["building" "polarity" "pair" "wrapper"];
        assertion =
          isAttrs spec
          && spec ? fn
          && isFunction spec.fn
          && ((spec.args or []) == [] || isList (spec.args or []));
        message = concat " " [
          "expected"
          "a function or an attrset with"
          (wrap {
            token = "`";
            input = "fn";
          })
          "as a function and optional"
          (wrap {
            token = "`";
            input = "args";
          })
          "as a list"
        ];
      };
        spec.fn;

      allowed = (spec.args or []) ++ ["polarity"];

      validate = args: let
        invalid =
          filter
          (argName: !(isIn argName allowed))
          (attrNames args);
      in
        assert withContext {
          name = "mkPolarity.pair";
          context = concat " " ["validating" "polarity" "pair" "arguments"];
          assertion = invalid == [];
          message = concat " " [
            "unexpected arguments"
            (wrap {
              token = "`";
              input = invalid;
              sep = ", ";
            })
            "- allowed:"
            (wrap {
              token = "`";
              input = spec.args or [];
              sep = ", ";
            })
          ];
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
      domain ? "value",
    }: let
      fn = {
        name = concat "." [domain "selectByPolarity"];
        context = concat " " ["selecting" polarity domain "input"];
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
          message = concat " " [
            "list input must have exactly 2 elements"
            (wrap {
              token = "`";
              input = "[darkVal lightVal]";
            })
            "- got"
            (toString (length value))
          ];
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
          assertion = hasAttr polarity value;
          message = concat " " [
            domain
            "attrset input is missing"
            (wrap {
              token = "`";
              input = polarity;
            })
          ];
        };
          getAttr polarity value
      else
        assert withContext {
          inherit (fn) name context;
          assertion = false;
          message = concat " " [
            "expected"
            "null, string, list, or attrset,"
            "got"
            (wrap {
              token = "`";
              input = typeOf value;
            })
          ];
        }; null;
  };

  lookupByCategory = name: category: let
    fn = {
      name = "lookupByCategory";
      context = concat " " [
        "looking up registry entry by category"
      ];
    };

    entry = assert withContext {
      inherit (fn) name context;
      assertion = hasAttr name raw;
      message = concat " " [
        "unknown style entry"
        (wrap {
          token = "`";
          input = name;
        })
        "in registry"
      ];
    };
      raw.${name};
  in
    assert withContext {
      inherit (fn) name context;
      assertion = elem category (entry.categories or []);
      message = concat " " [
        wrap
        {
          token = "`";
          input = name;
        }
        "does not satisfy category"
        (wrap {
          token = "`";
          input = category;
        })
        "- categories:"
        (wrap {
          token = "`";
          input = entry.categories or [];
          sep = ", ";
        })
      ];
    }; entry;

  mkMembers = {
    kind,
    owner,
    available,
    names,
  }: let
    available' =
      if isList available
      then listToAttrs available
      else if isAttrs available
      then available
      else
        assert withContext {
          name = "mkMembers";
          context = concat " " [
            "normalizing"
            kind
            "members for"
            owner
          ];
          assertion = false;
          message = concat " " [
            "expected"
            (wrap {
              token = "`";
              input = "available";
            })
            "as a list of"
            (wrap {
              token = "`";
              input = "{ name, value }";
            })
            "pairs or an attrset"
          ];
        }; {};
  in
    listToAttrs (
      map
      (
        memberName: {
          name = memberName;
          value = assert withContext {
            name = concat "." [owner kind];
            context = concat " " ["selecting" kind memberName "for" owner];
            assertion = hasAttr memberName available';
            message = concat " " [
              "unknown"
              kind
              wrap
              {
                token = "`";
                input = memberName;
              }
              "- valid:"
              (wrap {
                token = "`";
                input = attrNames available';
                sep = ", ";
              })
            ];
          };
            available'.${memberName};
        }
      )
      names
    );

  mkAggregate = {
    owner ? "mkAggregate",
    source,
    kind,
    field ? null,
    fields ? [],
    flatten ? false,
  }: let
    fn = {
      name = concat "." [owner kind];
      context = concat " " ["building" kind "aggregate" "member"];
    };

    dataset = let
      raw = source;
      flat =
        if isRegistry raw
        then flatten raw
        else raw;
    in {inherit raw flat;};

    target =
      unique
      (filter isString ((toList field) ++ fields));

    keyOf = entry:
      concat "::" (
        map
        (fieldName: toString (entry.${fieldName} or ""))
        target
      );

    keys =
      unique
      (filter isNotEmpty (map keyOf (attrValues dataset.flat)));
  in
    assert withContext {
      inherit (fn) name context;
      assertion =
        isAttrs source
        && isIn kind ["group" "query"]
        && isNotEmpty target;
      message = concat " " [
        "expected"
        "a non-empty"
        (wrap {
          token = "`";
          input = ["field" "fields"];
          sep = " or ";
        })
        "input, a valid"
        (wrap {
          token = "`";
          input = "kind";
        })
        ", and an attrset"
        (wrap {
          token = "`";
          input = "source";
        })
      ];
    };
      if flatten
      then
        genAttrs keys (
          key:
            filterAttrs
            (_: entry: keyOf entry == key)
            dataset.flat
        )
      else
        genAttrs keys (
          key:
            filterAttrs
            (_: namespace: namespace != {})
            (
              mapAttrs
              (
                _: entries':
                  filterAttrs
                  (_: entry: keyOf entry == key)
                  entries'
              )
              dataset.raw
            )
        );

  mkMember = args @ {
    kind,
    owner ? "mkMember",
    name ? null,
    value ? null,
    field ? null,
    prefix ? null,
    suffix ? null,
    source ? null,
    flatten ? false,
  }: let
    name' = let
      prefix' = optionalString (isNotEmpty prefix) prefix;
      stem =
        if isNotEmpty name
        then name
        else if isNotEmpty field
        then field
        else "";
      stem' =
        if isEmpty prefix
        then stem
        else toTitleCase stem;
      suffix' = optionalString (isNotEmpty suffix) (toTitleCase suffix);
    in
      concat "" [prefix' stem' suffix'];

    value' =
      if args ? value
      then value
      else mkAggregate {inherit kind owner field source flatten;};
  in
    assert withContext {
      name = concat "." [owner kind];
      context =
        if args ? value
        then concat " " ["building" "explicit" kind "member"]
        else concat " " ["building" "derived" kind "member"];
      assertion = isNotEmpty name';
      message = concat " " [
        "member input requires a non-empty resolved name"
      ];
    }; {
      name = name';
      value = value';
    };

  mkSource = {
    owner ? "mkSource",
    path ? ./.,
    name,
    entries ? null,
    groups ? null,
    queries ? null,
    from ? null,
  }: let
    data = importRegistry path;
    explicit = filter isNotEmpty [entries groups queries from];

    value =
      if length explicit == 0
      then
        assert withContext {
          name = owner;
          context = concat " " ["resolving" "named" "source"];
          assertion =
            isNotEmpty name
            && hasAttr name data;
          message = concat " " [
            "expected"
            (wrap {
              token = "`";
              input = "name";
            })
            "to match a key in"
            (wrap {
              token = "`";
              input = "importRegistry path";
            })
          ];
        };
          getAttr name data
      else
        assert withContext {
          name = owner;
          context = concat " " ["resolving" "explicit" "source"];
          assertion = length explicit == 1;
          message = concat " " [
            "expected at most one of"
            (wrap {
              token = "`";
              input = ["entries" "groups" "queries" "from"];
              sep = ", ";
            })
          ];
        };
          if isNotEmpty entries
          then entries
          else if isNotEmpty from
          then from
          else if isNotEmpty groups
          then groups
          else queries;
  in {
    inherit name value;
  };

  mkRegistry = {
    owner ? "mkRegistry",
    name,
    value,
    seed ? {},
  }: let
    entries = assert withContext {
      name = owner;
      context = concat " " ["constructing" "registry" "for" name];
      assertion = isAttrs value;
      message = concat " " [
        "expected an attrset for resolved registry value:"
        name
      ];
    }; value;

    lookup = key: getAttr key entries;
  in {
    inherit name entries lookup seed;

    normalize = args @ {
      value,
      polarity ? null,
      key ? null,
      fallback ? null,
    }: let
      fallback' =
        if args ? fallback
        then fallback
        else if isNotEmpty key && hasAttr key seed
        then getAttr key seed
        else null;

      selected =
        if polarity != null
        then
          if isEmpty value && fallback' != null
          then fallback'
          else
            mkPolarity.selection {
              inherit value polarity;
              domain = name;
            }
        else if isEmpty value && fallback' != null
        then fallback'
        else value;
    in
      if isNotEmpty key && hasAttr key entries
      then getAttr key entries
      else if isString selected
      then lookup selected
      else selected;
  };

  mkAnalysis = {
    owner ? "mkAnalysis",
    registry,
    groupBy ? [],
    queryBy ? [],
  }: let
    data = registry.entries;

    group = {
      inherit owner;
      kind = "group";
    };

    query = {
      inherit owner;
      kind = "query";
    };

    mkGroup = args: mkMember (group // args);
    mkGroups = available:
      mkMembers (group
        // {
          inherit available;
          names = groupBy;
        });

    mkQuery = args: mkMember (query // args);
    mkQueries = available:
      mkMembers (query
        // {
          inherit available;
          names = queryBy;
        });
  in {
    groups = mkGroups [
      (mkGroup {
        prefix = "by";
        name = "Category";
        value =
          genAttrs
          (
            unique
            (
              concatMap (entry: entry.categories or [])
              (attrValues data)
            )
          )
          (
            category:
              filterAttrs
              (_: entry: isIn category (entry.categories or []))
              data
          );
      })
      (mkGroup {
        prefix = "by";
        field = "family";
        source = data;
        flatten = true;
      })
      (mkGroup {
        prefix = "by";
        field = "polarity";
        source = data;
        flatten = true;
      })
    ];

    queries = mkQueries [
      (mkQuery {
        prefix = "has";
        name = "Aliases";
        value =
          filterAttrs
          (_: entry: isNotEmpty (entry.aliases or []))
          data;
      })
      (mkQuery {
        prefix = "no";
        name = "Aliases";
        value =
          filterAttrs
          (_: entry: isEmpty (entry.aliases or []))
          data;
      })
      (mkQuery {
        prefix = "has";
        name = "Package";
        value =
          filterAttrs
          (_: entry: (entry.package or null) != null)
          data;
      })
      (mkQuery {
        prefix = "has";
        name = "Variant";
        value =
          filterAttrs
          (_: entry: entry ? variant)
          data;
      })
      (mkQuery {
        prefix = "has";
        name = "Names";
        value =
          filterAttrs
          (_: entry: entry ? names)
          data;
      })
      (mkQuery {
        prefix = "by";
        field = "family";
        source = data;
        flatten = true;
      })
      (mkQuery {
        prefix = "by";
        field = "polarity";
        source = data;
        flatten = true;
      })
    ];
  };

  mkData = {
    owner ? "mkData",
    path ? ./.,
    domain ? null,
    seed ? {},
    entries ? null,
    groups ? null,
    queries ? null,
    from ? null,
    groupBy ? [],
    queryBy ? [],
  }: let
    name =
      if isNotEmpty domain
      then toDomainName domain
      else baseNameOf path;

    source = mkSource {
      inherit path name entries groups queries from;
      owner = "mkSource";
    };

    registry = mkRegistry {
      inherit seed;
      inherit (source) name value;
      owner = "mkRegistry";
    };

    analysis = mkAnalysis {
      inherit registry groupBy queryBy;
      owner = "mkAnalysis";
    };
  in {
    inherit seed source registry analysis;
    inherit (registry) name entries lookup normalize;
    inherit (analysis) groups queries;
  };
  raw = importRegistry ./.;
  data = mkData {};
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
