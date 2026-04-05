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
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.attrsets.construction) genAttrs;

  filters = {
    inherit all byCategory ofCategory;

    byFamily = genAttrs families (name: filterAttrs (_: a: (a.family   or null) == name) all);
    byChannel = genAttrs channels (name: filterAttrs (_: a: (a.channel  or null) == name) all);
    needsTerminal = filterAttrs (_: a: a.needsTerminal or false) all;
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
