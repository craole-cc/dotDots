{_, ...}: let
  __exports = {
    internal = enums;
    external.interfaceEnums = enums;
  };

  inherit (_.applications.interface) filters;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.construction) mkEnum;

  enums = {
    compositors = {
      all = mkEnum filters.compositors.all;
      standalone = mkEnum filters.compositors.where.standalone;
      embedded = mkEnum filters.compositors.where.embedded;
      shell = mkEnum filters.compositors.where.shell;
      byProtocol = mapAttrs (_: v: mkEnum v) filters.compositors.byProtocol;
    };

    environments = {
      all = mkEnum filters.environments.all;
      desktop = mkEnum filters.environments.where.desktop;
      standalone = mkEnum filters.environments.where.standalone;
      byProtocol = mapAttrs (_: v: mkEnum v) filters.environments.byProtocol;
    };

    greeters = {
      all = mkEnum filters.greeters.all;
      graphical = mkEnum filters.greeters.where.graphical;
      terminal = mkEnum filters.greeters.where.terminal;
      byProtocol = mapAttrs (_: v: mkEnum v) filters.greeters.byProtocol;
    };

    protocols = {
      all = mkEnum filters.protocols.all;
      compositing = mkEnum filters.protocols.where.compositing;
      accelerated = mkEnum filters.protocols.where.accelerated;
      remote = mkEnum filters.protocols.where.remote;
    };

    panels = {
      all = mkEnum filters.panels.all;
      integrated = mkEnum filters.panels.where.integrated;
      standalone = mkEnum filters.panels.where.standalone;
      byProtocol = mapAttrs (_: v: mkEnum v) filters.panels.byProtocol;
    };

    notifiers = {
      all = mkEnum filters.notifiers.all;
      integrated = mkEnum filters.notifiers.where.integrated;
      standalone = mkEnum filters.notifiers.where.standalone;
      byProtocol = mapAttrs (_: v: mkEnum v) filters.notifiers.byProtocol;
    };
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
