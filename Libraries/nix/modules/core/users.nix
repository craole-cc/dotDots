{
  _,
  lib,
  ...
}: let
  inherit (_.attrsets.resolution) package;
  inherit (_.lists.predicates) isIn;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists) head optionals;

  exports = {
    internal = {
      inherit
        mkSudoRules
        hostUsers
        homeUsers
        adminNames
        adminUsers
        mkUsers
        ;
    };
    external = {
      mkCoreUsers = mkUsers;
    };
  };

  /**
  Creates passwordless sudo rules for admin users.

  Type: [String] -> [AttrSet]

  Example:
    mkSudoRules ["alice" "bob"]
    => [
      { users = ["alice"]; commands = [{ command = "ALL"; options = ["SETENV" "NOPASSWD"]; }]; }
      { users = ["bob"]; commands = [{ command = "ALL"; options = ["SETENV" "NOPASSWD"]; }]; }
    ]
  */
  mkSudoRules = admins:
    map (name: {
      users = [name];
      commands = [
        {
          command = "ALL";
          options = ["SETENV" "NOPASSWD"];
        }
      ];
    })
    admins;

  /**
  Get all enabled users from host configuration.

  Type: AttrSet -> AttrSet

  Returns: An attribute set of enabled users with their configurations
  */
  hostUsers = host: host.users.data.enabled or {};

  /**
  Get users eligible for home-manager configuration.
  Delegates to the `interactive` user set, which already excludes
  service accounts and guests.

  Type: AttrSet -> AttrSet

  Returns: An attrset of enabled, interactive users.
  */
  homeUsers = host: host.users.data.interactive or {};

  /**
  Get list of admin user names.

  Type: AttrSet -> [String]

  Returns: List of usernames with elevated privileges
  */
  adminNames = host: host.users.names.elevated or [];
  adminUsers = host: host.users.data.elevated or {};

  /**
  Main user configuration builder.
  Creates NixOS users, home-manager configurations, and sudo rules.

  Type: { host, pkgs, homeModules, specialArgs, src, ... } -> AttrSet

  Arguments:
    - host: Host configuration containing user definitions
    - pkgs: Nixpkgs package set
    - homeModules: Available home-manager modules
    - specialArgs: Extra arguments to pass to home-manager
    - src: Source path for additional configurations

  Returns: Configuration attribute set containing:
    - security.sudo: Sudo configuration for admin users
    - users: System user and group definitions
    - home-manager: Per-user home-manager configurations

  Example:
    mkUsers {
      host = { users.data.enabled = { alice = { role = "admin"; }; }; };
      pkgs = pkgs;
      homeModules = {};
      specialArgs = {};
      src = ./.;
    }
  */
  mkUsers = {
    host,
    pkgs,
    ...
  }: {
    security.sudo = {
      execWheelOnly = true;
      extraRules = mkSudoRules (adminNames host);
    };

    users = {
      #> Create a private group for each user
      groups = mapAttrs (_: _: {}) (hostUsers host);

      #> Configure all system users (including service accounts)
      users = mapAttrs (name: user: {
        isNormalUser = user.role != "service";
        isSystemUser = user.role == "service";
        description = user.description or name;
        password = user.password or null;
        group = name;
        extraGroups =
          []
          ++ optionals (user.role or null != "service") ["users"]
          ++ optionals (isIn (user.role or null) ["admin" "administrator"]) ["wheel"]
          ++ optionals (host.devices.network != []) ["networkmanager"];
        shell = package {
          inherit pkgs;
          target = head (user.shells or ["bash"]);
        };
      }) (hostUsers host);
    };
  };
in
  exports.internal // {_rootAliases = exports.external;}
