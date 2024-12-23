{ specialArgs, lib, ... }:
let
  inherit (specialArgs) users;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists) any;
in
{
  # programs.hyprland.enable = lib.any (user: user.desktop.manager or null == "hyprland") (users);

  users.users = mapAttrs (
    _: user: with user; {
      inherit
        description
        isNormalUser
        hashedPassword
        ;
      uid = id;
    }
  ) specialArgs.users;
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
