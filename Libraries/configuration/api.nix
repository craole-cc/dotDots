{
  _,
  lib,
  ...
}: let
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
  inherit (_.filesystem.importors) importAttrs;
  inherit (lib.lists) head elem sort length;
  inherit (_.configuration.interface) updateInterface;
  apiPath = ../..API;

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
    hostsPath ? (apiPath + "/hosts"),
    usersPath ? (apiPath + "/users"),
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
    usersUpdated = updateUsers {inherit host users;};
    enrichment = {
      inherit name;
      inherit (host.paths) dots;
      users = usersUpdated;
      system = host.specs.platform or "x86_64-linux";
      interface = updateInterface {inherit (usersUpdated) primaryUser;};
    };
  in
    host // enrichment;

  updateUsers = {
    host,
    users,
  }: let
    rolePriority = {
      "administrator" = 1;
      "admin" = 2;
      "developer" = 3;
      "poweruser" = 4;
    };
    principals = listToAttrs (map (p: {
        name = p.name;
        value = p;
      })
      host.principals);

    #> Merge user configs but keep enable, autoLogin, and role from principals
    all =
      mapAttrs (
        name: hostUser: let
          userData = users.${name} or {};
          #> Remove enable, autoLogin, and role from user data
          userDataFiltered = removeAttrs userData ["enable" "autoLogin" "role"];
        in
          recursiveUpdate userDataFiltered hostUser
      )
      principals;

    #> Force-enable first principal if none enabled
    allWithDefault =
      if filterAttrs (_: u: u.enable == true) all == {}
      then let
        principal = head host.principals;
      in
        all
        // {
          ${principal.name} =
            all.${principal.name}
            // {
              enable = true;
              role = all.${principal.name}.role or "administrator";
            };
        }
      else all;

    enabled = filterAttrs (_: u: u.enable == true) allWithDefault;

    autoLogin = filterAttrs (_: u: u.autoLogin == true) enabled;

    elevated =
      mapAttrs
      (_: u: u // {_priority = rolePriority.${u.role or "guest"} or 999;})
      (
        filterAttrs
        (_: u: elem (u.role or "") (attrNames rolePriority))
        enabled
      );

    primary =
      if autoLogin != {}
      then autoLogin
      else if elevated != {}
      then let
        sorted = sort (a: b: a._priority < b._priority) (attrValues elevated);
      in {${(head sorted).name} = head sorted;}
      else if enabled != {}
      then enabled
      else {};

    names = {
      all = attrNames all;
      primary =
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
  in {inherit names count data;};
in {
  inherit all host hostOrDefault;
  _rootAliases = {
    getAttrs = all;
    getHost = host;
    getHostOrDefault = hostOrDefault;
  };
}
