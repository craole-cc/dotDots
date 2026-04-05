{_, ...}: let
  __exports = {
    internal = enums;
    external.shellEnums = enums;
  };

  inherit (_.applications.shell) filters;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.construction) mkEnum;

  enums = {
    shells = {
      all = mkEnum filters.shells.all;
      interactive = mkEnum filters.shells.where.interactive;
      system = mkEnum filters.shells.where.system;
    };

    lineEditors = {
      all = mkEnum filters.lineEditors.all;
      stable = mkEnum filters.lineEditors.where.stable;
      byShell = mapAttrs (_: v: mkEnum v) filters.lineEditors.byShell;
    };

    prompts = {
      all = mkEnum filters.prompts.all;
      multiShell = mkEnum filters.prompts.where.multiShell;
    };

    enhancements = {
      all = mkEnum filters.enhancements.all;
      byShell = shell: mkEnum (filters.enhancements.byShell.${shell} or {});
      byKind = kind: mkEnum (filters.enhancements.where.${kind} or {});
    };
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
