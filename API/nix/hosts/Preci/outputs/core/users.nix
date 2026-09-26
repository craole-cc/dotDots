{host, lix, ...}: let
  principals = host.principals.all;
  users = lix.attrsets.listToAttrs (lix.lists.map (user: {
    name = user.name;
    value = {
      isNormalUser = true;
      description = user.description;
      hashedPassword = user.hashedPassword;
      extraGroups =
        if user.role == "administrator"
        then ["wheel" "networkmanager"]
        else ["networkmanager"];
    };
  }) principals);
in {
  users.users = users;
}
