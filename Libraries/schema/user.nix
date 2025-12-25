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

  rolePriority = {
    "administrator" = 1;
    "admin" = 2;
    "developer" = 3;
    "poweruser" = 4;
  };

  getPrincipals = host:
    listToAttrs (map (p: {
        name = p.name;
        value = p;
      })
      host.principals);

  #> Merge user configs but keep enable, autoLogin, and role from principals
  getAll = {
    users,
    host,
  }:
    mapAttrs (
      name: hostUser: let
        userData = users.${name} or {};
        #> Remove enable, autoLogin, and role from user data
        userDataFiltered = removeAttrs userData ["enable" "autoLogin" "role"];
      in
        recursiveUpdate userDataFiltered hostUser
    )
    (getPrincipals host);

  #> Force-enable first principal if none enabled
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

  getEnabled = users: filterAttrs (_: u: u.enable == true) users;

  getAutoLogin = enabledUsers: filterAttrs (_: u: u.autoLogin == true) enabledUsers;

  getElevated = enabledUsers:
    mapAttrs
    (_: u: u // {_priority = rolePriority.${u.role or "guest"} or 999;})
    (
      filterAttrs (_: u: elem (u.role or "") (attrNames rolePriority)) enabledUsers
    );

  getPrimary = {
    autoLogin ? {},
    elevated ? {},
    enabled ? {},
  }:
    if autoLogin != {}
    then head (attrValues autoLogin)
    else if elevated != {}
    then
      head (
        sort
        (a: b: a._priority < b._priority)
        (attrValues elevated)
      )
    else if enabled != {}
    then head (attrValues enabled)
    else {};

  enriched = {
    host,
    users,
  }: let
    all = getAll {inherit host users;};
    enabled = getEnabled (getAllWithDefault {inherit host users;});
    autoLogin = getAutoLogin enabled;
    elevated = getElevated enabled;
    primary = getPrimary {inherit autoLogin enabled elevated;};

    names = {
      all = attrNames all;
      primaryUser =
        if primary != {}
        then head (attrNames primary)
        else null;
      enabled = attrNames enabled;
      elevated = attrNames elevated;
      autoLogin = attrNames autoLogin;
    };
    count = {
      total = length names.all;
      enabled = length names.enabled;
      elevated = length names.elevated;
    };
    data = {inherit all enabled elevated autoLogin primary;};
  in {
    inherit
      names
      count
      data
      ;
  };
in {
  inherit enriched getPrincipals getAll;
}
