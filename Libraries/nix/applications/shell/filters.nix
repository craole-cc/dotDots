{_, ...}: let
  __exports = {
    internal = filters;
    external.shellFilters = filters;
  };

  inherit (_.attrsets.transformation) filterAttrs mapAttrs;
  inherit (_.lists.access) length;
  inherit (_.lists.predicates) elem;
  inherit (_.applications.registry) shells lineEditors prompts enhancements;

  filters = {
    shells = let
      all = shells;
    in
      all
      // {
        inherit all;
        where = {
          interactive = filterAttrs (_: s: s.interactive) all;
          system = filterAttrs (_: s: s.system) all;
          posix = filterAttrs (_: s: s.posix) all;
          modern = filterAttrs (_: s: !s.posix) all;
        };
      };

    lineEditors = let
      all = lineEditors;
      stable = filterAttrs (_: e: e.maturity == "stable") all;
      byShell =
        mapAttrs
        (name: _: filterAttrs (_: e: elem name e.shells) all)
        shells;
    in
      all
      // {
        inherit all byShell;
        where = {inherit stable;};
      };

    prompts = let
      all = prompts;
      multiShell = filterAttrs (_: p: length p.shells > 1) all;
      byShell =
        mapAttrs
        (name: _: filterAttrs (_: p: elem name p.shells) all)
        shells;
    in
      all
      // {
        inherit all byShell;
        where = {inherit multiShell;};
      };

    enhancements = let
      all = enhancements;
      fuzzy = filterAttrs (_: e: e.kind == "fuzzy") all;
      history = filterAttrs (_: e: e.kind == "history") all;
      navigation = filterAttrs (_: e: e.kind == "navigation") all;
      byShell =
        mapAttrs
        (name: _: filterAttrs (_: e: elem name e.shells) all)
        shells;
    in
      all
      // {
        inherit all byShell;
        where = {inherit fuzzy history navigation;};
      };
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
