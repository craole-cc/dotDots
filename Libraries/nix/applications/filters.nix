{_, ...}: let
  __exports = {
    internal = filters;
    external.applicationFilters = filters;
  };

  inherit (_.applications.enums) constants;
  categories = constants.categories.allValues;
  channels = constants.channels.allValues;
  families = constants.families.allValues;
  inherit (_.applications.registry) all byCategory ofCategory;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs;

  filters = {
    inherit all byCategory ofCategory;

    byFamily = mapAttrs (name: _: filterAttrs (_: a: a.family or null == name) all) families;
    byChannel = mapAttrs (name: _: filterAttrs (_: a: a.channel == name) all) channels;
    needsTerminal = filterAttrs (_: a: a.needsTerminal or false) all;
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
