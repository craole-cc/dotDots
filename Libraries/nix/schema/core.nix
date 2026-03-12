{
  _,
  lib,
  ...
}: let
  inherit (_.filesystem.importers) importAttrs;
  inherit (_.filesystem.tree) mkTree;
  inherit (_.schema) ui user;
  inherit (lib.attrsets) mapAttrs attrNames attrValues;
  inherit (lib.lists) head;

  exports = {
    internal = {
      inherit all enrichHost host hostOrDefault;
      mkSchema = all;
      mkHost = enrichHost;
    };
    external = {
      inherit
        (exports.internal)
        mkSchema
        mkHost
        ;
    };
  };

  paths = mkTree {};
  apiPath = paths.api.nix;

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
  all = {
    hostsPath ? apiPath.hosts,
    usersPath ? apiPath.users,
  }: let
    users = importAttrs usersPath;
    hosts = mapAttrs (name: host: enrichHost {inherit name host users;}) (importAttrs hostsPath);
  in {inherit users hosts;};

  host = {
    hosts,
    name ? null,
  }:
    if hosts ? ${name}
    then hosts.${name}
    else throw "Host '${name}' not found. Available hosts: ${toString (attrNames hosts)}";

  hostOrDefault = {
    hosts,
    name ? null,
  }:
    if name == null
    then host {inherit hosts name;}
    else if hosts != {}
    then head (attrValues hosts)
    else throw "No hosts available";

  /**
  Enrich a single host with user data, interface normalization, and metadata.
  */
  enrichHost = {
    name,
    host,
    users,
  }: let
    enrichedUser = user.enriched {inherit host users;};
    enrichedUI = ui.enriched {
      inherit host;
      user = enrichedUser.data.primary;
    };
    enrichment = {
      inherit name;
      inherit (host.paths) dots;
      system = host.specs.platform or "x86_64-linux";
      users = enrichedUser;
      interface = enrichedUI;
    };
  in
    host // enrichment;
in
  exports.internal // {_rootAliases = exports.external;}
# {
#   inherit all host hostOrDefault;
#   _rootAliases = {
#     getAttrs = all;
#     getHost = host;
#     getHostOrDefault = hostOrDefault;
#   };
# }
