{
  _,
  lib,
  ...
}: let
  inherit (_.filesystem.importers) importAttrs;
  inherit (_.schema.core) mkCore;
  inherit (lib.attrsets) mapAttrs;

  exports = {
    internal = {inherit mkSchema;};
    external = exports.internal;
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
    paths = {
      users = tree.api.users.store;
      hosts = tree.api.hosts.store;
    };
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
  exports.internal // {_rootAliases = exports.external;}
