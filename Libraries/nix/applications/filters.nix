{_, ...}: let
  __exports = {
    internal = filters;
    external.applicationFilters = filters;
  };

  inherit (_.applications.construction) mkFilters;
  inherit (_.applications.enums) categories channels families;
  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.construction) genAttrs;
  inherit (_.attrsets.transformation) filterAttrs;
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
    filterAttrs (_: a: (a.${field} or false)) set;

  withoutFlag = {
    field,
    set,
  }:
    filterAttrs (_: a: !(a.${field} or false)) set;

  withEq = {
    field,
    default ? null,
    value,
    set,
  }:
    filterAttrs (_: a: (a.${field} or default) == value) set;

  withNeq = {
    field,
    default ? null,
    value,
    set,
  }:
    filterAttrs (_: a: (a.${field} or default) != value) set;

  withMember = {
    field,
    value,
    set,
  }:
    filterAttrs (_: a: isIn value (a.${field} or [])) set;

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
          set =
            filterAttrs
            (_: a: (a.categories or []) == ["shell"])
            byCategory.shell;
          all = set;
          grouped = {
            byLanguage = groupBy {
              field = "language";
              keys = unique (
                map
                (a: a.language or "unknown")
                (attrValues all)
              );
              inherit set;
            };
          };
          queried = {
            system = withFlag {
              field = "system";
              inherit set;
            };
            interactive = withFlag {
              field = "interactive";
              inherit set;
            };
            posix = withFlag {
              field = "posix";
              inherit set;
            };
            modern = withoutFlag {
              field = "posix";
              inherit set;
            };
          };
          # flattened = all // grouped // queried;
        in {inherit all grouped queried;};

        prompts = let
          set = byCategory.prompt;
          all = set;
          grouped = {
            byShell = groupByMember {
              inherit set;
              field = "shells";
              keys = unique (
                concatMap
                (a: a.shells or [])
                (attrValues all)
              );
            };
            byLanguage = groupBy {
              inherit set;
              field = "language";
              keys = unique (
                map
                (a: a.language or "unknown")
                (attrValues all)
              );
            };
            byMaturity = groupBy {
              inherit set;
              field = "maturity";
              keys = unique (
                map
                (a: a.maturity  or "unknown")
                (attrValues all)
              );
            };
          };
          queried = {
            configurable =
              filterAttrs
              (_: a: (a.config or null) != null)
              all;
            crossShell =
              filterAttrs
              (_: a: length (a.shells or []) > 1)
              all;
            singleShell =
              filterAttrs
              (_: a: length (a.shells or []) == 1)
              all;
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
              keys = unique (
                map
                (a: a.kind or "unknown")
                (attrValues all)
              );
            };
            byShell = groupByMember {
              inherit set;
              field = "shells";
              keys = unique (
                concatMap
                (a: a.shells or [])
                (attrValues all)
              );
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
              keys = unique (
                concatMap
                (a: a.shells or [])
                (attrValues all)
              );
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
      in {
        inherit
          all
          shells
          prompts
          enhancements
          lineEditors
          ;
      };

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
              keys = protocolNames;
            };
            byRole = groupBy {
              inherit set;
              field = "role";
              keys = unique (
                map
                (a: a.role or "unknown")
                (attrValues all)
              );
            };
            byMaturity = groupBy {
              inherit set;
              field = "maturity";
              keys = unique (
                map
                (a: a.maturity or "unknown")
                (attrValues all)
              );
            };
          };
          queried = {};
        in {inherit all grouped queried;};

        environments = let
          set = byCategory.environment;
          all = set;
          grouped = {
            byCompositor = groupBy {
              field = "compositor";
              default = "none";
              keys = unique (map (a: a.compositor or "none") (attrValues set));
              inherit set;
            };
            byPanel = groupByMember {
              field = "panel";
              keys = unique (concatMap (a: a.panel or []) (attrValues set));
              inherit set;
            };
            byScope = groupBy {
              field = "scope";
              default = "unknown";
              keys = unique (
                map
                (a: a.scope or "unknown")
                (attrValues set)
              );
              inherit set;
            };
            byLayout = groupByMember {
              field = "layouts";
              keys = ["tiling" "floating" "stacking"];
              inherit set;
            };
            byProtocol = groupByMember {
              field = "protocol";
              keys = protocolNames;
              inherit set;
            };
            byGreeter = groupByMember {
              field = "greeters";
              keys = greeterNames;
              inherit set;
            };
          };
          queried = {
            desktop = withEq {
              field = "scope";
              default = null;
              value = "desktop";
              inherit set;
            };
            compositor = withEq {
              field = "scope";
              default = null;
              value = "compositor";
              inherit set;
            };
            tiling = withMember {
              field = "layouts";
              value = "tiling";
              inherit set;
            };
            floating = withMember {
              field = "layouts";
              value = "floating";
              inherit set;
            };
            stacking = withMember {
              field = "layouts";
              value = "stacking";
              inherit set;
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
            byProtocol = mkMemberQueries {
              inherit set;
              field = "protocol";
            };
          };

          queried = let
            independence = mkBoolQueries {
              inherit set;
              field = "independent";
              trueKey = "independent";
              falseKey = "integrated";
            };
            maturity = {
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
            };
            display = {
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
          in
            independence // maturity // display;
        in {inherit all grouped queried;};

        notifiers = let
          set = byCategory.notifier;
          all = set;

          grouped = {
            byMaturity = mkEqQueries {
              inherit set;
              field = "maturity";
              default = "unknown";
            };
            byProtocol = mkMemberQueries {
              inherit set;
              field = "protocol";
            };
            byConfigLanguage = mkMemberQueries {
              inherit set;
              field = "config";
            };
          };

          queried = let
            independence = mkBoolQueries {
              inherit set;
              field = "independent";
              trueKey = "independent";
              falseKey = "integrated";
            };
            maturity = {
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
            };
            protocol = {
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
          in
            independence // maturity // protocol;
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
            byMaturity = mkEqQueries {
              inherit set;
              field = "maturity";
            };
            byProtocol = mkMemberQueries {
              inherit set;
              field = "protocol";
            };
            byConfigLanguage = mkMemberQueries {
              inherit set;
              field = "config";
            };
            byEngineLanguage = mkMemberQueries {
              inherit set;
              field = "engine";
            };
          };
          queried = let
            independence = mkBoolQueries {
              inherit set;
              field = "independent";
              trueKey = "independent";
              falseKey = "integrated";
            };
            maturity = {
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
            };
            protocol = {
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
          in
            independence // maturity // protocol;
        in {inherit all grouped queried;};

        protocols = let
          set = byCategory.protocol;
          all = set;
          grouped = {
            byCapability = {
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
            bySurface = mkEqQueries {
              inherit set;
              field = "surface";
            };
            byMaturity = mkEqQueries {
              inherit set;
              field = "maturity";
            };
          };
          queried = let
            capabilities = {
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
            maturity = {
              isStable = withEq {
                inherit set;
                field = "maturity";
                value = "stable";
              };
              isLegacy = withEq {
                inherit set;
                field = "maturity";
                value = "legacy";
              };
            };
          in
            capabilities // maturity;
        in {inherit all grouped queried;};
      in {
        inherit
          all
          # grouped
          # queried
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
