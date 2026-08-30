{_, ...}: let
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
  Enrich each declared host against the hosts baseline, using already-
  imported api data (no filesystem access - api.hosts/api.users are
  resolved attrsets, not directories).

  # Arguments
  - api (attrset): The imported API module, with .global, .hosts, .users

  # Returns
  An attribute set with:
  - global: api.global, passed through unchanged
  - users: api.users, passed through unchanged (raw)
  - hosts: each host enriched via mkCore against the hosts baseline
  */
  mkSchema = api: let
    global = api.global or {};
    users = api.users or {};
    hosts = let
      defaults = api.hosts.default or {};
      specs = removeAttrs (api.hosts or {}) ["default"];
      enriched = mapAttrs (name: host:
        mkCore {
          inherit name users;
          host = recursiveUpdate defaults host;
        })
      specs;
    in
      enriched
      // {
        default = mkCore {
          name = "default";
          inherit users;
          host = defaults;
        };
      };
  in {inherit global users hosts;};
in
  __exports.internal // {__rootAliases = __exports.external;}
