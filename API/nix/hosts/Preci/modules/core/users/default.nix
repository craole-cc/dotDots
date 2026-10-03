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
  inherit (lix.lists) map;

  #? Administrators get `wheel`; everyone gets network management. `optionals`
  #? already yields `[]` when the role does not match, so the administrator
  #? case must not also append the base list.
  extraGroups =
    user:
    if user.role == "administrator"
    then [
      "wheel"
      "networkmanager"
    ]
    else ["networkmanager"];

  #? Bound as `accounts` because `users` at this level is already the NixOS
  #? `users` option set, and shadowing it makes `inherit (users) users` resolve
  #? against the option rather than the local.
  accounts = listToAttrs (map (user: {
      inherit (user) name;
      value = {
        inherit (user) description uid;
        #? Derived from the role rather than read off the principal: the
        #? schema has no `isNormalUser` field, and `service` is the only role
        #? that maps to a system account.
        isNormalUser = user.role != "service";
        home = user.paths.roots.home;
        extraGroups = extraGroups user;
        #? Only the hashed form. The spec carries a yescrypt hash, never a
        #? plaintext password: `initialPassword` is stored unhashed in the Nix
        #? store and in /etc/shadow, so setting both would be a leak waiting to
        #? happen and means nothing useful while the value is already a hash.
        initialHashedPassword = user.hashedPassword;
      };
    })
    host.principals.all);
in {
  #? This module contributes to `users.users`, not `users`: `accounts` is keyed
  #? by principal name and each entry is one account definition.
  users.users = accounts;
}