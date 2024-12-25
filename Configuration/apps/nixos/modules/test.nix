{
  specialArgs,
  lib,
  config,
  ...
}:
let

  inherit (specialArgs) host modules;
  inherit (host) userConfigs people;
  inherit (lib.attrsets)
    mapAttrs
    attrValues
    attrNames
    filterAttrs
    ;
  inherit (lib.lists)
    any
    filter
    unique
    elem
    ;
  inherit (config.networking) networkmanager;

  enabledUsers = filter (user: user.enable or true) people;
  regularUsersPerHost = map (user: user.name) (
    filter (user: user.admin or false == false) enabledUsers
  );
  elevatedUsersPerHostConf = map (user: user.name) (
    filter (user: user.admin or false == true) enabledUsers
  );
  elevatedUsersPerUserConf = attrNames (filterAttrs (_: user: user.isAdminUser or false) userConfigs);
  elevatedUsers = unique (
    filter (user: !elem user regularUsersPerHost) (elevatedUsersPerHostConf ++ elevatedUsersPerUserConf)
  );
  users = lib.attrNames specialArgs.host.userConfigs;

in
{
  _module.args = {
    users =
      {
        all = users;
        elevated = elevatedUsers;
      }
      // mapAttrs (name: user: {
        uid = user.id or null;
        description = user.description or name;
        isNormalUser = user.isNormalUser or true;
        hashedPassword = user.hashedPassword or null;
        extraGroups =
          if user.isNormalUser or true then
            [ "users" ]
            ++ (if elem name elevatedUsers then [ "wheel" ] else [ ])
            ++ (if networkmanager.enable or false then [ "networkmanager" ] else [ ])
          else
            [ ];
      }) userConfigs;
  };
}
