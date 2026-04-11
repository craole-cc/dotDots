{
  _,
  __meta,
  ...
}: let
  __exports = _.meta.mkModuleExports {
    meta = __meta.module;
    functions = {
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
        ;
    };
  };

  __imports = {
    inherit (_.attrsets.access) attrNames attrValues;
    inherit
      (_.attrsets.construction)
      genAttrs
      listToAttrs
      optionalAttrs
      ;
    inherit (_.attrsets.predicates) isAttrs;
    inherit (_.attrsets.transformation) filterAttrs;
    inherit (_.lists.access) length;
    inherit (_.lists.predicates) isIn;
    inherit (_.lists.reduction) concatMap;
    inherit (_.lists.selection) filter;
    inherit (_.lists.transformation) unique;
    inherit (_.strings.transformation) removePrefix toPascal;
    inherit (_.applications.primitives) toValue toName;
    inherit (_.applications.predicates) hasField hasListField;
    inherit
      (_.applications.groups)
      mkCapabilityGroup
      mkMaturityGroup
      mkProtocolGroup
      mkScopeGroup
      ;
    inherit (_.applications.selectors) withFlag withoutFlag;
  };
  inherit (__imports) attrNames attrValues concatMap filter filterAttrs genAttrs hasField hasListField isAttrs isIn length listToAttrs mkCapabilityGroup mkMaturityGroup mkProtocolGroup mkScopeGroup optionalAttrs removePrefix toName toPascal toValue unique withFlag withoutFlag;

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
    field,
  }:
    optionalAttrs (field != null)
    (optionalAttrs (hasListField {inherit field set;})
      (mkLength {
        inherit set field;
        singleKey = "single" + toPascal field;
        multiKey = "multi" + toPascal field;
      }));

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

  # ── Query producers (named predicates) ──────────────────────────────────────
  mkMaturity = {set}:
    mkNamed {
      prefix = "is";
      set = mkMaturityGroup {inherit set;};
    };
  mkProtocol = {set}:
    mkNamed {
      prefix = "for";
      set = mkProtocolGroup {inherit set;};
    };
  mkScope = {set}:
    mkNamed {
      prefix = "as";
      set = mkScopeGroup {inherit set;};
    };
  mkCapability = {set}:
    mkNamed {
      prefix = "has";
      set = mkCapabilityGroup {inherit set;};
    };

  # present only when field exists in set; produces { independent = …; integrated = …; }
  mkIndependence = {set}: let
    field = "independent";
  in
    optionalAttrs (hasField {inherit field set;})
    (mkBool {
      inherit field set;
      trueKey = field;
      falseKey = "integrated";
    });

  # present only when any app has a config attrset with a `file` key
  mkConfig = {set}: let
    withConfig = filterAttrs (_: a: let cfg = toValue {field = "config";} a; in isAttrs cfg && cfg ? file) set;
    profileOnly = filterAttrs (_: a: toValue {field = "config.file";} a == ".profile") withConfig;
    isConfigurable = removeAttrs withConfig (attrNames profileOnly);
  in
    optionalAttrs (withConfig != {}) {inherit isConfigurable;};
in
  __exports.internal // {_rootAliases = __exports.external;}
