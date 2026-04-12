{
  _,
  __moduleDir,
  ...
}: let
  inherit (_.applications.groups) mkStandardGroups;
  inherit (_.applications.primitives) keysFromMembers keysFromOptional;
  inherit (_.applications.queries) mkQueries mkStandardQueries;
  inherit (_.applications.selection) resolveConfig withFlag;
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
    groups = {inherit byCategory byFamily byChannel ofCategory;} // groups;
    queries = queries {inherit byCategory byFamily byChannel;};
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

        shells = let
          set = resolveConfig (
            filterAttrs (_: a: (a.categories or []) == ["shell"]) all
          );
          groups = mkStandardGroups {
            inherit set;
            member = ["engine"];
            fields = ["config" "maturity"];
          };
          queries = mkStandardQueries {
            inherit set;
            flags = [
              {
                field = "posix";
                trueKey = "posix";
                falseKey = "modern";
              }
            ];
          };
        in {
          inherit groups queries;
          default = set;
        };

        prompts = let
          set = byCategory.prompt;
          groups = mkStandardGroups {
            inherit set;
            member = ["engine" "shells"];
            fields = ["maturity"];
          };
          queries = mkStandardQueries {inherit set;};
        in {
          inherit groups queries;
          default = set;
        };

        enhancements = let
          set = byCategory.enhancement;
          groups = mkStandardGroups {
            inherit set;
            eq = ["kind"];
            member = ["shells" "engine"];
            fields = ["maturity"];
          };
          queries = mkStandardQueries {
            inherit set;
            support = {inherit (groups.byKind) history fuzzy navigation;};
          };
        in {
          inherit groups queries;
          default = set;
        };

        lineEditors = let
          set = byCategory."line-editor";
          groups = mkStandardGroups {
            inherit set;
            member = ["engine" "shells"];
            fields = ["maturity"];
          };
          queries = mkStandardQueries {inherit set;};
        in {
          inherit groups queries;
          default = set;
        };
      };

      interface = let
        all = byCategory.interface;
      in {
        inherit all;

        compositors = let
          set = byCategory.compositor;
          groups = mkStandardGroups {
            inherit set;
            eq = ["role"];
            fields = ["protocol" "maturity"];
          };
          queries = mkStandardQueries {inherit set;};
        in {
          inherit groups queries;
          default = set;
        };

        environments = let
          set = byCategory.environment;

          groups = mkStandardGroups {
            inherit set;
            eq = ["compositor" "scope"];
            member = ["panel" "layouts" "greeters"];
            fields = ["protocol" "maturity"];
          };

          queries = mkStandardQueries {
            inherit set;
            support = ["layouts"];
          };
        in {
          inherit groups queries;
          default = set;
        };

        greeters = let
          set = byCategory.greeter;
          groups = mkStandardGroups {
            inherit set;
            eq = ["kind" "toolkit"];
            fields = ["protocol"];
          };
          queries = mkStandardQueries {inherit set;};
        in {
          inherit groups queries;
          default = set;
        };

        notifiers = let
          set = byCategory.notifier;
          groups = mkStandardGroups {
            inherit set;
            member = ["config.lang"];
            fields = ["maturity" "protocol"];
          };
          queries = mkStandardQueries {inherit set;};
        in {
          inherit groups queries;
          default = set;
        };

        panels = let
          set = byCategory.panel;
          groups = mkStandardGroups {
            inherit set;
            eq = ["toolkit"];
            member = ["config.lang" "engine"];
            fields = ["maturity" "protocol"];
          };
          queries = mkStandardQueries {inherit set;};
        in {
          inherit groups queries;
          default = set;
        };

        protocols = let
          set = byCategory.protocol;
          groups = mkStandardGroups {
            inherit set;
            eq = ["surface"];
            fields = ["capability" "maturity"];
          };
          queries = mkQueries {inherit set;};
        in {
          inherit groups queries;
          default = set;
        };
      };
    in {inherit needsTerminal shell interface;};
  };
in
  _.meta.mkModuleExports {
    directory = __moduleDir;
    doc = ''
      Application filters (Layer 4).

      Partitions the application registry into typed, queryable subsets.
      Provides pre-built filters for shells and interfaces, including
      grouped sub-sets and queries derived from standard field builders.

      Depends on: applications.{groups, queries, selection, primitives}.
    '';

    functions = default // {inherit mkFilters;};
  }
