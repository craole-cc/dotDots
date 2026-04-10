# filters/default.nix
# Thin composition root.  All machinery lives in helpers/; all section
# declarations live in sections/.  This file only wires them together.
{_, ...}: let
  exports = {
    internal = filters;
    external.applicationFilters = filters;
  };

  inherit (_.applications.construction) mkFilters;

  helpers = import ./helpers {inherit _;};
  inherit (helpers) withFlag;

  filters = mkFilters {
    all = _.applications.registry;
    queries = {byCategory, ...}: {
      needsTerminal = withFlag {
        field = "needsTerminal";
        set   = _.applications.registry;
      };
      shell     = import ./sections/shell.nix     {inherit helpers byCategory;};
      interface = import ./sections/interface.nix {inherit helpers byCategory;};
    };
  };
in
  exports.internal // {_rootAliases = exports.external;}
