{
  config,
  host,
  lix,
  pkgs,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "users";
    mod = "users";
  };
  inherit (context) cfg;

  inherit (lix.attrsets.resolution) package;
  inherit (lix.attrsets.transformation) mapAttrs removeAttrs;
  inherit (lix.lists.construction) optionals;
  inherit (lix.lists.access) head;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkOption mkTrue;
  inherit (lix.types.primitives) anything;

  hostUsers = host.users.data.enabled or {};
  adminNames = host.users.names.elevated or [];
  inherit (host.hardware) hasNetwork;
  publicProfiles = mapAttrs (_: user: removeAttrs user ["password"]) (host.users.data.all or {});
in
  mkConfig {
    inherit context;
    predicate = true;
    options = {
      execWheelOnly = mkTrue "Restrict sudo to wheel group members";
      profiles = mkOption {
        description = "Derived host user profiles for dots introspection; credential fields are omitted";
        default = publicProfiles;
        type = anything;
      };
    };
    outputs = {
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
  }
