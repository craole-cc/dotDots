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
  cfg = config.${top}.inputs.${dom};

  inherit (lix.attrsets.resolution) package;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.modules.core.staging) mkStaged;
  inherit (lib.attrsets) mapAttrs removeAttrs;
  inherit (lib.lists) head optionals;
  inherit (lib.options) mkOption;
  inherit (lib.types) anything bool;

  hostUsers = host.users.data.enabled or {};
  adminNames = host.users.names.elevated or [];
  inherit (host.hardware) hasNetwork;
  publicProfiles = mapAttrs (_: user: removeAttrs user ["password"]) (host.users.data.all or {});

  payload = {
    security.sudo = {
      inherit (cfg) execWheelOnly;
      extraRules =
        map (name: {
          users = [name];
          commands = [
            {
              command = "ALL";
              options = [
                "SETENV"
                "NOPASSWD"
              ];
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
            optionals (user.role != "service") ["users"]
            ++ optionals (isIn (user.role or null) [
              "admin"
              "administrator"
            ]) ["wheel"]
            ++ optionals hasNetwork ["networkmanager"];
          shell = package {
            inherit pkgs;
            target = head (user.shells or ["bash"]);
          };
        })
        hostUsers;
    };
  };
in {
  options.${top}.inputs.${dom} = {
    execWheelOnly = mkOption {
      description = "Restrict sudo to wheel group members";
      default = true;
      type = bool;
    };
    profiles = mkOption {
      description = "Derived host user profiles for dots introspection; credential fields are omitted";
      default = {};
      type = anything;
    };
  };

  config = lib.mkMerge [
    {${top}.inputs.users.profiles = publicProfiles;}
    (lib.mkMerge (mkStaged {
      inherit top payload;
    }))
  ];
}
