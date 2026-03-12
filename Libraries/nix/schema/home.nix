{lib, ...}: let
  inherit
    (lib.attrsets)
    mapAttrs
    listToAttrs
    attrNames
    attrValues
    recursiveUpdate
    filterAttrs
    removeAttrs
    ;

  inherit (lib.lists) head elem sort length;

  /**
  Role priority rankings used for primary user selection.
  Lower value = higher priority. Roles not listed default to 999.
  */
  rolePriority = {
    "administrator" = 1;
    "admin" = 2;
    "developer" = 3;
    "poweruser" = 4;
    "service" = 5;
    "guest" = 6;
  };

  /**
  Convert a host's principals list into an attrset keyed by principal name.

  Type: getPrincipals :: Host -> AttrSet

  Arguments:
    host: A host config containing a `principals` list, each with at least a `name` field.

  Returns an attrset of `{ name = principal; }` pairs.
  */
  getPrincipals = host:
    listToAttrs (map (p: {
        name = p.name;
        value = p;
      })
      host.principals);

  /**
  Merge global user config with host principal config for all principals.
  `enable`, `autoLogin`, and `role` are always sourced from the principal —
  never from global user data — so host intent cannot be overridden.

  Type: getAll :: { users :: AttrSet, host :: Host } -> AttrSet

  Arguments:
    users: Global user definitions (e.g. from a users module).
    host:  Host config containing a `principals` list.

  Returns an attrset of merged user configs keyed by username.
  */
  getAll = {
    users,
    host,
  }:
    mapAttrs (
      name: hostUser: let
        userData = users.${name} or {};
        userDataFiltered = removeAttrs userData ["enable" "autoLogin" "role"];
      in
        recursiveUpdate userDataFiltered hostUser
    )
    (getPrincipals host);

  /**
  Like `getAll`, but guarantees at least one user has `enable = true`.
  If no principal is enabled, the first principal is force-enabled and
  assigned the `administrator` role if it has none.

  Type: getAllWithDefault :: { users :: AttrSet, host :: Host } -> AttrSet

  Arguments:
    users: Global user definitions.
    host:  Host config containing a `principals` list.

  Throws if no principals are defined at all.
  */
  getAllWithDefault = {
    users,
    host,
  }: let
    all = getAll {inherit users host;};
    principal =
      if all == {}
      then throw "No users defined"
      else head (attrNames all);
  in
    if filterAttrs (_: u: u.enable == true) all == {}
    then
      all
      // {
        ${principal} =
          all.${principal}
          // {
            enable = true;
            role = all.${principal}.role or "administrator";
          };
      }
    else all;

  /**
  Filter a user attrset to only users with `enable = true`.

  Type: getEnabled :: AttrSet -> AttrSet

  Arguments:
    users: Any attrset of user configs.
  */
  getEnabled = users: filterAttrs (_: u: u.enable == true) users;

  /**
  Filter a user attrset to enabled, interactive (human) users only.
  Excludes `service` and `guest` roles, who must never own a login
  session or be selected as the primary user.

  Type: getInteractive :: AttrSet -> AttrSet

  Arguments:
    users: Any attrset of user configs.
  */
  getInteractive = users: filterAttrs (_: u: (u.role or "") != "service" && (u.role or "") != "guest") (getEnabled users);

  /**
  Filter a user attrset to only users with `autoLogin = true`.

  Type: getAutoLogin :: AttrSet -> AttrSet

  Arguments:
    enabledUsers: An attrset of already-enabled user configs.
  */
  getAutoLogin = enabledUsers: filterAttrs (_: u: u.autoLogin == true) enabledUsers;

  /**
  Filter a user attrset to users with a known role, and annotate each
  with `_rank` (from `rolePriority`) for use in primary user selection.
  Lower rank = higher privilege. Only enabled users are considered.
  Users with unknown roles are excluded.

  Type: getElevated :: AttrSet -> AttrSet

  Arguments:
    users: Any attrset of user configs.
  */
  getElevated = users:
    mapAttrs
    (_: u: u // {_rank = rolePriority.${u.role or "guest"} or 999;})
    (
      filterAttrs (_: u: elem (u.role or "") (attrNames rolePriority)) (getEnabled users)
    );

  /**
  Select the primary user by the following precedence:
    1. First auto-login user.
    2. Highest-privilege elevated user (lowest `_rank` value).
    3. First interactive user.
    4. `{}` if no users are available.

  Type: getPrimary :: { autoLogin :: AttrSet, elevated :: AttrSet, interactive :: AttrSet } -> AttrSet

  Arguments:
    autoLogin:   Users with `autoLogin = true`.
    elevated:    Users with a known role, annotated with `_rank`.
    interactive: All enabled, non-service, non-guest users.
  */
  getPrimary = {
    autoLogin ? {},
    elevated ? {},
    interactive ? {},
  }:
    if autoLogin != {}
    then head (attrValues autoLogin)
    else if elevated != {}
    then
      head (
        sort
        (a: b: a._rank < b._rank)
        (attrValues elevated)
      )
    else if interactive != {}
    then head (attrValues interactive)
    else {};

  /**
  Produce a fully enriched user summary for a host.

  Type: enriched :: { host :: Host, users :: AttrSet } -> { names :: AttrSet, count :: AttrSet, data :: AttrSet }

  Arguments:
    host:  Host config containing a `principals` list.
    users: Global user definitions.

  Returns:
    names: Attrset of username lists — `all`, `enabled`, `interactive`, `elevated`, `autoLogin`, `primaryUser`.
    count: Attrset of counts   — `total`, `enabled`, `interactive`, `elevated`.
    data:  Attrset of full user configs — `all`, `enabled`, `interactive`, `elevated`, `autoLogin`, `primary`.
  */
  mkHome = {
    host,
    users,
  }: let
    all = getAll {inherit host users;};
    enabled = getEnabled (getAllWithDefault {inherit host users;});
    interactive = getInteractive enabled;
    autoLogin = getAutoLogin interactive;
    elevated = getElevated interactive;
    primary = getPrimary {inherit autoLogin elevated interactive;};

    names = {
      all = attrNames all;
      primaryUser =
        if primary != {}
        then head (attrNames primary)
        else null;
      enabled = attrNames enabled;
      interactive = attrNames interactive;
      elevated = attrNames elevated;
      autoLogin = attrNames autoLogin;
    };
    count = {
      total = length names.all;
      enabled = length names.enabled;
      interactive = length names.interactive;
      elevated = length names.elevated;
    };
    data = {inherit all enabled interactive elevated autoLogin primary;};
  in {
    inherit
      names
      count
      data
      ;
  };
in {
  inherit mkHome getPrincipals getAll;
}
