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
    api = tree.api or {};
    paths = {
      users = api.users.store or {};
      hosts = api.hosts.store or {};
    };
    users = importAttrs paths.users;
    hosts = mapAttrs (
      name: host: mkCore {inherit name host users;}
    ) (importAttrs paths.hosts);
  in {inherit users hosts;};
in
  exports.internal // {_rootAliases = exports.external;}
