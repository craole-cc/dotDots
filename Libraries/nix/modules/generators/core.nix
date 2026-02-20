{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.modules) evalModules;
  inherit (_.modules.resolution) getInputs;
  inherit (_.attrsets.resolution) package;
  inherit (lib.lists) head optionals;
  # inherit (_.filesystem.paths) getDefaults;
  inherit (_.lists.predicates) isIn;

  mkSystem = {
    hosts,
    flake,
    lix,
    schema,
    paths,
    ...
  }:
    mapAttrs (
      _name: host: let
        modules = let
          all = {
            inherit
              ((getInputs {inherit host flake;}).modules)
              modulesPath
              baseModules
              coreModules
              homeModules
              hostModules
              ;
            inherit lix lib;
          };
          eval = evalModules {
            specialArgs = all // {inherit lix host schema paths;};
            modules =
              []
              ++ all.baseModules
              ++ all.coreModules
              ++ all.hostModules
              ++ [{config._module.args = all;}];
          };
        in {inherit all eval;};
      in
        if (host.class or "nixos") == "darwin"
        then
          (
            modules.eval
            // {system = modules.eval.config.system.build.toplevel;}
          )
        else modules.eval
    )
    hosts;

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
  userAttrs = host: host.users.data.enabled or {};

  /**
  Get list of admin user names.

  Type: AttrSet -> [String]

  Returns: List of usernames with elevated privileges
  */
  adminsNames = host: host.users.names.elevated or [];

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
      extraRules = mkSudoRules (adminsNames host);
    };

    users = {
      #> Create a private group for each user
      groups = mapAttrs (_: _: {}) (userAttrs host);

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
      }) (userAttrs host);
    };
  };
  exports = {
    inherit
      mkSystem
      mkUsers
      mkSudoRules
      ;
  };
in
  exports // {_rootAliases = exports;}
