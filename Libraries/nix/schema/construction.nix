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
      inherit (_.schema.ui) mkUI;
    };
    external = {inherit mkSchema;};
  };

  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.filesystem.resolution) pathAttrs;
  inherit (_.schema.core) mkCore;
  inherit (_.schema.home) mkUsers;
  inherit (_.strings.access) getEnvOr;
  inherit (_.types.access) headOf;
  inherit (_.types.predicates) isString;

  /**
  Enrich each declared host against the hosts baseline and determine the active
  deployment target.

  # Arguments
  - api: The API data - a path, `importAttrs`'s raw `{ value; stems; }`
    result, or an already-unwrapped value. Normalized via `pathAttrs`.
  - host: Caller-supplied host override. Trusted as-is only when it already
    carries both non-negotiable fields (`paths.src`, `stateVersion`) - i.e.
    it's already a fully resolved host, not just a name to look up. Otherwise
    falls back to `$HOSTNAME`/first-declared, resolved against `base.hosts`.

  # Returns
  A fully hydrated schema attrset with active `default` pointers and `raw` fallbacks.
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
        users = api'.users or {};
        hosts = api'.hosts or {};
      };

    paths = raw.global.paths or {};

    base = {
      hosts =
        mapAttrs (
          name: host:
            mkCore (
              {
                inherit name;
                inherit (base) users;
                host = recursiveUpdate (raw.hosts.default or {}) host;
              }
              // paths
            )
        )
        raw.hosts
        // {
          default = mkCore (
            {
              name = "default";
              inherit (base) users;
              host = raw.hosts.default or {};
            }
            // paths
          );
        };
      users = mkUsers {inherit (raw) users;};
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
