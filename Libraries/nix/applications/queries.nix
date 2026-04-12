{_, ...}: let
  meta = let
    doc = ''
      Application query builders (Layer 3).

      Provides composable query functions that partition an application set
      by field values, list membership, boolean flags, and field length.

      Includes semantic builders for well-known fields (maturity, protocol,
      scope, capability, config, independence, engine) and a standard query
      combinator that applies all of them in one call.

      Depends on: applications {groups, predicates, primitives, selection}.
    '';
    functions = {
      inherit
        all
        mkBool
        mkCapability
        mkConfig
        mkEq
        mkEqFor
        mkEngine
        mkFlagsFor
        mkLength
        mkLengthFor
        mkMaturity
        mkMember
        mkNamed
        mkProtocol
        mkScope
        mkStandard
        mkSupport
        ;
      mkQueries = mkStandard;
    };
    exports = {
      local = all // functions;
      alias = {mkApplicationQueries = mkStandard;};
    };
  in {inherit doc exports functions;};

  all = _.applications.filters.queries;
  inherit (_.applications.groups) mkCapabilityGroups mkMaturityGroups mkProtocolGroups mkScopeGroups;
  inherit (_.applications.predicates) hasField hasListField;
  inherit (_.applications.primitives) toValue toName;
  inherit (_.applications.selection) withFlag withoutFlag;
  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.construction) genAttrs listToAttrs optionalAttrs;
  inherit (_.attrsets.predicates) isAttrs;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.lists.access) length;
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.reduction) concatMap foldl';
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.strings.transformation) toPascal;

  /**
  Partition an attribute set into two subsets based on the presence or absence
  of a boolean flag field, exposing them under caller-supplied keys.

  # Type
  ```nix
  mkBool :: {
    field    :: string,
    trueKey  :: string,
    falseKey :: string,
    set      :: AttrSet,
  } -> { ${trueKey} :: AttrSet, ${falseKey} :: AttrSet }
  ```

  # Examples
  ```nix
  mkBool {
    field    = "active";
    trueKey  = "running";
    falseKey = "stopped";
    set      = { a = { active = true; }; b = { active = false; }; };
  }
  # => { running = { a = { active = true;  }; };
  #      stopped = { b = { active = false; }; }; }
  ```
  */
  mkBool = {
    field,
    trueKey,
    falseKey,
    set,
  }: {
    ${trueKey} = withFlag {inherit field set;};
    ${falseKey} = withoutFlag {inherit field set;};
  };

  /**
  Apply `mkBool` for each flag descriptor in `flags`, merging results.

  Each entry carries `field`, `trueKey`, `falseKey`, and an optional
  `prefix` (default `"is"`) passed to `mkNamed`.

  # Type
  ```nix
  mkFlagsFor :: {
    set   :: AttrSet,
    flags :: [{ field :: string, trueKey :: string, falseKey :: string, prefix? :: string }],
  } -> AttrSet
  ```

  # Examples
  ```nix
  mkFlagsFor {
    set   = { a = { posix = true; }; b = { posix = false; }; };
    flags = [{ field = "posix"; trueKey = "posix"; falseKey = "modern"; }];
  }
  # => { isPosix = { a = ...; }; isModern = { b = ...; }; }

  mkFlagsFor {
    set   = { a = { posix = true; }; b = { posix = false; }; };
    flags = [{ field = "posix"; trueKey = "posix"; falseKey = "modern"; prefix = "has"; }];
  }
  # => { hasPosix = { a = ...; }; hasModern = { b = ...; }; }
  ```
  */
  mkFlagsFor = {
    set,
    flags ? [],
  }:
    foldl' (
      acc: f:
        acc
        // optionalAttrs (hasField {
          inherit set;
          field = f.field;
        })
        (mkNamed {
          prefix = f.prefix or "is";
          set = mkBool {
            inherit set;
            inherit (f) field trueKey falseKey;
          };
        })
    ) {}
    flags;

  /**
  Partition an attribute set by the distinct values of a scalar field,
  returning an attribute set whose keys are those values and whose values
  are the subsets sharing that value.

  Entries where the field is `null` are excluded from all partitions.

  # Type
  ```nix
  mkEq :: {
    field :: string,
    set   :: AttrSet,
  } -> { ${value} :: AttrSet }
  ```

  # Examples
  ```nix
  mkEq {
    field = "color";
    set   = { a = { color = "red"; }; b = { color = "blue"; }; c = { color = "red"; }; };
  }
  # => { red  = { a = { color = "red"; }; c = { color = "red"; }; };
  #      blue = { b = { color = "blue"; }; }; }

  # Entries with a null field value are dropped entirely
  mkEq {
    field = "color";
    set   = { a = { color = "red"; }; b = { color = null; }; };
  }
  # => { red = { a = { color = "red"; }; }; }
  ```
  */
  mkEq = {
    field,
    set,
  }: let
    getVal = toValue {inherit field;};
    keys = unique (filter (v: v != null) (map getVal (attrValues set)));
  in
    genAttrs keys (value: filterAttrs (_: a: getVal a == value) set);

  /**
  Apply `mkEq` for each field in `eq`, prefixing keys via `mkNamed`.

  Field names map to prefixes via `knownPrefixes`; unrecognised fields
  get an empty prefix. Pass an attrset `{ field, prefix }` to override.

  # Type
  ```nix
  mkEqFor :: {
    set :: AttrSet,
    eq  :: [string | { field :: string, prefix :: string }],
  } -> AttrSet
  ```

  # Examples
  ```nix
  mkEqFor {
    set = { a = { kind = "graphical"; }; b = { kind = "terminal"; }; };
    eq  = ["kind"];
  }
  # => { asGraphical = { a = ...; }; asTerminal = { b = ...; }; }

  mkEqFor {
    set = { a = { kind = "graphical"; }; };
    eq  = [{ field = "kind"; prefix = "is"; }];
  }
  # => { isGraphical = { a = ...; }; }
  ```
  */
  mkEqFor = {
    set,
    eq ? [],
  }: let
    knownPrefixes = {
      channel = "on";
      color = "in";
      compositor = "using";
      family = "from";
      greeters = "via";
      kind = "as";
      lang = "for";
      notifier = "via";
      panel = "with";
      role = "as";
      scope = "for";
      surface = "on";
      toolkit = "with";
    };
    normalize = f:
      if isAttrs f
      then f
      else {
        field = f;
        prefix = knownPrefixes.${f} or "";
      };
  in
    foldl' (
      acc: f: let
        e = normalize f;
      in
        acc
        // optionalAttrs (hasField {
          inherit set;
          field = e.field;
        })
        (mkNamed {
          prefix = e.prefix;
          set = mkEq {
            inherit set;
            field = e.field;
          };
        })
    ) {}
    eq;

  /**
  Partition an attribute set by the length of a list field, producing two
  subsets: entries whose list has exactly one element and entries whose list
  has more than one element. Both subsets are exposed under caller-supplied
  keys.

  When the field is absent on an entry it is treated as `[]`, so that entry
  appears in neither subset.

  # Type
  ```nix
  mkLength :: {
    field     :: string,
    singleKey :: string,
    multiKey  :: string,
    set       :: AttrSet,
  } -> { ${singleKey} :: AttrSet, ${multiKey} :: AttrSet }
  ```

  # Examples
  ```nix
  mkLength {
    field     = "ports";
    singleKey = "singlePort";
    multiKey  = "multiPort";
    set       = {
      a = { ports = [ 80 ]; };
      b = { ports = [ 80 443 ]; };
      c = {};
    };
  }
  # => { singlePort = { a = { ports = [ 80 ]; }; };
  #      multiPort  = { b = { ports = [ 80 443 ]; }; }; }
  ```
  */
  mkLength = {
    field,
    singleKey,
    multiKey,
    set,
  }: let
    getVal = toValue {
      inherit field;
      default = [];
    };
  in {
    ${singleKey} = filterAttrs (_: a: length (getVal a) == 1) set;
    ${multiKey} = filterAttrs (_: a: length (getVal a) > 1) set;
  };

  /**
  Apply `mkLength` for each field in `lengths`, deriving key names
  automatically via `toPascal`. Fields absent from `set` or not carrying
  a list value are silently skipped.

  Key names follow the pattern `"single" + toPascal field` and
  `"multi" + toPascal field`.

  # Type
  ```nix
  mkLengthFor :: {
    set     :: AttrSet,
    lengths :: [string],
  } -> AttrSet
  ```

  # Examples
  ```nix
  mkLengthFor {
    set     = { a = { tags = [ "x" ]; }; b = { tags = [ "x" "y" ]; }; };
    lengths = ["tags"];
  }
  # => { singleTags = { a = { tags = [ "x" ]; }; };
  #      multiTags  = { b = { tags = [ "x" "y" ]; }; }; }

  # Non-list field — hasListField guard fires, field skipped
  mkLengthFor {
    set     = { a = { tags = "x"; }; };
    lengths = ["tags"];
  }
  # => {}
  ```
  */
  mkLengthFor = {
    set,
    lengths ? [],
  }:
    foldl' (
      acc: f:
        acc
        // optionalAttrs (f != null)
        (optionalAttrs (hasListField {
            inherit set;
            field = f;
          })
          (mkLength {
            inherit set;
            field = f;
            singleKey = "single" + toPascal f;
            multiKey = "multi" + toPascal f;
          }))
    ) {}
    lengths;

  /**
  Index an attribute set by the members of a list field, producing an
  attribute set whose keys are the distinct list elements and whose values
  are the subsets that contain that element.

  When the field is absent on an entry it is treated as `[]`, so that entry
  does not appear under any key.

  # Type
  ```nix
  mkMember :: {
    field :: string,
    set   :: AttrSet,
  } -> { ${element} :: AttrSet }
  ```

  # Examples
  ```nix
  mkMember {
    field = "tags";
    set   = {
      a = { tags = [ "nixos" "flake" ]; };
      b = { tags = [ "flake" ]; };
      c = {};
    };
  }
  # => { nixos = { a = { tags = [ "nixos" "flake" ]; }; };
  #      flake = { a = { tags = [ "nixos" "flake" ]; }; b = { tags = [ "flake" ]; }; }; }
  ```
  */
  mkMember = {
    field,
    set,
  }: let
    getVal = toValue {
      inherit field;
      default = [];
    };
    keys = unique (concatMap getVal (attrValues set));
  in
    genAttrs keys (value: filterAttrs (_: a: isIn value (getVal a)) set);

  /**
  Re-key each attribute in `set` by transforming its name through `toName`,
  which prepends `prefix` and optionally appends `suffix`.

  # Type
  ```nix
  mkNamed :: {
    prefix :: string,
    set    :: AttrSet,
    suffix :: string,  # optional, default ""
  } -> AttrSet
  ```

  # Examples
  ```nix
  mkNamed {
    prefix = "by";
    set    = { color = { ... }; size = { ... }; };
  }
  # => { byColor = { ... }; bySize = { ... }; }

  mkNamed {
    prefix = "by";
    suffix = "Index";
    set    = { color = { ... }; size = { ... }; };
  }
  # => { byColorIndex = { ... }; bySizeIndex = { ... }; }
  ```
  */
  mkNamed = {
    prefix,
    set,
    suffix ? "",
  }:
    listToAttrs (map (field: {
      name = toName {inherit prefix suffix field;};
      value = set.${field};
    }) (attrNames set));

  mkCapability = {set}:
    optionalAttrs (hasListField {
      inherit set;
      field = "capabilities";
    })
    (mkNamed {
      prefix = "has";
      set = mkCapabilityGroups {inherit set;};
    });

  mkMaturity = {set}:
    optionalAttrs (hasField {
      inherit set;
      field = "maturity";
    })
    (mkNamed {
      prefix = "is";
      set = mkMaturityGroups {inherit set;};
    });

  mkProtocol = {set}:
    optionalAttrs (hasListField {
      inherit set;
      field = "protocol";
    })
    (mkNamed {
      prefix = "for";
      set = mkProtocolGroups {inherit set;};
    });

  mkScope = {set}:
    optionalAttrs (hasField {
      inherit set;
      field = "scope";
    })
    (mkNamed {
      prefix = "as";
      set = mkScopeGroups {inherit set;};
    });

  mkEngine = {set}:
    optionalAttrs (hasListField {
      inherit set;
      field = "engine";
    })
    (mkNamed {
      prefix = "writtenIn";
      set = mkMember {
        inherit set;
        field = "engine";
      };
    });

  /**
  Derive config-related queries from an application set.

  Produces `isConfigurable` for apps with a non-profile config file, and
  `configuredWith*` entries partitioned by `config.lang` when present.

  # Type
  ```nix
  mkConfig :: { set :: AttrSet } -> AttrSet
  ```

  # Examples
  ```nix
  mkConfig {
    set = {
      a = { config = { file = "foot.ini"; lang = ["ini"]; }; };
      b = { config = { file = ".profile"; lang = ["sh"]; }; };
      c = {};
    };
  }
  # => { isConfigurable    = { a = ...; };
  #      configuredWithIni = { a = ...; }; }
  ```
  */
  mkConfig = {set}: let
    withConfig = filterAttrs (_: a: let
      cfg = toValue {field = "config";} a;
    in
      isAttrs cfg && cfg ? file)
    set;
    profileOnly = filterAttrs (_: a: toValue {field = "config.file";} a == ".profile") withConfig;
    isConfigurable = removeAttrs withConfig (attrNames profileOnly);
    configuredWith = mkNamed {
      prefix = "configuredWith";
      set = mkMember {
        set = isConfigurable;
        field = "config.lang";
      };
    };
  in
    optionalAttrs (withConfig != {}) ({inherit isConfigurable;} // configuredWith);

  # mkIndependence = {set}: let
  #   field = "independent";
  # in
  #   optionalAttrs (hasField {inherit field set;})
  #   (mkBool {
  #     inherit field set;
  #     trueKey = field;
  #     falseKey = "integrated";
  #   });

  mkSupport = {
    set,
    support ? [],
  }:
    mkNamed {
      prefix = "supports";
      set =
        foldl' (
          acc: f:
            acc
            // optionalAttrs (hasListField {
              inherit set;
              field = f;
            })
            (mkMember {
              inherit set;
              field = f;
            })
        ) {}
        support;
    };

  mkStandard = {
    set,
    eq ? [
      "compositor"
      "kind"
      "role"
      "scope"
      "family"
      "surface"
      "toolkit"
    ],
    flags ? [
      {
        field = "posix";
        trueKey = "posix";
        falseKey = "modern";
      }
      {
        field = "independent";
        trueKey = "independent";
        falseKey = "integrated";
      }
      {
        field = "interactive";
        trueKey = "interactive";
        falseKey = "passive";
      }
      {
        field = "system";
        trueKey = "system";
        falseKey = "userOnly";
      }
      {
        field = "wrappable";
        trueKey = "wrappable";
        falseKey = "bare";
      }
      {
        field = "builtin";
        trueKey = "builtin";
        falseKey = "standalone";
      }
      {
        field = "needsTerminal";
        trueKey = "tui";
        falseKey = "graphical";
      }
    ],
    lengths ? [
      "categories"
      "config.lang"
      "engine"
      "layouts"
      "protocol"
      "shells"
      "toolkit"
    ],
    support ? [
      "layouts"
      "protocol"
      "shells"
    ],
  }:
    filterAttrs (_: v: v != {}) ({}
      // mkCapability {inherit set;}
      // mkConfig {inherit set;}
      // mkEngine {inherit set;}
      // mkEqFor {inherit set eq;}
      // mkFlagsFor {inherit set flags;}
      // mkLengthFor {inherit set lengths;}
      // mkMaturity {inherit set;}
      // mkProtocol {inherit set;}
      // mkScope {inherit set;}
      // mkSupport {inherit set support;}
      // {});
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
