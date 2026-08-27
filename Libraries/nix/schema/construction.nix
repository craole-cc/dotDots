{_, ...}: let
  inherit (_.filesystem.importers) importAttrs;
  inherit (_.schema.core) mkCore;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.attrsets.aggregation) recursiveUpdate;

  __exports = {
    internal = {
      inherit mkSchema;
      inherit (_.schema.applications) mkApplications;
      inherit (_.schema.hardware) mkHardware;
      inherit (_.schema.home) mkHome;
      inherit (_.schema.io) mkKeyboard mkHyprKeybinds;
      inherit (_.schema.locale) mkLocale;
      inherit (_.schema.ui) mkUI;
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
  # Host API records are intentionally flat declarations. `default.nix` is
  # the complete host baseline; each named host supplies sparse updates.
  mkSchema = paths: let
    paths' = with paths; {
      global = api.global.store;
      users = api.users.store;
      hosts = api.hosts.store;
    };
    # paths = {inherit (tree.store.api) global users hosts;};

    global =
      if paths'.global != null
      then import paths'.global
      else {};
    users =
      if paths'.users != null
      then importAttrs paths'.users
      else {};
    defaultHost =
      if paths'.hosts != null
      then import (paths'.hosts + "/default.nix")
      else {};
    rawHosts =
      if paths'.hosts != null
      then removeAttrs (importAttrs paths'.hosts) ["default"]
      else {};
    hosts =
      mapAttrs (
        name: host:
          mkCore {
            inherit name users;
            host = recursiveUpdate defaultHost host;
          }
      )
      rawHosts;
  in {
    inherit global users hosts;
  };
in
  __exports.internal // {__rootAliases = __exports.external;}
