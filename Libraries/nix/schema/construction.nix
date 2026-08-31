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
  inherit (_.filesystem.traversal) importAttrs;
  inherit (_.schema.core) mkCore;
  inherit (_.schema.home) mkUsers;
  inherit (_.strings.access) getEnvOr;
  inherit (_.types.access) headOf;

  /**
  Enrich each declared host against the hosts baseline and determine the active
  deployment target.

  # Arguments
  - api: The imported API module (.global, .hosts, .users)
  - args: The flake/system arguments to extract host name overrides

  # Returns
  A fully hydrated schema attrset with active `default` pointers and `raw` fallbacks.
  */
  mkSchema = {
    api ? (importAttrs paths.core.api.default.store).value,
    paths ? _defaults.paths,
    args ? {},
  }: let
    raw = {
      global = api.global or {};
      users = api.users or {};
      hosts = api.hosts or {};
    };

    base = {
      hosts =
        mapAttrs (name: host:
          mkCore {
            inherit name;
            users = base.users;
            host = recursiveUpdate (raw.hosts.default or {}) host;
          })
        (removeAttrs raw.hosts ["default"])
        // {
          default = mkCore {
            name = "default";
            users = base.users;
            host = raw.hosts.default or {};
          };
        };
      users = mkUsers raw.users;
    };

    active = let
      host = let
        name =
          args.host.name or (
            getEnvOr "HOSTNAME" (
              headOf (removeAttrs base.hosts ["default"])
            )
          );
      in
        base.hosts.${name} or base.hosts.default;
      user = host.users.primary;
    in {inherit host user;};
  in {
    inherit (raw) global;
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
