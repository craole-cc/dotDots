{
  _,
  lib,
  ...
}: let
  inherit (_.filesystem.importers) importAttrs;
  inherit (_.schema.core) mkCore;
  inherit (lib.attrsets) mapAttrs;

  __exports = {
    internal = {
      inherit mkSchema;
      inherit (_.schema.ui) mkUI;
      inherit (_.schema.home) mkHome;
      inherit (_.schema.locale) mkLocale;
      inherit (_.schema.hardware) mkHardware;
    };
    external = {inherit mkSchema;};
  };

  /**
  Get host and user attributes from specified directories.

  # Arguments
  - hostsPath (path): Directory containing host configurations
  - usersPath (path): Directory containing user configurations

  # Returns
  An attribute set with:
  - hosts: Enriched host configurations
  - users: Raw user configurations
  */
  mkSchema = {tree}: let
    paths = {inherit (tree.store.api) users hosts;};
    users =
      if paths.users != null
      then importAttrs paths.users
      else {};
    hosts =
      if paths.hosts != null
      then
        mapAttrs (name: host:
          mkCore {
            inherit name host users;
          }) (importAttrs paths.hosts)
      else {};
  in {inherit users hosts;};
in
  __exports.internal // {_rootAliases = __exports.external;}
