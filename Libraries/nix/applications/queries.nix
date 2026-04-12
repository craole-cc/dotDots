{
  _,
  __moduleDir,
  __moduleName,
  ...
}: let
  inherit
    (_.applications.groups)
    mkCapabilityGroups
    mkMaturityGroups
    mkProtocolGroups
    mkScopeGroups
    ;
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
  default = _.applications.filters.queries;

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

  mkFlagsFor = {
    set,
    flags ? [],
  }:
    foldl' (
      acc: f:
        acc
        // mkNamed {
          prefix = f.prefix or "is";
          set = mkBool {
            inherit set;
            inherit (f) field trueKey falseKey;
          };
        }
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

  mkEqFor = {
    set,
    eq ? [],
  }: let
    knownPrefixes = {
      kind = "as";
      surface = "on";
      toolkit = "with";
      color = "in";
      lang = "for";
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
        // mkNamed {
          prefix = e.prefix;
          set = mkEq {
            inherit set;
            field = e.field;
          };
        }
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
    } -> { ${singleKey} :: AttrSet, ${multiKey} :: AttrSe t }
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
        c = {};                       # missing field — excluded from both subsets
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
    Conditionally build length-based queries for a field, deriving the subset
    keys automatically via `toPascal`. Returns `{}` when `field` is `null`, or
    when `field` is non-null but no entry in `set` carries it as a list (i.e.
    `hasListField` returns false).

    Key names follow the pattern `"single" + toPascal field` and
    `"multi" + toPascal field`.

    # Type
  ```nix
    mkLengthFor :: {
      set   :: AttrSet,
      field :: string | null,
    } -> { ${singleKey} :: AttrSet, ${multiKey} :: AttrSet } | {}
  ```

    # Examples
  ```nix
    mkLengthFor {
      field = "tags";
      set   = { a = { tags = [ "x" ]; }; b = { tags = [ "x" "y" ]; }; };
    }
    # => { singleTags = { a = { tags = [ "x" ]; }; };
    #      multiTags  = { b = { tags = [ "x" "y" ]; }; }; }

    # field is present on entries but not as a list — hasListField guard fires
    mkLengthFor {
      field = "tags";
      set   = { a = { tags = "x"; }; b = { tags = "y"; }; };
    }
    # => {}

    mkLengthFor { field = null; set = { a = { tags = [ "x" ]; }; }; }
    # => {}
  ```
  */
  mkLengthFor = {
    set,
    lengths ? [], # was `fields` — avoids shadowing the imported `length` function
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
        c = {};                           # missing field — excluded from all keys
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

  mkMaturity = {set}:
    mkNamed {
      prefix = "is";
      set = mkMaturityGroups {inherit set;};
    };

  mkProtocol = {set}:
    mkNamed {
      prefix = "for";
      set = mkProtocolGroups {inherit set;};
    };

  mkScope = {set}:
    mkNamed {
      prefix = "as";
      set = mkScopeGroups {inherit set;};
    };

  mkCapability = {set}:
    mkNamed {
      prefix = "has";
      set = mkCapabilityGroups {inherit set;};
    };

  mkSupport = {
    set,
    support ? [], # was `fields`
  }:
    mkNamed {
      prefix = "supports";
      set =
        foldl' (
          acc: f:
            acc
            // mkMember {
              inherit set;
              field = f;
            }
        ) {}
        support;
    };

  mkIndependence = {set}: let
    field = "independent";
  in
    optionalAttrs (hasField {inherit field set;})
    (mkBool {
      inherit field set;
      trueKey = field;
      falseKey = "integrated";
    });

  /**
      Partition an application set by the members of the `engine` field,
      prefixed with `writtenIn` to reflect implementation language.

      # Type
  ```nix
      mkEngine :: { set :: AttrSet } -> { ${writtenIn} :: AttrSet }
  ```

      # Examples
  ```nix
      mkEngine { set = { a = { engine = ["rust"]; }; b = { engine = ["go"]; }; }; }
      # => { writtenInRust = { a = ...; }; writtenInGo = { b = ...; }; }
  ```
  */
  mkEngine = {set}:
    mkNamed {
      prefix = "writtenIn";
      set = mkMember {
        inherit set;
        field = "engine";
      };
    };

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
          a = { config = { file = "foot.ini"; lang = "ini"; }; };
          b = { config = { file = ".profile"; lang = "sh"; }; };
          c = {};
        };
      }
      # => { isConfigurable = { a = ...; };
      #      configuredWithIni = { a = ...; }; }
  ```
  */
  mkConfig = {set}: let
    withConfig =
      filterAttrs
      (_: a: let cfg = toValue {field = "config";} a; in isAttrs cfg && cfg ? file)
      set;
    profileOnly =
      filterAttrs
      (_: a: toValue {field = "config.file";} a == ".profile")
      withConfig;
    isConfigurable = removeAttrs withConfig (attrNames profileOnly);
    configuredWith = mkNamed {
      prefix = "configuredWith";
      set = mkMember {
        set = isConfigurable;
        field = "config.lang";
      };
    };
  in
    optionalAttrs (withConfig != {}) (
      {inherit isConfigurable;}
      // configuredWith
    );

  mkStandard = {
    set,
    eq ? ["kind" "toolkit" "surface"],
    flags ? [],
    lengths ? ["categories" "engine" "shells"],
    support ? [],
  }:
    {}
    // mkCapability {inherit set;}
    // mkConfig {inherit set;}
    // mkEngine {inherit set;}
    // mkIndependence {inherit set;}
    // mkEqFor {inherit set eq;}
    // mkFlagsFor {inherit set flags;}
    // mkLengthFor {inherit set lengths;}
    // mkMaturity {inherit set;}
    // mkProtocol {inherit set;}
    // mkScope {inherit set;}
    // mkSupport {inherit set support;}
    // {};
in
  _.meta.mkModuleExports {
    directory = __moduleDir;
    filename = __moduleName;
    doc = ''
      Application query builders (Layer 3).

      Provides composable query functions that partition an application set
      by field values, list membership, boolean flags, and field length.
      Includes semantic builders for well-known fields (maturity, protocol,
      scope, capability, config, independence) and a standard query combinator
      that applies all of them in one call.

      Depends on: applications {groups, predicates, primitives, selectors}.
    '';

    functions =
      default
      // {
        inherit
          mkBool
          mkCapability
          mkConfig
          mkEq
          mkIndependence
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
        mk = mkStandard;
      };
  }
