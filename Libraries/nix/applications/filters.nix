{_, ...}: let
  __exports = {
    internal = filters;
    external.applicationFilters = filters;
  };

  inherit (_.applications.construction) mkFilters;
  inherit (_.attrsets.access) attrByPath attrNames attrValues;
  inherit (_.attrsets.construction) genAttrs listToAttrs optionalAttrs;
  inherit (_.attrsets.merging) recursiveUpdate;
  inherit (_.attrsets.predicates) isAttrs;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs setAttrByPath;
  inherit (_.lists.access) length;
  inherit (_.lists.predicates) isIn isList;
  inherit (_.lists.reduction) concatMap;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.strings.construction) concatStringsSep;
  inherit (_.strings.transformation) splitString toPascal;
  all = _.applications.registry;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Primitives                                                ║
  #╚═══════════════════════════════════════════════════════════╝
  toPath = field:
    if isList field
    then field
    else splitString "." field;

  toValue = {
    field,
    default ? null,
  }: app:
    attrByPath (toPath field) default app;

  toName = {
    prefix ? "by",
    field,
    suffix ? "",
  }: let
    normalized = concatStringsSep "-" (toPath field);
    name = toPascal normalized;
  in
    prefix + name + suffix;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Predicates                                                ║
  #╚═══════════════════════════════════════════════════════════╝
  hasField = {
    field,
    set,
  }:
    filter (a: toValue {inherit field;} a != null) (attrValues set) != [];

  hasListField = {
    field,
    set,
  }:
    filter (a: isList (toValue {inherit field;} a)) (attrValues set) != [];

  #╔═══════════════════════════════════════════════════════════╗
  #║ Primitive Filters                                         ║
  #╚═══════════════════════════════════════════════════════════╝
  withFlag = {
    field,
    set,
  }:
    filterAttrs (_:
      toValue {
        inherit field;
        default = false;
      })
    set;

  withoutFlag = {
    field,
    set,
  }:
    filterAttrs (_: a:
      !(toValue {
          inherit field;
          default = false;
        }
        a))
    set;

  withNeq = {
    field,
    default ? null,
    value ? null,
    set,
  }:
    filterAttrs (_: a: toValue {inherit field default;} a != value) set;

  normalizeConfig = {
    set,
    path ? ["config"],
  }:
    mapAttrs (
      _: a: let
        cfg = attrByPath path null a;
      in
        if cfg != null && cfg.home != null && cfg.file != null
        then recursiveUpdate a (setAttrByPath path (cfg // {path = "${cfg.home}/${cfg.file}";}))
        else a
    )
    set;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Field Query Builders                                      ║
  #╚═══════════════════════════════════════════════════════════╝
  mkEqQueries = {
    field,
    set,
  }: let
    getVal = toValue {inherit field;};
    keys = unique (filter (v: v != null) (map getVal (attrValues set)));
  in
    genAttrs keys (value: filterAttrs (_: a: getVal a == value) set);

  mkMemberQueries = {
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

  mkBoolQueries = {
    field,
    trueKey,
    falseKey,
    set,
  }: {
    ${trueKey} = withFlag {inherit field set;};
    ${falseKey} = withoutFlag {inherit field set;};
  };

  mkLengthQueries = {
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

  mkLengthQueriesFor = {
    set,
    field,
  }:
    optionalAttrs (field != null)
    (optionalAttrs (hasListField {inherit field set;})
      (mkLengthQueries {
        inherit set field;
        singleKey = "single" + toPascal field;
        multiKey = "multi" + toPascal field;
      }));

  mkNamedQueries = {
    prefix,
    set,
    suffix ? "",
  }:
    listToAttrs (map (field: {
      name = toName {inherit prefix suffix field;};
      value = set.${field};
    }) (attrNames set));

  #╔═══════════════════════════════════════════════════════════╗
  #║ Semantic Helpers                                          ║
  #╚═══════════════════════════════════════════════════════════╝
  mkMaturityGroup = {set}:
    mkEqQueries {
      inherit set;
      field = "maturity";
    };
  mkProtocolGroup = {set}:
    mkMemberQueries {
      inherit set;
      field = "protocol";
    };
  mkScopeGroup = {set}:
    mkEqQueries {
      inherit set;
      field = "scope";
    };
  mkCapabilityGroup = {set}: let
    fields = ["acceleration" "compositing" "remote" "floating"];
  in
    filterAttrs (_: v: v != {}) (genAttrs fields (field: withFlag {inherit field set;}));

  mkMaturityQueries = {set}:
    mkNamedQueries {
      prefix = "is";
      set = mkMaturityGroup {inherit set;};
    };
  mkProtocolQueries = {set}:
    mkNamedQueries {
      prefix = "for";
      set = mkProtocolGroup {inherit set;};
    };
  mkScopeQueries = {set}:
    mkNamedQueries {
      prefix = "as";
      set = mkScopeGroup {inherit set;};
    };
  mkCapabilityQueries = {set}:
    mkNamedQueries {
      prefix = "has";
      set = mkCapabilityGroup {inherit set;};
    };

  mkIndependenceQueries = {set}: let
    field = "independent";
  in
    optionalAttrs (hasField {inherit field set;})
    (mkBoolQueries {
      inherit field set;
      trueKey = field;
      falseKey = "integrated";
    });

  mkConfigQueries = {set}: let
    withConfig = filterAttrs (_: a: let cfg = toValue {field = "config";} a; in isAttrs cfg && cfg ? file) set;
    profileOnly = filterAttrs (_: a: toValue {field = "config.file";} a == ".profile") withConfig;
    isConfigurable = removeAttrs withConfig (attrNames profileOnly);
  in
    optionalAttrs (withConfig != {}) {inherit isConfigurable;};

  mkStandardQueries = {
    set,
    field ? null,
  }:
    mkCapabilityQueries {inherit set;}
    // mkConfigQueries {inherit set;}
    // mkIndependenceQueries {inherit set;}
    // mkMaturityQueries {inherit set;}
    // mkProtocolQueries {inherit set;}
    // mkScopeQueries {inherit set;}
    // mkLengthQueriesFor {inherit set field;};

  #╔═══════════════════════════════════════════════════════════╗
  #║ Group Helpers                                             ║
  #╚═══════════════════════════════════════════════════════════╝
  mkConfigFileGroup = {set}: let
    getVal = toValue {field = "config.file";};
    withCfg = filterAttrs (_: a: toValue {field = "config";} a != null) set;
    keys = unique (filter (v: v != null) (map getVal (attrValues withCfg)));
  in
    genAttrs keys (file: filterAttrs (_: a: getVal a == file) set);

  mkStandardGrouped = {
    set,
    eq ? [],
    member ? [],
    fields ? [],
  }: let
    perField = {
      maturity = mkMaturityGroup {inherit set;};
      protocol = mkProtocolGroup {inherit set;};
      config = mkConfigFileGroup {inherit set;};
      capability = mkCapabilityGroup {inherit set;};
      scope = mkScopeGroup {inherit set;};
    };
    allFields = unique (eq ++ member ++ fields);
  in
    listToAttrs (map (field: {
        name = toName {inherit field;};
        value =
          perField.${
            field
          } or (
            if isIn field eq
            then mkEqQueries {inherit set field;}
            else mkMemberQueries {inherit set field;}
          );
      })
      allFields);

  # ── Section builder ──────────────────────────────────────────────────────────
  # Eliminates the repeated skeleton across every leaf section:
  #
  #   let all = …; groups = mkStandardGrouped {…}; queries = mkStandardQueries {…} // extras;
  #   in { inherit all groups queries; }
  #
  # `extraQueries` is a function `groups -> attrset` so callers can promote
  # specific group keys into queries without needing a separate binding:
  #
  #   extraQueries = groups: { inherit (groups.byKind) history fuzzy; }
  mkSection = {
    set,
    grouped ? {},
    queryField ? null,
    extraQueries ? (_groups: {}),
  }: let
    groups = mkStandardGrouped ({inherit set;} // grouped);
  in {
    all = set;
    inherit groups;
    queries =
      mkStandardQueries {
        inherit set;
        field = queryField;
      }
      // extraQueries groups;
  };

  #╔═══════════════════════════════════════════════════════════╗
  #║ Core                                                      ║
  #╚═══════════════════════════════════════════════════════════╝
  filters = mkFilters {
    inherit all;
    queries = {byCategory, ...}: let
      needsTerminal = withFlag {
        field = "needsTerminal";
        set = all;
      };

      shell = let
        all = byCategory.shell;
      in {
        inherit all;

        shells = mkSection {
          set = normalizeConfig {
            set = filterAttrs (_: a: (a.categories or []) == ["shell"]) all;
          };
          grouped = {
            member = ["engine"];
            fields = ["config" "maturity"];
          };
          # posix query runs against the full shell set, not the filtered one
          extraQueries = _:
            mkBoolQueries {
              set = all;
              field = "posix";
              trueKey = "posix";
              falseKey = "modern";
            };
        };

        prompts = mkSection {
          set = byCategory.prompt;
          grouped = {
            eq = ["engine"];
            member = ["shells"];
            fields = ["maturity"];
          };
          queryField = "shells";
        };

        enhancements = mkSection {
          set = byCategory.enhancement;
          grouped = {
            eq = ["kind"];
            member = ["shells" "engine"];
            fields = ["maturity"];
          };
          queryField = "shells";
          extraQueries = groups: {inherit (groups.byKind) history fuzzy navigation;};
        };

        lineEditors = mkSection {
          set = byCategory."line-editor";
          grouped = {
            member = ["engine" "shell"];
            fields = ["maturity"];
          };
          queryField = "shells";
        };
      };

      interface = let
        all = byCategory.interface;
      in {
        inherit all;

        compositors = mkSection {
          set = byCategory.compositor;
          grouped = {
            eq = ["role"];
            fields = ["protocol" "maturity"];
          };
        };

        environments = mkSection {
          set = byCategory.environment;
          grouped = {
            eq = ["compositor" "scope"];
            member = ["panel" "layouts" "greeters"];
            fields = ["protocol" "maturity"];
          };
          extraQueries = groups:
            {inherit (groups.byLayouts) tiling floating stacking;}
            // groups.byScope;
        };

        greeters = mkSection {
          set = byCategory.greeter;
          grouped = {
            eq = ["kind" "toolkit"];
            fields = ["protocol"];
          };
          extraQueries = groups: groups.byToolkit // groups.byKind;
        };

        notifiers = mkSection {
          set = byCategory.notifier;
          grouped = {
            member = ["config.lang"];
            fields = ["maturity" "protocol"];
          };
        };

        panels = mkSection {
          set = byCategory.panel;
          grouped = {
            eq = ["toolkit"];
            member = ["config.lang" "engine"];
            fields = ["maturity" "protocol"];
          };
          queryField = "toolkit";
        };

        protocols = mkSection {
          set = byCategory.protocol;
          grouped = {
            eq = ["surface"];
            fields = ["capability" "maturity"];
          };
          extraQueries = groups:
            mkCapabilityQueries {set = byCategory.protocol;}
            // groups.bySurface;
        };
      };
    in {inherit needsTerminal shell interface;};
  };
in
  __exports.internal // {__rootAliases = __exports.external;}
