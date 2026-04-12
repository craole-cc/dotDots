{
  _,
  __moduleDir,
  ...
}: let
  inherit (_.applications.groups) mkGroups;
  inherit (_.applications.primitives) keysFromMembers keysFromOptional;
  inherit (_.applications.queries) mkQueries;
  inherit (_.applications.selection) resolveConfig withFlag;
  inherit (_.attrsets.construction) genAttrs;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.lists.predicates) isIn;
  registry = _.applications.registry.all;

  /**
  Build a standard section from an application set, producing a consistent
  `{ all, default, groups, queries }` shape. `all` and `default` both expose
  the raw set — `all` for flat enumeration, `default` for fallback selection.
  `groups` and `queries` are derived via `mkGroups` and `mkQueries` respectively,
  with optional overrides passed through `groupArgs` and `queryArgs`.

  # Type
  ```nix
  mkSection :: {
    set       :: AttrSet,
    groupArgs :: AttrSet,  # optional, merged into mkGroups call
    queryArgs :: AttrSet,  # optional, merged into mkQueries call
  } -> { all :: AttrSet, default :: AttrSet, groups :: AttrSet, queries :: AttrSet }
  ```

  # Examples
  ```nix
  mkSection { set = byCategory.greeter; }
  # => {
  #   all     = { gdm = ...; lightdm = ...; };
  #   default = { gdm = ...; lightdm = ...; };
  #   groups  = { byMaturity = ...; byProtocol = ...; };
  #   queries = { forWayland = ...; isStable = ...; };
  # }

  mkSection {
    set       = byCategory.prompt;
    groupArgs = { member = ["engine" "shells"]; fields = ["maturity"]; };
  }
  # => { all = ...; default = ...; groups = ...; queries = ...; }
  ```
  */
  mkSection = {
    set,
    groupArgs ? {},
    queryArgs ? {},
  }: {
    all = set;
    default = set;
    groups = mkGroups ({inherit set;} // groupArgs);
    queries = mkQueries ({inherit set;} // queryArgs);
  };

  /**
  Build a filter tree from an arbitrary registry, partitioned by category,
  family, and channel. Accepts optional `groups` and `queries` overrides to
  extend the base partitions with domain-specific structure.

  `queries` receives `{ byCategory, byFamily, byChannel }` and returns an
  attrset of named query trees.

  # Type
  ```nix
  mkFilters :: {
    registry :: AttrSet,
    groups   :: AttrSet,        # optional, merged into base groups
    queries  :: AttrSet -> AttrSet, # optional, receives partition maps
  } -> { default :: AttrSet, groups :: AttrSet, queries :: AttrSet }
  ```

  # Examples
  ```nix
  mkFilters {
    registry = { a = { categories = ["shell"]; }; };
  }
  # => {
  #   default = { a = ...; };
  #   groups  = { byCategory = { shell = { a = ...; }; }; byFamily = {}; byChannel = {}; ofCategory = <fn>; };
  #   queries = {};
  # }
  ```
  */
  mkFilters = {
    registry,
    groups ? {},
    queries ? (_: {}),
  }: let
    byCategory =
      genAttrs
      (keysFromMembers "categories" registry) (
        category:
          filterAttrs
          (_: app: isIn category (app.categories or []))
          registry
      );
    byFamily =
      genAttrs
      (keysFromOptional "family" registry) (
        family:
          filterAttrs
          (_: app: (app.family or null) == family)
          registry
      );
    byChannel =
      genAttrs
      (keysFromOptional "channel" registry) (
        channel:
          filterAttrs
          (_: app: (app.channel or null) == channel)
          registry
      );
    ofCategory = category: byCategory.${category} or {};
  in {
    default = registry;
    groups =
      {inherit byCategory byFamily byChannel ofCategory;}
      // groups;
    queries = queries {inherit byCategory byFamily byChannel;};
  };

  all = mkFilters {
    inherit registry;
    queries = {byCategory, ...}: let
      /**
      Applications that must be launched inside a terminal emulator.
      Derived from the `needsTerminal` boolean flag on the registry.
      */
      needsTerminal = withFlag {
        field = "needsTerminal";
        set = registry;
      };

      /**
      Shell-related applications, partitioned into sub-sections by category.
      `all` is the full `shell` category; sub-sections refine by single-category
      membership or exact category match.
      */
      shell = let
        all = byCategory.shell;
      in {
        inherit all;

        #? Pure shells — entries whose categories list is exactly ["shell"],
        #? with config resolved to normalise nested attrsets.
        shells = mkSection {
          set = resolveConfig (
            filterAttrs (_: a: (a.categories or []) == ["shell"]) all
          );
        };

        #? Shell prompt themes and frameworks.
        prompts = mkSection {set = byCategory.prompt;};

        #? Shell enhancement plugins (history, fuzzy-find, navigation, etc.).
        enhancements = mkSection {set = byCategory.enhancement;};

        #? Readline-style line editing libraries used by shells.
        lineEditors = mkSection {set = byCategory."line-editor";};
      };

      /**
      Interface-related applications, partitioned into sub-sections by category.
      `all` is the full `interface` category.
      */
      interface = let
        all = byCategory.interface;
      in {
        inherit all;

        #? Wayland/X11 compositors.
        compositors = mkSection {set = byCategory.compositor;};

        #? Desktop environments.
        environments = mkSection {set = byCategory.environment;};

        #? Display managers and login greeters.
        greeters = mkSection {set = byCategory.greeter;};

        #? Desktop notification daemons.
        notifiers = mkSection {set = byCategory.notifier;};

        #? Taskbars, status bars, and panel applications.
        panels = mkSection {set = byCategory.panel;};

        #? Display protocols (Wayland, Xorg, KMS, TTY).
        protocols = mkSection {set = byCategory.protocol;};
      };
    in {inherit needsTerminal shell interface;};
  };
in
  _.meta.mkModuleExports {
    directory = __moduleDir;
    doc = ''
      Application filters (Layer 4).

      Partitions the application registry into typed, queryable subsets.
      Provides pre-built filters for shells and interfaces, each exposing
      { all, default, groups, queries } via mkSection. Top-level partitions
      by category, family, and channel are available under filters.groups.

      Depends on: applications {groups, queries, selection, primitives}.
    '';

    functions = all // {inherit mkFilters mkSection;};
  }
