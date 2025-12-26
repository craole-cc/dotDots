{
  host,
  lix,
  ...
}: let
  inherit (lix.configuration.core) mkSudoRules;
  admins = host.users.names.elevated or [];
in {
  security.sudo = {
    #> Restrict sudo to members of the wheel group (root is always allowed).
    execWheelOnly = true;

    #> For each admin user, grant passwordless sudo for all commands.
    extraRules = mkSudoRules admins;
  };
}
