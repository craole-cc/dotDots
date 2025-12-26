{
  host,
  lib,
  ...
}: let
  inherit (lib.attrsets) filterAttrs mapAttrs;
  inherit (lib.lists) elem;
  users = host.users.data.enabled or {};
  names = host.users.names.enabled or [];
  admins = host.users.names.elevated or [];

  #> Collect all enabled regular users (non-service, non-guest)
  normalUsers = filterAttrs (_: u: !(elem u.role ["service" "guest"])) users;
  # perUserConfigs =
in {
  # users.users = mapAttrs (_name: cfg: cfg.nixosUser) perUserConfigs;
  security.sudo = {
    #> Restrict sudo to members of the wheel group (root is always allowed).
    execWheelOnly = true;

    #> For each admin user, grant passwordless sudo for all commands.
    # extraRules = mapAttrsToList (name: _: mkAdmin name) adminUsers;
  };
}
