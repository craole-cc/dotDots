{
  specialArgs,
  lib,
  config,
  ...
}:
let
  inherit (specialArgs) users;
  inherit (lib.attrsets) mapAttrs;
  inherit (config.networking) networkmanager;
in
{
  users.users = mapAttrs (name: user: {
    uid = user.id;
    description = user.description or name;
    isNormalUser = user.isNormalUser or true;
    hashedPassword = user.hashedPassword or null;
    extraGroups = (
      if user.isNormalUser then
        [ "users" ]
        ++ (if networkmanager.enable then [ "networkmanager" ] else [ ])
        ++ (if user.isAdminUser then [ "wheel" ] else [ ])
      else
        [ ]
    );
  }) specialArgs.users;
  # users = {
  #   users = mapAttrs (
  #     name: u: with u; {
  #       inherit
  #         description
  #         isNormalUser
  #         hashedPassword
  #         shell
  #         ;
  #       uid = id;
  #       extraGroups = groups ++ extraGroups;
  #       useDefaultShell = elem shell [
  #         null
  #         config.users.defaultUserShell
  #       ];
  #     }
  #   ) (filterAttrs (_: u: u.enable == true) users);
  # };
}
