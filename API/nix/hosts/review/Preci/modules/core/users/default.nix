#? NixOS user accounts for this host's principals.
#?
#? One account per principal, carrying the identity the schema already
#? resolved: uid, home, description and password material. Nothing is
#? recomputed here -- a principal that resolves a uid in the schema gets that
#? uid on disk, so a change in the spec is the only way to change it.
{
  host,
  lix,
  ...
}: let
  inherit (lix.attrsets) listToAttrs;
  inherit (lix.lists) optional;
in {
  users.users = listToAttrs (
    map (user: {
      inherit (user) name;
      value = {
        inherit (user) description uid;
        inherit (user.paths.roots) home;
        isNormalUser = user.role != "service";
        extraGroups =
          ["networkmanager"]
          ++ (optional (user.role == "administrator") "wheel");
        initialHashedPassword = user.hashedPassword;
      };
    })
    host.principals.defined
  );
}
