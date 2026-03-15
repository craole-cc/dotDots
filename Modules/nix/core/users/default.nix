{
  config,
  host,
  lib,
  lix,
  pkgs,
  top,
  ...
}: let
  dom = "users";
  cfg = config.${top}.${dom};

  inherit (lix.attrsets.resolution) package;
  inherit (lix.lists.predicates) isIn;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists) head optionals;
  inherit (lib.options) mkOption;
  inherit (lib.types) bool;

  hostUsers = host.users.data.enabled or {};
  adminNames = host.users.names.elevated or [];
  hasNetwork = host.hardware.hasNetwork;
in {
  options.${top}.${dom} = {
    execWheelOnly = mkOption {
      description = "Restrict sudo to wheel group members";
      default = true;
      type = bool;
    };
  };

  config = {
    security.sudo = {
      execWheelOnly = cfg.execWheelOnly;
      extraRules =
        map (name: {
          users = [name];
          commands = [
            {
              command = "ALL";
              options = ["SETENV" "NOPASSWD"];
            }
          ];
        })
        adminNames;
    };

    users = {
      groups = mapAttrs (_: _: {}) hostUsers;

      users =
        mapAttrs (name: user: {
          isNormalUser = user.role != "service";
          isSystemUser = user.role == "service";
          description = user.description or name;
          password = user.password or null;
          group = name;
          extraGroups =
            []
            ++ optionals (user.role != "service") ["users"]
            ++ optionals (isIn (user.role or null) ["admin" "administrator"]) ["wheel"]
            ++ optionals hasNetwork ["networkmanager"];
          shell = package {
            inherit pkgs;
            target = head (user.shells or ["bash"]);
          };
        })
        hostUsers;
    };
  };
}
