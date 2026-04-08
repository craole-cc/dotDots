{_, ...}: let
  __exports = {
    internal = filters;
    external.applicationFilters = filters;
  };

  inherit (_.applications.construction) mkFilters;
  inherit (_.applications.enums) categories channels families;
  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.construction) genAttrs;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs;
  inherit (_.lists.access) length;
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.transformation) unique;
  inherit (_.lists.reduction) concatMap;
  inherit (_.lists.selection) filter;
  all = _.applications.registry;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Checkers                                                  ║
  #╚═══════════════════════════════════════════════════════════╝
  withFlag = {
    field,
    set,
  }:
    filterAttrs
    (_: a: (a.${field} or false))
    set;

  withoutFlag = {
    field,
    set,
  }:
    filterAttrs
    (_: a: !(a.${field} or false))
    set;

  withEq = {
    field,
    default ? null,
    value,
    set,
  }:
    filterAttrs
    (_: a: (a.${field} or default) == value)
    set;

  withNeq = {
    field,
    default ? null,
    value,
    set,
  }:
    filterAttrs
    (_: a: (a.${field} or default) != value)
    set;

  withMember = {
    field,
    value,
    set,
  }:
    filterAttrs
    (_: a: isIn value (a.${field} or []))
    set;

  groupBy = {
    field,
    default ? "unknown",
    keys,
    set,
  }:
    genAttrs keys (k:
      withEq {
        inherit field default set;
        value = k;
      });

  groupByMember = {
    field,
    keys,
    set,
  }:
    genAttrs keys (p:
      withMember {
        inherit field set;
        value = p;
      });

  byFile = {
    set,
    field ? "config.file",
  }:
    mkEqQueries {inherit set field;};

  #╔═══════════════════════════════════════════════════════════╗
  #║ Builders                                                  ║
  #╚═══════════════════════════════════════════════════════════╝
  mkEqQueries = {
    field,
    default ? false,
    set,
  }: let
    keys = unique (
      filter (k: k != default) (
        map
        (a: a.${field} or default)
        (attrValues set)
      )
    );
  in
    groupBy {inherit field default keys set;};

  mkBoolQueries = {
    field,
    trueKey,
    falseKey,
    set,
  }: {
    ${trueKey} = withFlag {inherit field set;};
    ${falseKey} = withoutFlag {inherit field set;};
  };

  mkMemberQueries = {
    field,
    set,
  }: let
    keys = unique (
      concatMap
      (a: a.${field} or [])
      (attrValues set)
    );
  in
    groupByMember {inherit field keys set;};

  # -- Semantic grouped helpers ─────────────────────────────────────────────────
  mkMaturityGroup = {
    set,
    default ? "unknown",
  }:
    mkEqQueries {
      inherit set default;
      field = "maturity";
    };

  mkProtocolGroup = set:
    mkMemberQueries {
      inherit set;
      field = "protocol";
    };

  mkCapabilityGroup = set: {
    acceleration = withFlag {
      inherit set;
      field = "acceleration";
    };
    compositing = withFlag {
      inherit set;
      field = "compositing";
    };
    remote = withFlag {
      inherit set;
      field = "remote";
    };
  };

  # -- Semantic queried helpers ─────────────────────────────────────────────────
  mkIndependenceQueries = set:
    mkBoolQueries {
      inherit set;
      field = "independent";
      trueKey = "independent";
      falseKey = "integrated";
    };

  mkMaturityQueries = set: {
    isStable = withEq {
      inherit set;
      field = "maturity";
      value = "stable";
    };
    isYoung = withEq {
      inherit set;
      field = "maturity";
      value = "young";
    };
    isLegacy = withEq {
      inherit set;
      field = "maturity";
      value = "legacy";
    };
  };

  mkProtocolQueries = set: {
    worksOnWayland = withMember {
      inherit set;
      field = "protocol";
      value = "wayland";
    };
    worksOnXorg = withMember {
      inherit set;
      field = "protocol";
      value = "xorg";
    };
  };

  mkCapabilityQueries = set: {
    canAccelerate = withFlag {
      inherit set;
      field = "acceleration";
    };
    canComposite = withFlag {
      inherit set;
      field = "compositing";
    };
    canRemote = withFlag {
      inherit set;
      field = "remote";
    };
  };

  #╔═══════════════════════════════════════════════════════════╗
  #║ Core                                                      ║
  #╚═══════════════════════════════════════════════════════════╝
  filters = mkFilters {
    inherit all categories channels families;
    queried = {byCategory, ...}: let
      needsTerminal = withFlag {
        field = "needsTerminal";
        set = all;
      };

      shell = let
        set = byCategory.shell;
        all = set;

        shells = let
          set = mapAttrs (_: val:
            val
            // {fileName = val.config.file or "none";}) (
            filterAttrs
            (_: a: (a.categories or []) == ["shell"])
            byCategory.shell
          );
          all = set;

          grouped = {
            byEngine = mkMemberQueries {
              inherit set;
              field = "engine";
            };
            byMaturity = mkMaturityGroup {inherit set;};
            byFile = mkEqQueries {
              inherit set;
              field = "fileName";
              # default = "none";
            };
          };

          queried = let
            standards = mkBoolQueries {
              inherit set;
              field = "posix";
              trueKey = "posix";
              falseKey = "modern";
            };
            configurability = let
              isProfileOnly = grouped.byFile.".profile" or {};
              isConfigurable = removeAttrs all (attrNames isProfileOnly);
            in {inherit isProfileOnly isConfigurable;};
            roles = {
              system = withFlag {
                inherit set;
                field = "system";
              };
              interactive = withFlag {
                inherit set;
                field = "interactive";
              };
            };
          in
            standards // configurability // roles;
        in {inherit all grouped queried;};

        prompts = let
          set = byCategory.prompt;
          all = set;
          grouped = {
            byShell = mkMemberQueries {
              inherit set;
              field = "shells";
            };
            byLanguage = mkEqQueries {
              inherit set;
              field = "language";
            };
            byMaturity = mkMaturityGroup {inherit set;};
          };
          queried = {
            configurable = filterAttrs (_: a: (a.config or null) != null) all;
            multiShell = filterAttrs (_: a: length (a.shells or []) > 1) all;
            singleShell = filterAttrs (_: a: length (a.shells or []) == 1) all;
            stable = withEq {
              inherit set;
              field = "maturity";
              value = "stable";
            };
            legacy = withEq {
              inherit set;
              field = "maturity";
              value = "legacy";
            };
          };
        in {inherit all grouped queried;};

        enhancements = let
          set = byCategory.enhancement;
          all = set;
          grouped = {
            byKind = groupBy {
              inherit set;
              field = "kind";
              keys = unique (map (a: a.kind or "unknown") (attrValues all));
            };
            byShell = groupByMember {
              inherit set;
              field = "shells";
              keys = unique (concatMap (a: a.shells or []) (attrValues all));
            };
          };
          queried = {
            history = withEq {
              inherit set;
              field = "kind";
              value = "history";
            };
            fuzzy = withEq {
              inherit set;
              field = "kind";
              value = "fuzzy";
            };
            navigation = withEq {
              inherit set;
              field = "kind";
              value = "navigation";
            };
          };
        in {inherit all grouped queried;};

        lineEditors = let
          set = byCategory."line-editor";
          all = set;
          grouped = {
            byShell = groupByMember {
              inherit set;
              field = "shells";
              keys = unique (concatMap (a: a.shells or []) (attrValues all));
            };
          };
          queried = {
            stable = withEq {
              inherit set;
              field = "maturity";
              value = "stable";
            };
            young = withEq {
              inherit set;
              field = "maturity";
              value = "young";
            };
          };
        in {inherit all grouped queried;};
      in {inherit all shells prompts enhancements lineEditors;};

      interface = let
        set = byCategory.interface;
        all = set;
        protocolNames = attrNames byCategory.protocol;
        greeterNames = attrNames byCategory.greeter;

        compositors = let
          set = byCategory.compositor;
          all = set;
          grouped = {
            byProtocol = groupByMember {
              inherit set;
              field = "protocol";
              keys = protocolNames; # pinned to registry; mkProtocolGroup would derive from data
            };
            byRole = groupBy {
              inherit set;
              field = "role";
              keys = unique (map (a: a.role or "unknown") (attrValues all));
            };
            byMaturity = mkMaturityGroup {inherit set;};
          };
          queried = {};
        in {inherit all grouped queried;};

        environments = let
          set = byCategory.environment;
          all = set;
          grouped = {
            byCompositor = groupBy {
              inherit set;
              field = "compositor";
              default = "none";
              keys = unique (map (a: a.compositor or "none") (attrValues set));
            };
            byPanel = groupByMember {
              inherit set;
              field = "panel";
              keys = unique (concatMap (a: a.panel or []) (attrValues set));
            };
            byScope = groupBy {
              inherit set;
              field = "scope";
              default = "unknown";
              keys = unique (map (a: a.scope or "unknown") (attrValues set));
            };
            byLayout = groupByMember {
              inherit set;
              field = "layouts";
              keys = ["tiling" "floating" "stacking"];
            };
            byProtocol = groupByMember {
              inherit set;
              field = "protocol";
              keys = protocolNames; # pinned to registry; mkProtocolGroup would derive from data
            };
            byGreeter = groupByMember {
              inherit set;
              field = "greeters";
              keys = greeterNames;
            };
          };
          queried = {
            desktop = withEq {
              inherit set;
              field = "scope";
              default = null;
              value = "desktop";
            };
            compositor = withEq {
              inherit set;
              field = "scope";
              default = null;
              value = "compositor";
            };
            tiling = withMember {
              inherit set;
              field = "layouts";
              value = "tiling";
            };
            floating = withMember {
              inherit set;
              field = "layouts";
              value = "floating";
            };
            stacking = withMember {
              inherit set;
              field = "layouts";
              value = "stacking";
            };
          };
        in {inherit all grouped queried;};

        greeters = let
          set = byCategory.greeter;
          all = set;
          grouped = {
            byKind = mkEqQueries {
              inherit set;
              field = "kind";
            };
            byToolkit = mkEqQueries {
              inherit set;
              field = "toolkit";
            };
            byProtocol = mkProtocolGroup set;
          };
          queried =
            (mkIndependenceQueries set)
            // (mkMaturityQueries set)
            // {
              isGraphical = withEq {
                inherit set;
                field = "display";
                value = "graphical";
              };
              isTerminal = withEq {
                inherit set;
                field = "display";
                value = "terminal";
              };
            };
        in {inherit all grouped queried;};

        notifiers = let
          set = byCategory.notifier;
          all = set;
          grouped = {
            byMaturity = mkMaturityGroup {
              inherit set;
              default = "unknown";
            };
            byProtocol = mkProtocolGroup set;
            byConfigLanguage = mkMemberQueries {
              inherit set;
              field = "config";
            };
          };
          queried =
            (mkIndependenceQueries set)
            // (mkMaturityQueries set)
            // (mkProtocolQueries set);
        in {inherit all grouped queried;};

        panels = let
          set = byCategory.panel;
          all = set;
          grouped = {
            byToolkit = mkEqQueries {
              inherit set;
              field = "toolkit";
              default = "unknown";
            };
            byMaturity = mkMaturityGroup {inherit set;};
            byProtocol = mkProtocolGroup set;
            byConfigLanguage = mkMemberQueries {
              inherit set;
              field = "config";
            };
            byEngineLanguage = mkMemberQueries {
              inherit set;
              field = "engine";
            };
          };
          queried =
            (mkIndependenceQueries set)
            // (mkMaturityQueries set)
            // (mkProtocolQueries set);
        in {inherit all grouped queried;};

        protocols = let
          set = byCategory.protocol;
          all = set;
          grouped = {
            byCapability = mkCapabilityGroup set;
            bySurface = mkEqQueries {
              inherit set;
              field = "surface";
            };
            byMaturity = mkMaturityGroup {inherit set;};
          };
          queried =
            (mkCapabilityQueries set)
            // (mkMaturityQueries set);
        in {inherit all grouped queried;};
      in {
        inherit
          all
          compositors
          environments
          greeters
          notifiers
          panels
          protocols
          ;
      };
    in {inherit needsTerminal shell interface;};
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
