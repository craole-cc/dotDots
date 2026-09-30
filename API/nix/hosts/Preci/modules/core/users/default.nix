{
  host,
  lix,
  ...
}: let
  principals = host.principals.all;
  users = lix.attrsets.listToAttrs (lix.lists.map (user: {
      inherit (user) name;
      value = {
        isNormalUser = true;
        inherit (user) description;
        inherit (user) hashedPassword;
        extraGroups =
          if user.role == "administrator"
          then ["wheel" "networkmanager"]
          else ["networkmanager"];
      };
    })
    principals);
in {
  users.users = users;
}
