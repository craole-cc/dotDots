{
  host,
  lib,
  lix,
  ...
}: let
  inherit (lib.attrsets) filterAttrs mapAttrs;
  inherit (lib.lists) elem;
  inherit (lix.configuration.core) mkSudoRules;

  users = host.users.data.enabled or {};
  names = host.users.names.enabled or [];
  admins = host.users.names.elevated or [];

  #> Collect all enabled regular users (non-service, non-guest)
  normalUsers = filterAttrs (_: u: !(elem u.role ["service" "guest"])) users;
  isNormalUser = cfg.role != "service";

  perUserConfigs =
    mapAttrs (name: cfg: let
    in {
      user = {
        inherit isNormalUser;
        isSystemUser = !isNormalUser;
        description = cfg.description or name;

        #> Use first shell as default
        shell = package {
          inherit pkgs;
          target = head (cfg.shells or ["bash"]);
        };

        password = cfg.password or null;

        extraGroups =
          optional
          (elem (cfg.role or null) ["admin" "administrator"])
          ["wheel"]
          ++ optional
          (isNormalUser && (config.networking.networkmanager.enable or false))
          ["networkmanager"];
      };
    })
    normalUsers;
in {
  security.sudo = {
    #> Restrict sudo to members of the wheel group (root is always allowed).
    execWheelOnly = true;

    #> For each admin user, grant passwordless sudo for all commands.
    extraRules = mkSudoRules admins;
  };
  users.users = mapAttrs (_name: cfg: cfg.user) perUserConfigs;
}
