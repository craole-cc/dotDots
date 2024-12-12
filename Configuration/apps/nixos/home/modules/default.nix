{ specialArgs, ... }:
{
  users = {
    users = mapAttrs (
      name: u: with u; {
        inherit
          description
          isNormalUser
          hashedPassword
          shell
          ;
        uid = id;
        extraGroups = groups ++ extraGroups;
        useDefaultShell = elem shell [
          null
          config.users.defaultUserShell
        ];
      }
    ) (filterAttrs (_: u: u.enable == true) users);
  };
}
