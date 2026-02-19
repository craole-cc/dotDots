{
  _,
  lib,
  ...
}: let
  inherit (_.attrsets.resolution) package;
  inherit (lib.attrsets) filterAttrs mapAttrs;
  inherit (lib.lists) head optionals;
  inherit (lib.strings) hasInfix toLower;
  inherit (_.lists.predicates) isIn;

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
  Filter users eligible for home-manager configuration.
  Excludes: service users, guest users, and empty/undefined users.

  Type: AttrSet -> AttrSet

  Example:
    homeManagerUsers { users.data.enabled = {
      alice = { role = "admin"; };
      cc = { role = "service"; };
    }; }
    => { alice = { role = "admin"; }; }
  */
  homeUserAttrs = host:
    filterAttrs
    (_: user:
      user
      != {} # User must exist
      && (user.role or null) != "service" # Not a system service
      && (user.role or null) != "guest") # Not a guest account
    
    (userAttrs host);

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
    extraSpecialArgs,
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

    home-manager = {
      backupFileExtension = "BaC";
      overwriteBackup = true;
      useGlobalPkgs = true;
      useUserPackages = true;
      inherit extraSpecialArgs;

      #> Only configure home-manager for eligible users
      #? (excludes service accounts and guests)
      users =
        mapAttrs (name: user: {
          # config,
          nixosConfig,
          mkHomeModuleApps,
          paths,
          ...
        }: let
          inputs = mkHomeModuleApps {inherit user;};
        in {
          #> Pass user data and apps to modules via _module.args
          _module.args.user = user // {inherit name;};

          #> Update the stateVersion to mirror that of the host
          home = {inherit (nixosConfig.system) stateVersion;};

          imports =
            []
            ++ [paths.store.pkgs.home]
            ++ (user.imports or [])
            #> Always import ALL modules so options are always defined
            ++ (with inputs; [
              caelestia.module
              catppuccin.module
              dank-material-shell.module
              noctalia-shell.module
              nvf.module
              plasma.module
              zen-browser.module
            ]);
        })
        (homeUserAttrs host);
    };
  };

  exports = {
    inherit
      mkUsers
      mkSudoRules
      ;
  };
in
  exports // {_rootAliases = exports;}
