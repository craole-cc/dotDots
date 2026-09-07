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

  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.filesystem.resolution) pathAttrs;
  inherit (_.schema.core) mkCore;
  inherit (_.schema.home) mkUsers;
  inherit (_.schema.settings) mkSettings;
  inherit (_.strings.access) getEnvOr;
  inherit (_.types.access) headOf;
  inherit (_.types.predicates) isString;

  /**
  Enrich each declared host against the hosts baseline, resolve global and host-level
  settings via `mkSettings`, and determine the active deployment target.
  */
  mkSchema = {
    api ? _defaults.paths.repo.api.default.store,
    host ? {},
    ...
  }: let
    api' = pathAttrs api;

    raw =
      api'
      // {
        global = api'.global or {};
        paths = api'.paths or (api'.global.paths or {});
        shells = api'.shells or {};
        users = api'.users or {};
        hosts = api'.hosts or {};
      };

    paths = raw.paths;
    users = mkUsers {inherit (raw) users;};

    base = {
      hosts =
        mapAttrs (
          name: hostAttr:
            mkCore (
              {
                settings = mkSettings {
                  inherit (raw) global;
                  host = hostAttr;
                };
                inherit users;
                inherit (raw) shells;
                host = recursiveUpdate (raw.hosts.default or {}) hostAttr;
                inherit name;
              }
              // paths
            )
        )
        raw.hosts
        // {
          default = mkCore (
            {
              name = "default";
              settings = mkSettings {
                inherit (raw) global;
                host = raw.hosts.default or {};
              };
              inherit users;
              inherit (raw) shells;
              host = raw.hosts.default or {};
            }
            // paths
          );
        };
      inherit users;
    };

    active = {
      host =
        if host ? paths.roots.repo.src && host ? stateVersion
        then host
        else let
          name =
            if isString host && host != "" && base.hosts ? ${host}
            then host
            else if host ? name && base.hosts ? ${host.name}
            then host.name
            else getEnvOr "HOSTNAME" (headOf raw.hosts);
        in
          base.hosts.${name};

      user = active.host.users.primary;
    };
  in
    raw
    // {
      hosts =
        base.hosts
        // {
          default = active.host;
          raw = raw.hosts;
        };
      users =
        base.users
        // {
          default = active.user;
          raw = raw.users;
        };
    };
in
  __exports.internal // {__rootAliases = __exports.external;}
