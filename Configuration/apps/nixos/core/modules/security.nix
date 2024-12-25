{ specialArgs, lib, ... }:
let
  inherit (specialArgs) users host;
  inherit (lib.attrsets) attrNames filterAttrs;
  inherit (lib.lists) unique filter elem;

  enabledUsers = filter (user: user.enable or true) host.people;
  regularUsersPerHost = map (user: user.name) (
    filter (user: user.admin or false == false) enabledUsers
  );
  elevatedUsersPerHostConf = map (user: user.name) (
    filter (user: user.admin or false == true) enabledUsers
  );
  elevatedUsersPerUserConf = attrNames (filterAttrs (_: user: user.isAdminUser or false) users);
  elevatedUsers = unique (
    filter (user: !elem user regularUsersPerHost) (elevatedUsersPerHostConf ++ elevatedUsersPerUserConf)
  );
in
{
  security = {
    sudo = {
      execWheelOnly = true;
      extraRules = [
        {
          users = elevatedUsers;
          commands = [
            {
              command = "ALL";
              options = [
                "SETENV"
                "NOPASSWD"
              ];
            }
          ];
        }
      ];
    };
  };
}
