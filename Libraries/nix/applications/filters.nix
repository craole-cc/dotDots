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

  mkLengthQueries = {
    field,
    singleKey,
    multiKey,
    set,
  }: {
    ${singleKey} =
      filterAttrs
      (_: a: length (a.${field} or []) == 1)
      set;
    ${multiKey} =
      filterAttrs
      (_: a: length (a.${field} or []) > 1)
      set;
  };

  mkScopeQueries = {
    set,
    field,
    singleKey,
    multiKey,
  }:
    mkLengthQueries {inherit set field singleKey multiKey;};

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

  mkIndependenceQueries = set:
    mkBoolQueries {
      inherit set;
      field = "independent";
      trueKey = "independent";
      falseKey = "integrated";
    };

  mkMaturityQueries = set: {
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
    legacy = withEq {
      inherit set;
      field = "maturity";
      value = "legacy";
    };
  };

  mkProtocolQueries = set: {
    onWayland = withMember {
      inherit set;
      field = "protocol";
      value = "wayland";
    };
    onKMS = withMember {
      inherit set;
      field = "protocol";
      value = "kms";
    };
    onTTY = withMember {
      inherit set;
      field = "protocol";
      value = "tty";
    };
    onXorg = withMember {
      inherit set;
      field = "protocol";
      value = "xorg";
    };
  };

  mkCapabilityQueries = set: {
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

  mkConfigQueries = set: {
    configurable =
      filterAttrs
      (_: a: (a.config or null) != null)
      set;
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
      in {
        inherit all;
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
            byConfig = mkEqQueries {
              inherit set;
              field = "fileName";
            };
          };

          queried = let
            profileOnly = grouped.byFile.".profile" or {};
            configurable = removeAttrs all (attrNames profileOnly);
          in
            {
              inherit configurable;
              system = withFlag {
                inherit set;
                field = "system";
              };
              interactive = withFlag {
                inherit set;
                field = "interactive";
              };
            }
            // mkMaturityQueries set
            // mkBoolQueries {
              inherit set;
              field = "posix";
              trueKey = "posix";
              falseKey = "modern";
            };
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

          queried =
            {}
            // mkConfigQueries set
            // mkMaturityQueries set
            // mkScopeQueries {
              inherit set;
              field = "shells";
              singleKey = "singleShell";
              multiKey = "multiShell";
            };
        in {inherit all grouped queried;};

        enhancements = let
          set = byCategory.enhancement;
          all = set;

          grouped = {
            byKind = mkEqQueries {
              inherit set;
              field = "kind";
            };
            byShell = mkMemberQueries {
              inherit set;
              field = "shells";
            };
            byEngine = mkMemberQueries {
              inherit set;
              field = "engine";
            };
            byMaturity = mkMaturityGroup {inherit set;};
          };

          queried =
            {
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
            }
            // mkConfigQueries set
            // mkMaturityQueries set
            // mkScopeQueries {
              inherit set;
              field = "shells";
              singleKey = "singleShell";
              multiKey = "multiShell";
            };
        in {inherit all grouped queried;};

        lineEditors = let
          set = byCategory."line-editor";
          all = set;
          grouped = {
            byEngine = mkMemberQueries {
              inherit set;
              field = "engine";
            };
            byShell = mkMemberQueries {
              inherit set;
              field = "shells";
            };
            byMaturity = mkMaturityGroup {inherit set;};
          };
          queried =
            {}
            // (mkConfigQueries set)
            // (mkMaturityQueries set)
            // (mkScopeQueries {
              inherit set;
              field = "shells";
              singleKey = "singleShell";
              multiKey = "multiShell";
            });
        in {inherit all grouped queried;};
      };

      interface = let
        set = byCategory.interface;
        all = set;

        compositors = let
          set = byCategory.compositor;
          all = set;
          grouped = {
            byProtocol = mkProtocolGroup set;
            byRole = mkEqQueries {
              inherit set;
              field = "role";
            };
            byMaturity = mkMaturityGroup {inherit set;};
          };
          queried =
            {}
            // (mkMaturityQueries set)
            // (mkProtocolQueries set)
            // (mkConfigQueries set);
        in {inherit all grouped queried;};

        environments = let
          set = byCategory.environment;
          all = set;

          grouped = {
            byCompositor = mkEqQueries {
              inherit set;
              field = "compositor";
            };
            byPanel = mkMemberQueries {
              inherit set;
              field = "panel";
            };
            byScope = mkEqQueries {
              inherit set;
              field = "scope";
            };
            byLayout = mkMemberQueries {
              inherit set;
              field = "layouts";
            };
            byProtocol = mkProtocolGroup set;
            byGreeter = mkMemberQueries {
              inherit set;
              field = "greeters";
            };
          };

          queried =
            {
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
            }
            // mkProtocolQueries set
            // mkEqQueries {
              inherit set;
              field = "scope";
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
            {}
            // mkIndependenceQueries set
            // mkMaturityQueries set
            // mkEqQueries {
              inherit set;
              field = "toolkit";
            }
            // mkEqQueries {
              inherit set;
              field = "kind";
            };
        in {inherit all grouped queried;};

        notifiers = let
          set = byCategory.notifier;
          all = set;

          grouped = {
            byMaturity = mkMaturityGroup {inherit set;};
            byProtocol = mkProtocolGroup set;
            byConfigLanguage = mkMemberQueries {
              inherit set;
              field = "config.lang";
            };
          };

          queried =
            {}
            // mkIndependenceQueries set
            // mkMaturityQueries set
            // mkProtocolQueries set
            // mkConfigQueries set;
        in {inherit all grouped queried;};

        panels = let
          set = byCategory.panel;
          all = set;
          grouped = {
            byToolkit = mkEqQueries {
              inherit set;
              field = "toolkit";
            };
            byMaturity = mkMaturityGroup {inherit set;};
            byProtocol = mkProtocolGroup set;
            byConfigLanguage = mkMemberQueries {
              inherit set;
              field = "config.lang";
            };
            byEngineLanguage = mkMemberQueries {
              inherit set;
              field = "engine";
            };
          };
          queried =
            {}
            // mkIndependenceQueries set
            // mkMaturityQueries set
            // mkProtocolQueries set
            // mkConfigQueries set
            // mkEqQueries {
              inherit set;
              field = "toolkit";
            };
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
            {}
            // mkCapabilityQueries set
            // mkMaturityQueries set
            // mkEqQueries {
              inherit set;
              field = "surface";
            };
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
