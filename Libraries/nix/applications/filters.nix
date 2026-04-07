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
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.transformation) unique;
  all = _.applications.registry;

  filters = mkFilters {
    inherit all categories channels families;
    queried = {byCategory, ...}: {
      needsTerminal =
        filterAttrs (_: a: a.needsTerminal or false) all;

      shell = let
        all = byCategory.shell;
        languages = unique (map (a: a.language or "unknown") (attrValues all));
      in {
        inherit all;
        grouped = {
          byLanguage =
            genAttrs languages
            (l: filterAttrs (_: a: (a.language or "unknown") == l) all);
          prompts = byCategory.prompt;
          enhancements = byCategory.enhancement;
          lineEditors = byCategory."line-editor";
        };
        queried = {
          system = filterAttrs (_: a: a.system      or false) all;
          interactive = filterAttrs (_: a: a.interactive or false) all;
          posix = filterAttrs (_: a: a.posix       or false) all;
          modern = filterAttrs (_: a: !(a.posix       or false)) all;
        };
      };

      interface = {
        all = byCategory.interface;
        grouped = {
          compositors = let
            all = byCategory.compositor;
            protocols = attrNames byCategory.protocol;
            roles = unique (map (a: a.role      or "unknown") (attrValues all));
            maturities = unique (map (a: a.maturity  or "unknown") (attrValues all));
          in {
            inherit all;
            grouped = {
              byProtocol =
                genAttrs protocols
                (p: filterAttrs (_: a: isIn p (a.protocol or [])) all);
              byRole =
                genAttrs roles
                (r: filterAttrs (_: a: (a.role     or "unknown") == r) all);
              byMaturity =
                genAttrs maturities
                (m: filterAttrs (_: a: (a.maturity or "unknown") == m) all);
            };
            queried = {
              integrated =
                filterAttrs
                (_: a: a.integrated or false)
                byCategory.interface;
              standalone =
                filterAttrs
                (_: a: !(a.integrated or false))
                byCategory.interface;
              wayland =
                filterAttrs
                (_: a: isIn "wayland" (a.protocol or []))
                byCategory.interface;
              xorg =
                filterAttrs
                (_: a: isIn "xorg" (a.protocol or []))
                byCategory.interface;
              stable =
                filterAttrs
                (_: a: (a.maturity or null) == "stable")
                byCategory.interface;
              legacy =
                filterAttrs
                (_: a: (a.maturity or null) == "legacy")
                byCategory.interface;
            };
          };

          environments = let
            all = byCategory.environment;
            kinds = unique (map (a: a.kind or "unknown") (attrValues all));
          in {
            inherit all;
            grouped = {
              byKind =
                genAttrs kinds
                (k: filterAttrs (_: a: (a.kind or "unknown") == k) all);
            };
            queried = {
              desktop = filterAttrs (_: a: (a.kind or null) == "desktop") all;
              window = filterAttrs (_: a: (a.kind or null) == "compositor") all;
            };
          };

          greeters = let
            all = byCategory.greeter;
            displays = unique (map (a: a.display or "unknown") (attrValues all));
          in {
            inherit all;
            grouped = {
              byDisplay =
                genAttrs displays
                (d: filterAttrs (_: a: (a.display or "unknown") == d) all);
            };
            queried = {
              graphical = filterAttrs (_: a: (a.display or null) == "graphical") all;
              terminal = filterAttrs (_: a: (a.display or null) == "terminal") all;
            };
          };

          notifiers = let
            all = byCategory.notifier;
            protocols = attrNames byCategory.protocol;
          in {
            inherit all;
            grouped = {
              byProtocol =
                genAttrs protocols
                (p: filterAttrs (_: a: isIn p (a.protocol or [])) all);
            };
            queried = {
              integrated = filterAttrs (_: a: a.integrated or false) all;
              standalone = filterAttrs (_: a: !(a.integrated or false)) all;
            };
          };

          panels = let
            all = byCategory.panel;
            protocols = attrNames byCategory.protocol;
          in {
            inherit all;
            grouped = {
              byProtocol =
                genAttrs protocols
                (p: filterAttrs (_: a: isIn p (a.protocol or [])) all);
            };
            queried = {
              integrated = filterAttrs (_: a: a.integrated or false) all;
              standalone = filterAttrs (_: a: !(a.integrated or false)) all;
            };
          };

          protocols = let
            all = byCategory.protocol;
            surfaces = unique (map (a: a.surface  or "unknown") (attrValues all));
            maturities = unique (map (a: a.maturity or "unknown") (attrValues all));
          in {
            inherit all;
            grouped = {
              bySurface =
                genAttrs surfaces
                (s: filterAttrs (_: a: (a.surface  or "unknown") == s) all);
              byMaturity =
                genAttrs maturities
                (m: filterAttrs (_: a: (a.maturity or "unknown") == m) all);
            };
            queried = {
              compositing = filterAttrs (_: a: a.compositing  or false) all;
              nonCompositing = filterAttrs (_: a: !(a.compositing  or false)) all;
              remote = filterAttrs (_: a: a.remote       or false) all;
              local = filterAttrs (_: a: !(a.remote       or false)) all;
              accelerated = filterAttrs (_: a: a.acceleration or false) all;
              software = filterAttrs (_: a: !(a.acceleration or false)) all;
              modern = filterAttrs (_: a: (a.maturity or null) != "legacy") all;
              legacy = filterAttrs (_: a: (a.maturity or null) == "legacy") all;
            };
          };
        };
        queried = {};
      };
    };
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
