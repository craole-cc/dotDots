{_, ...}: let
  meta = let
    doc = ''
      Application filters (Layer 4).

      Partitions the application registry into typed, queryable subsets.
      Each top-level key maps to a domain section exposing
      { all, default, groups, queries } via mkSection. Sub-sections refine
      by category intersection, boolean flags, or protocol affinity.

      Top-level sections:
        needsTerminal  — apps requiring a host terminal emulator
        shell          — shells, prompts, enhancements, line editors
        interface      — compositors, environments, greeters, notifiers, panels, protocols
        terminal       — terminal emulators (with wayland/xorg/wrappable sub-sets)
        launcher       — app launchers (standalone and builtin)
        editor         — text editors, IDEs, database editors
        browser        — web browsers (by family and channel)
        fileManager    — file managers (graphical and TUI)
        media          — media players and audio apps
        graphics       — image and graphics editors
        office         — office and document apps
        communication  — messengers and email clients
        monitor        — system monitors (graphical and TUI)

      Top-level partitions by category, family, and channel are
      available under filters.groups.

      Depends on: applications {groups, queries, selection, primitives}.
    '';

    functions = {
      inherit mkFilters mkSection;
      mkFilterSection = mkSection;
    };

    exports = {
      local = default // functions;
      alias = {
        toApplicationFilters = mkFilters;
        # toApplicationFilterSection = mkSection;
      };
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.applications.groups) mkGroups;
  inherit (_.applications.primitives) keysFromMembers keysFromOptional;
  inherit (_.applications.queries) mkQueries;
  inherit (_.applications.selection) resolveConfig withFlag;
  inherit (_.attrsets.construction) genAttrs;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.predicates) isIn;
  registry = _.applications.registry.all;

  /**
  Build a standard section from an application set, producing a consistent
  `{ all, default, groups, queries }` shape.

  # Type
  ```nix
  mkSection :: {
    set       :: AttrSet,
    groupArgs :: AttrSet,
    queryArgs :: AttrSet,
  } -> { all :: AttrSet, default :: AttrSet, groups :: AttrSet, queries :: AttrSet }
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
  family, and channel.

  # Type
  ```nix
  mkFilters :: {
    registry :: AttrSet,
    groups   :: AttrSet,
    queries  :: AttrSet -> AttrSet,
  } -> { default :: AttrSet, groups :: AttrSet, queries :: AttrSet }
  ```
  */
  mkFilters = {
    registry,
    groups ? {},
    queries ? (_: {}),
  }: let
    byCategory = genAttrs (keysFromMembers "categories" registry) (
      category: filterAttrs (_: app: isIn category (app.categories or [])) registry
    );
    byFamily = genAttrs (keysFromOptional "family" registry) (
      family: filterAttrs (_: app: (app.family or null) == family) registry
    );
    byChannel = genAttrs (keysFromOptional "channel" registry) (
      channel: filterAttrs (_: app: (app.channel or null) == channel) registry
    );
    ofCategory = category: byCategory.${category} or {};
  in {
    default = registry;
    groups =
      {
        inherit
          byCategory
          byFamily
          byChannel
          ofCategory
          ;
      }
      // groups;
    queries = queries {inherit byCategory byFamily byChannel;};
  };

  default = mkFilters {
    inherit registry;
    queries = {byCategory, ...}: let
      /**
      Applications that must be launched inside a terminal emulator.
      */
      needsTerminal = withFlag {
        field = "needsTerminal";
        set = registry;
      };

      /**
      Shell-related applications: pure shells, prompts, enhancements, line editors.
      */
      shell = let
        all = byCategory.shell;
      in {
        inherit all;
        shells = mkSection {set = resolveConfig (filterAttrs (_: a: (a.categories or []) == ["shell"]) all);};
        prompts = mkSection {set = byCategory.prompt;};
        enhancements = mkSection {set = byCategory.enhancement;};
        lineEditors = mkSection {set = byCategory."line-editor";};
      };

      /**
      Interface-related applications: compositors, environments, greeters,
      notifiers, panels, and display protocols.
      */
      interface = let
        all = byCategory.interface;
      in {
        inherit all;
        compositors = mkSection {set = byCategory.compositor;};
        environments = mkSection {set = byCategory.environment;};
        greeters = mkSection {set = byCategory.greeter;};
        notifiers = mkSection {set = byCategory.notifier;};
        panels = mkSection {set = byCategory.panel;};
        protocols = mkSection {set = byCategory.protocol;};
      };

      /**
      Terminal emulators. Protocol affinity and wrap capability are exposed
      as queries rather than sub-sections — use `terminal.queries.forWayland`,
      `terminal.queries.forXorg`, and `terminal.queries.isWrappable` directly.
      */
      terminal = mkSection {set = mapAttrs (_: a: a // {wrappable = (a.wrap or null) != null;}) byCategory.terminal;};

      /**
      Application launchers and runners. `builtin` entries are provided
      by a desktop environment and have no standalone exec.
      */
      launcher = mkSection {set = mapAttrs (_: a: a // {builtin = a.builtin or false;}) byCategory.launcher;};

      /**
      Text editors and IDEs. Category membership distinguishes pure editors,
      IDEs, and database editors — use `editor.queries.forIde`,
      `editor.queries.forDatabase`, and `editor.queries.isTui` directly.
      */
      editor = mkSection {set = byCategory.editor;};

      /**
      Web browsers. `family` partitions by engine lineage
      (chromium, firefox, zen, etc.) and `channel` by release track
      (stable, esr, nightly, beta, twilight).
      */
      browser = mkSection {set = byCategory.browser;};

      /**
      File managers, both graphical and terminal-based.
      `needsTerminal` entries (lf, yazi, ranger, nnn, broot) require
      a host terminal emulator to launch.
      */
      fileManager = mkSection {set = byCategory."file-manager";};

      /**
      Media players and audio applications.
      */
      media = mkSection {set = byCategory.media;};

      /**
      Graphics and image editing applications.
      */
      graphics = mkSection {set = byCategory.graphics;};

      /**
      Office, productivity, and document viewer applications.
      */
      office = mkSection {set = byCategory.office;};

      /**
      Communication applications. Sub-sections split by protocol role:
      instant messengers and email clients.
      */
      communication = mkSection {set = byCategory.communication;};

      /**
      System monitoring applications. All entries carry `needsTerminal`
      (btop, htop, nvtop) or are graphical (mission-center, gnome-system-monitor).
      Sub-sections split by UI style.
      */
      monitor = mkSection {set = byCategory.monitor;};
    in {
      inherit
        needsTerminal
        shell
        interface
        terminal
        launcher
        editor
        browser
        fileManager
        media
        graphics
        office
        communication
        monitor
        ;
    };
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
