{
  _,
  lib,
  ...
}: let
  inherit (_.filesystem.importers) importAttrs;
  inherit (_.filesystem.tree) mkTree;
  inherit (_.schema.core) mkCore;
  inherit (lib.attrsets) mapAttrs;

  exports = {
    internal = {inherit mkSchema;};
    external = exports.internal;
  };
  inherit (mkTree {}) api;

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
  mkSchema = {
    hostsPath ? api.hosts.store,
    usersPath ? api.hosts.store,
  }: let
    users = importAttrs usersPath;
    hosts =
      mapAttrs (name: host:
        mkCore {inherit name host users;}) (importAttrs hostsPath);
  in {inherit users hosts;};
in
  exports.internal // {_rootAliases = exports.external;}
