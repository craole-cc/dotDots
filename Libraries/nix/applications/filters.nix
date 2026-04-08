{_, ...}: let
  __exports = {
    internal = filters;
    external.applicationFilters = filters;
  };

  inherit (_.applications.construction) mkFilters;
  inherit (_.applications.enums) categories channels families;
  inherit (_.attrsets.access) attrByPath attrNames attrValues;
  inherit (_.attrsets.construction) genAttrs optionalAttrs;
  inherit (_.attrsets.merging) recursiveUpdate;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs setAttrByPath;
  inherit (_.strings.transformation) toCamel;
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
    value,
    set,
  }:
    filterAttrs
    (_: a: (a.${field} or null) == value)
    set;

  withNeq = {
    field,
    default ? null,
    value ? null,
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

  normalizeConfig = {
    set,
    path ? ["config"],
  }:
    mapAttrs (
      _: a: let
        cfg = attrByPath path null a;
      in
        if cfg != null && cfg.home != null && cfg.file != null
        then
          recursiveUpdate a (
            setAttrByPath
            path
            (cfg // {path = "${cfg.home}/${cfg.file}";})
          )
        else a
    )
    set;

  groupBy = {
    field,
    keys,
    set,
  }:
    genAttrs keys (value:
      withEq {inherit field set value;});

  groupByMember = {
    field,
    keys,
    set,
  }:
    genAttrs keys (value:
      withMember {inherit field set value;});

  #╔═══════════════════════════════════════════════════════════╗
  #║ Builders                                                  ║
  #╚═══════════════════════════════════════════════════════════╝
  # mkCategory = {
  #   set,
  #   config ? {},
  # }: let
  #   all = set;
  #   groups = config.groups or {};
  #   queries = config.queries or {};
  # in {
  #   inherit all groups queries;
  #   # groups =
  #   #   groups
  #   #   // {
  #   #     byMaturity = mkMaturityGroup {inherit set;};
  #   #     byProtocol = optionalAttrs (set?protocol) (mkProtocolGroup set);
  #   #   };
  #   # queries = queries // mkStandardQueries {inherit set;};
  # };

  #╔═══════════════════════════════════════════════════════════╗
  #║ Group Helpers                                             ║
  #╚═══════════════════════════════════════════════════════════╝
  mkStandardGrouped = {
    set,
    fields,
  }:
    genAttrs fields (
      field:
        if field == "maturity"
        then mkMaturityGroup {inherit set;}
        else if field == "protocol"
        then mkProtocolGroup {inherit set;}
        else if field == "config"
        then mkConfigFileGroup {inherit set;}
        else mkMemberQueries {inherit set field;}
    );

  #> Groups shells by their config.file value (e.g. ".bashrc", ".zshrc")
  #? Entries without a config are silently excluded.
  mkConfigFileGroup = {set}: let
    withCfg = filterAttrs (_: a: a.config or null != null) set;
    keys = unique (map (a: a.config.file) (attrValues withCfg));
  in
    genAttrs keys (
      k:
        filterAttrs (_: a: (a.config or null) != null && a.config.file == k) set
    );
  #╔═══════════════════════════════════════════════════════════╗
  #║ Query Helpers                                             ║
  #╚═══════════════════════════════════════════════════════════╝
  mkFieldQueries = {
    set,
    field,
    values ? null,
    queryType ? "eq", # "eq", "member", "flag"
  }: let
    mkQuery =
      {
        "eq" = value: withEq {inherit set field value;};
        "member" = value: withMember {inherit set field value;};
        "flag" = _: withFlag {inherit set field;};
      }.${
        queryType
      };
  in
    if values == null
    then {}
    else genAttrs values mkQuery;

  mkStandardQueries = {
    set,
    field ? "shells",
  }:
    {}
    // mkConfigQueries {inherit set;}
    // mkIndependenceQueries {inherit set;}
    // mkMaturityQueries {inherit set;}
    // mkProtocolQueries {inherit set;}
    // optionalAttrs (set?field) (mkScopeQueries {
      inherit set field;
      singleKey = toCamel "single${field}";
      multiKey = toCamel "multi${field}";
    })
    // {};

  mkMaturityQueries = {set}: let
    field = "maturity";
    values = unique (
      map (a: a.${field}) (attrValues (
        filterAttrs (_: a: a.${field} != null) set
      ))
    );
  in
    mkFieldQueries {inherit set field values;};

  mkEqQueries = {
    field,
    set,
  }: let
    keys = unique (
      map (a: a.${field})
      (filter (a: a ? ${field}) (attrValues set))
    );
  in
    groupBy {inherit field keys set;};

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

  mkCapabilityGroup = {set}: {
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

  mkIndependenceQueries = {set}:
    mkBoolQueries {
      inherit set;
      field = "independent";
      trueKey = "independent";
      falseKey = "integrated";
    };

  mkProtocolQueries = {set}: {
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

  mkCapabilityQueries = {set}: {
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

  mkConfigQueries = {set}: let
    #> Pre-filter: only attrs that actually have a config
    withConfig = withNeq {
      inherit set;
      field = "config";
    };

    #> Partition withConfig into profile-only vs everything else
    profileOnly =
      filterAttrs
      (_: a: a.config.file == ".profile")
      withConfig;

    #> Filter our profileOnly and nulls.
    configurable = removeAttrs withConfig (attrNames profileOnly);
  in {inherit profileOnly configurable;};

  #╔═══════════════════════════════════════════════════════════╗
  #║ Core                                                      ║
  #╚═══════════════════════════════════════════════════════════╝
  filters = mkFilters {
    inherit all categories channels families;
    queries = {byCategory, ...}: let
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
          set = normalizeConfig {
            set = filterAttrs (_: a: (a.categories or []) == ["shell"]) byCategory.shell;
          };

          all = set;

          groups = mkStandardGrouped {
            inherit set;
            fields = ["engine" "config" "maturity"];
          };

          queries =
            mkStandardQueries {
              inherit set;
              field = "shells";
            }
            // mkBoolQueries {
              inherit set;
              field = "posix";
              trueKey = "posix";
              falseKey = "modern";
            };
          # queries = mkStandardQueries {
          #   inherit set;
          #   field = "shells";
          # };
          # queried = {
          #   system = withFlag {
          #     inherit set;
          #     field = "system";
          #   };
          #   interactive = withFlag {
          #     inherit set;
          #     field = "interactive";
          #   };
          # };
          # };
          # shells = let
          #   set = mapAttrs (_: val:
          #     val
          #     // {fileName = val.config.file or "none";}) (
          #     filterAttrs
          #     (_: a: (a.categories or []) == ["shell"])
          #     byCategory.shell
          #   );
          #   all = set;
          #   groups = {
          #     byEngine = mkMemberQueries {
          #       inherit set;
          #       field = "engine";
          #     };
          #     byMaturity = mkMaturityGroup {inherit set;};
          #     byConfig = mkEqQueries {
          #       inherit set;
          #       field = "fileName";
          #     };
          #   };
          #   queries = let
          #     profileOnly = groups.byFile.".profile" or {};
          #     configurable = removeAttrs all (attrNames profileOnly);
          #   in
          #     {
          #       inherit configurable;
          #       system = withFlag {
          #         inherit set;
          #         field = "system";
          #       };
          #       interactive = withFlag {
          #         inherit set;
          #         field = "interactive";
          #       };
          #     }
          #     // mkMaturityQueries set
          #     // mkBoolQueries {
          #       inherit set;
          #       field = "posix";
          #       trueKey = "posix";
          #       falseKey = "modern";
          #     };
        in {inherit all groups queries;};

        prompts = let
          set = byCategory.prompt;
          all = set;

          groups = {
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

          queries = mkStandardQueries {
            inherit set;
            field = "shells";
          };
        in {inherit all groups queries;};

        enhancements = let
          set = byCategory.enhancement;
          all = set;

          groups = {
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

          queries =
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
            // mkStandardQueries {
              inherit set;
              field = "shells";
            };
        in {inherit all groups queries;};

        lineEditors = let
          set = byCategory."line-editor";
          all = set;
          # groups = {
          #   byEngine = mkMemberQueries {
          #     inherit set;
          #     field = "engine";
          #   };
          #   byShell = mkMemberQueries {
          #     inherit set;
          #     field = "shells";
          #   };
          #   byMaturity = mkMaturityGroup {inherit set;};
          # };
          groups = mkStandardGrouped {
            inherit set;
            fields = ["engine" "shell" "maturity"];
          };
          queries = mkStandardQueries {
            inherit set;
            field = "shells";
          };
        in {inherit all groups queries;};
      };

      interface = let
        set = byCategory.interface;
        all = set;

        compositors = let
          set = byCategory.compositor;
          all = set;
          groups = {
            byProtocol = mkProtocolGroup set;
            byRole = mkEqQueries {
              inherit set;
              field = "role";
            };
            byMaturity = mkMaturityGroup {inherit set;};
          };
          queries =
            {}
            // (mkMaturityQueries {inherit set;})
            // (mkProtocolQueries {inherit set;})
            // (mkConfigQueries {inherit set;});
        in {inherit all groups queries;};

        environments = let
          set = byCategory.environment;
          all = set;

          groups = {
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

          queries =
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
        in {inherit all groups queries;};

        greeters = let
          set = byCategory.greeter;
          all = set;

          groups = {
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

          queries =
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
        in {inherit all groups queries;};

        notifiers = let
          set = byCategory.notifier;
          all = set;

          groups = {
            byMaturity = mkMaturityGroup {inherit set;};
            byProtocol = mkProtocolGroup {inherit set;};
            byConfigLanguage = mkMemberQueries {
              inherit set;
              field = "config.lang";
            };
          };

          queries = mkStandardQueries {inherit set;};
        in {inherit all groups queries;};

        panels = let
          set = byCategory.panel;
          all = set;
          groups = {
            byToolkit = mkEqQueries {
              inherit set;
              field = "toolkit";
            };
            byMaturity = mkMaturityGroup {inherit set;};
            byProtocol = mkProtocolGroup {inherit set;};
            byConfigLanguage = mkMemberQueries {
              inherit set;
              field = "config.lang";
            };
            byEngineLanguage = mkMemberQueries {
              inherit set;
              field = "engine";
            };
          };
          queries = mkStandardQueries {
            inherit set;
            field = "toolkit";
          };
        in {inherit all groups queries;};

        protocols = let
          set = byCategory.protocol;
          all = set;
          groups = {
            byCapability = mkCapabilityGroup set;
            bySurface = mkEqQueries {
              inherit set;
              field = "surface";
            };
            byMaturity = mkMaturityGroup {inherit set;};
          };
          queries =
            {}
            // mkCapabilityQueries set
            // mkMaturityQueries set
            // mkEqQueries {
              inherit set;
              field = "surface";
            };
        in {inherit all groups queries;};
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
