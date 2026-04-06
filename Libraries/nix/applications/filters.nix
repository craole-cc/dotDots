{_, ...}: let
  __exports = {
    internal = filters;
    external.applicationFilters = filters;
  };

  inherit (_.applications.registry) common interface shell;

  filters = {
    inherit (common.filters) all byCategory byChannel byFamily needsTerminal ofCategory;
    interface = interface.filters;
    shell = shell.filters;
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
