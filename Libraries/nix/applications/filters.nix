{
  _,
  __moduleDir,
  ...
}: let
  inherit (_.applications.groups) mkStandardGroups;
  inherit (_.applications.primitives) keysFromMembers keysFromOptional normalizeConfig;
  inherit (_.applications.queries) mkStandardQueries mkCapabilityQueries mkBoolQueries;
  inherit (_.applications.selection) withFlag;
  inherit (_.attrsets.construction) genAttrs;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.lists.predicates) isIn;
  registry = _.applications.registry.default;

  mkFilters = {
    registry,
    groups ? {},
    queries ? (_: {}),
  }: let
    byCategory = genAttrs (keysFromMembers "categories" registry) (
      category:
        filterAttrs (_: app: isIn category (app.categories or [])) registry
    );

    byFamily = genAttrs (keysFromOptional "family" registry) (
      family:
        filterAttrs (_: app: (app.family or null) == family) registry
    );

    byChannel = genAttrs (keysFromOptional "channel" registry) (
      channel:
        filterAttrs (_: app: (app.channel or null) == channel) registry
    );

    ofCategory = category: byCategory.${category} or {};
  in {
    default = registry;
    groups =
      {inherit byCategory byFamily byChannel ofCategory;}
      // groups;
    queries = queries {inherit byCategory byFamily byChannel;};
  };

  mkSection = {
    set,
    grouped ? {},
    queryField ? null,
    extraQueries ? (_: {}),
  }: let
    groups = mkStandardGroups ({inherit set;} // grouped);
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

  default = mkFilters {
    inherit registry;
    queries = {byCategory, ...}: let
      needsTerminal = withFlag {
        field = "needsTerminal";
        set = registry;
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
  _.meta.mkModuleExports {
    directory = __moduleDir;
    doc = ''
      Application enums (Layer 4).

      Converts the application registry into typed enums, recursively
      walking nested registry trees and wrapping leaf sets with `mkEnum`.
      Provides pre-built enums for shells and interfaces, including
      queried sub-enums with optional nullability overrides.

      Depends on: applications.queries lists.construction.
    '';

    functions = default // {inherit mkFilters mkSection;};
  }
