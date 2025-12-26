{
  host,
  lib,
  lix,
  ...
}: let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lix.configuration.core) mkAdmin;
  admins = host.users.names.elevated or [];
in {
  security.sudo = {
    #> Restrict sudo to members of the wheel group (root is always allowed).
    execWheelOnly = true;

    #> For each admin user, grant passwordless sudo for all commands.
    extraRules = mapAttrsToList (name: _: mkAdmin name) admins;
  };
}
