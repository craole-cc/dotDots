{_, ...}: let
  __exports = {
    internal = filters;
    external.interfaceFilters = filters;
  };

  inherit (_.attrsets.transformation) filterAttrs mapAttrs;
  inherit (_.lists.predicates) elem;
  inherit (_.applications.interface) registry;

  mkByProtocol = all:
    mapAttrs
    (name: _: filterAttrs (_: e: elem name e.protocol) all)
    registry.protocols;

  filters = {
    compositors = let
      all = registry.compositors;
    in {
      inherit all;
      byProtocol = mkByProtocol all;
      where = {
        standalone = filterAttrs (_: c: c.role == "standalone") all;
        embedded = filterAttrs (_: c: c.role == "embedded") all;
        shell = filterAttrs (_: c: c.role == "shell") all;
      };
    };

    environments = let
      all = registry.environments;
    in {
      inherit all;
      byProtocol = mkByProtocol all;
      where = {
        desktop = filterAttrs (_: e: e.kind == "desktop") all;
        standalone = filterAttrs (_: e: e.kind == "standalone") all;
        wayland = filterAttrs (_: e: elem "wayland" e.protocol) all;
        xorg = filterAttrs (_: e: elem "xorg" e.protocol) all;
      };
    };

    greeters = let
      all = registry.greeters;
    in {
      inherit all;
      byProtocol = mkByProtocol all;
      where = {
        graphical = filterAttrs (_: g: g.display == "graphical") all;
        terminal = filterAttrs (_: g: g.display == "terminal") all;
      };
    };

    notifiers = let
      all = registry.notifiers;
    in {
      inherit all;
      byProtocol = mkByProtocol all;
      where = {
        integrated = filterAttrs (_: n: n.integrated) all;
        standalone = filterAttrs (_: n: !n.integrated) all;
      };
    };

    panels = let
      all = registry.panels;
    in {
      inherit all;
      byProtocol = mkByProtocol all;
      where = {
        integrated = filterAttrs (_: p: p.integrated) all;
        standalone = filterAttrs (_: p: !p.integrated) all;
      };
    };

    protocols = let
      all = registry.protocols;
    in {
      inherit all;
      where = {
        compositing = filterAttrs (_: p: p.compositing) all;
        accelerated = filterAttrs (_: p: p.acceleration) all;
        remote = filterAttrs (_: p: p.remote) all;
      };
    };
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
