{
  lib,
  host,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists) concatLists;
  inherit (lib.strings) toUpper stringLength substring;
  inherit (host) users;

  # Capitalize the first letter of a string (for nicer default descriptions).
  # TODO: Move to lix.strings
  capitalizeFirst = str: "${toUpper (substring 0 1 str)}${substring 1 (stringLength str - 1) str}";

  # Turn a high-level user definition from `host.users` into a NixOS users.users entry.
  mkUser = name: user: let
    inherit (user) role description;

    # "service" accounts are treated as system users; everything else is a normal user.
    isNormalUser = role != "service";

    # Administrators have elevated privileges via the wheel group.
    isAdmin = role == "administrator";

    base = {
      inherit name isNormalUser;

      # Mirror the isNormalUser bit into the standard isSystemUser flag.
      isSystemUser = !isNormalUser;

      # Base extraGroups are derived from role and then extended by user.groups:
      # - Normal users: networkmanager + their own private group name.
      # - Admins: additionally added to wheel.
      extraGroups = concatLists [
        (
          if isNormalUser
          then [
            "networkmanager"
            name
          ]
          else []
        )
        (
          if isAdmin
          then ["wheel"]
          else []
        )
        (user.groups or [])
      ];

      # Default description if none is provided.
      description =
        if description != null
        then description
        else if isNormalUser
        then "A ${role} by the name of '${capitalizeFirst name}'"
        else "A ${role} dubbed '${name}'";
    };

    # Attach password hash if provided.
    withHash =
      if user.password != null
      then base // {hashedPassword = user.password;}
      else base;

    # Attach password file if provided (takes precedence at login time).
    withFile =
      if user.passwordFile != null
      then withHash // {hashedPasswordFile = user.passwordFile;}
      else withHash;
  in
    withFile;
in {
  # Convert host-level user definitions into NixOS users.users entries.
  # This is the single point where roles are interpreted into NixOS flags/groups.
  users.users = mapAttrs mkUser users;
}
