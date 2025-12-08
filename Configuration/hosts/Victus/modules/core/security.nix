{
  users,
  lib,
  ...
}:
let
  inherit (lib.attrsets) filterAttrs mapAttrsToList attrNames;
  inherit (lib.lists) length head;

  # List of all user names for this host (attrset keys of `users`).
  userNames = attrNames users;

  # Predicate: user is an administrator if their role is exactly "administrator".
  isAdmin = u: (u.role or null) == "administrator";

  # All users explicitly configured as administrators.
  adminsUsersRaw = filterAttrs (_: isAdmin) users;

  # Final set of admin users:
  # - If at least one admin is explicitly defined, use that set.
  # - If no admins and there is exactly one user, auto-promote that user to admin.
  # - If no admins and more than one user, leave empty and let the assertion fail.
  adminsUsers =
    if adminsUsersRaw != { } then
      adminsUsersRaw
    else if length userNames == 1 then
      let
        onlyName = head userNames;
      in
      {
        ${onlyName} = users.${onlyName};
      }
    else
      adminsUsersRaw;

  # Build a single sudo.extraRules entry granting passwordless root access
  # for a specific username.
  mkAdmin = name: {
    # Apply this rule only to the named user.
    users = [ name ];

    # Allow that user to run any command as any user/group, without password.
    # Equivalent to:  name ALL=(ALL:ALL) NOPASSWD: ALL
    commands = [
      {
        command = "ALL";
        options = [
          "SETENV"
          "NOPASSWD"
        ];
      }
    ];
  };
in
{
  # Policy check:
  # - If multiple users exist, at least one must be an administrator.
  # - A single-user host may omit role and will be auto-promoted to admin.
  assertions = [
    {
      assertion = (adminsUsers != { }) || (length userNames <= 1);
      message = ''
        When multiple users are defined for a host, at least one must have role = "administrator".
      '';
    }
  ];

  security.sudo = {
    # Restrict sudo to members of the wheel group (root is always allowed).
    execWheelOnly = true;

    # For each admin user, grant passwordless sudo for all commands.
    # This is in addition to the default root and wheel rules from the NixOS sudo module. [web:20][web:22]
    extraRules = mapAttrsToList (name: _: mkAdmin name) adminsUsers;
  };
}
