{_, ...}: let
  __exports = {
    internal = filters;
    external.applicationFilters = filters;
  };

  inherit (_.applications.enums) common;
  inherit (_.applications.construction) mkFilters;
  all = _.applications.registry;

  base = mkFilters {
    inherit all;
    inherit (common) categories channels families;
  };

  filters =
    base
    // {
      shell = {
        all = base.byCategory.shell;
        prompts = base.byCategory.prompt;
        enhancements = base.byCategory.enhancement;
        lineEditors = base.byCategory."line-editor";
      };
      interface = {
        all = base.byCategory.interface;
        compositors = base.byCategory.compositor;
        environments = base.byCategory.environment;
        greeters = base.byCategory.greeter;
        notifiers = base.byCategory.notifier;
        panels = base.byCategory.panel;
        protocols = base.byCategory.protocol;
      };
    };
in
  __exports.internal // {_rootAliases = __exports.external;}
