{ specialArgs, lib, ... }:
let
  inherit (specialArgs) users;
  inherit (lib.attrsets) attrNames filterAttrs;
  adminList = attrNames (filterAttrs (_: user: user.isAdminUser or false) users);
in
{
  security = {
    sudo = {
      execWheelOnly = true;
      extraRules = [
        {
          users = adminList;
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
