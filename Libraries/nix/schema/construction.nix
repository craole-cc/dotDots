{
  _,
  _defaults,
  ...
}: let
  __exports = {
    internal = {
      inherit mkSchema;
      inherit (_.schema.applications) mkApplications;
      inherit (_.schema.hardware) mkHardware;
      inherit (_.schema.home) mkHome;
      inherit (_.schema.io) mkKeyboard mkHyprKeybinds;
      inherit (_.schema.locale) mkLocale;
      inherit (_.schema.settings) mkSettings;
      inherit (_.schema.ui) mkUI;
    };
    external = {inherit mkSchema;};
  };

  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.filesystem.importers) importAttrs;
  inherit (_.filesystem.predicates) isPathLike;
  inherit (_.filesystem.resolution) pathAttrs;
  inherit (_.schema.core) mkCore;
  inherit (_.schema.home) mkUsers;
  inherit (_.schema.settings) mkSettings;

  /**
  Enrich each declared host and user from the API.

  Host and user identity records are atomic at their named `default.nix`.
  Nested directories below a host/user belong to that identity but must not
  replace its profile data. Other API domains may remain recursively shaped.
  No active host is inferred here.
  */
  mkSchema = {
    api ? _defaults.paths.repo.api.default.store,
    ...
  }: let
    api' = pathAttrs api;

    identities = name: fallback:
      if isPathLike api
      then importAttrs (api + "/${name}")
      else fallback;

    raw =
      api'
      // {
        global = api'.global or {};
        paths = api'.paths or (api'.global.paths or {});
        shells = api'.shells or {};
        users = identities "users" (api'.users or {});
        hosts = identities "hosts" (api'.hosts or {});
      };

    paths = raw.paths;
    users = mkUsers {inherit (raw) users;};
    hosts =
      mapAttrs (
        name: host:
          mkCore (
            {
              settings = mkSettings {
                inherit (raw) global;
                inherit host;
              };
              inherit users host name;
              inherit (raw) shells;
            }
            // paths
          )
      )
      raw.hosts;
  in
    raw
    // {
      inherit hosts users;
    };
in
  __exports.internal // {__rootAliases = __exports.external;}
