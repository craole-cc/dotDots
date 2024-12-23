{ specialArgs, lib, ... }:
let
  inherit (specialArgs) users;
  inherit (lib.attrsets) mapAttrs;
in
{
  users.users = mapAttrs (name: user: {
    uid = user.id;
    description = user.description or name;
    isNormalUser = user.isNormalUser or true;
    hashedPassword = user.hashedPassword or null;
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
