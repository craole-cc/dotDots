{_, ...}: let
  __exports = {
    internal = enums;
    external.shellEnums = enums;
  };

  inherit (_.applications.shell) filters;
  inherit (_.lists.construction) mkEnum;

  enums = {
    shells = {
      all = mkEnum {
        values = filters.shells.all;
        nullable = true;
      };
      interactive = mkEnum {
        values = filters.shells.where.interactive;
        nullable = true;
      };
      system = mkEnum {
        values = filters.shells.where.system;
        nullable = true;
      };
    };

    lineEditors = {
      all = mkEnum {
        values = filters.lineEditors.all;
        nullable = true;
      };
    };

    prompts = {
      all = mkEnum {
        values = filters.prompts.all;
        nullable = true;
      };
      multiShell = mkEnum {
        values = filters.prompts.where.multiShell;
        nullable = true;
      };
    };

    enhancements = {
      all = mkEnum {
        values = filters.enhancements.all;
        nullable = true;
      };
      byKind = kind:
        mkEnum {
          values = filters.enhancements.byShell.${kind} or {};
          nullable = true;
        };
    };
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
