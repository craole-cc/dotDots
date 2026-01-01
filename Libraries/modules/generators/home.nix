{
  _,
  lib,
  ...
}: let
  inherit (_.attrsets.resolution) package;
  inherit (lib.attrsets) filterAttrs mapAttrs optionalAttrs;
  inherit (lib.lists) head optionals;
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
  homeManagerUsers = host:
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
    specialArgs,
    ...
  }: let
    #> Pre-filter users eligible for home-manager
    homeUsers = homeManagerUsers host;

    # Helper to build user-specific home-manager configuration
    mkHomeConfig = {
      name,
      cfg,
      apps,
      modules,
    }: let
      userApps = apps {
        user = (userAttrs host).${name} or {};
        config = cfg;
        inherit modules pkgs;
      };
    in
      {
        config,
        nixosConfig,
        mkHomeModuleApps,
        homeModules,
        src,
        ...
      }: let
        userApps = mkHomeModuleApps {
          user = cfg;
          inherit homeModules pkgs config;
        };
      in
        with userApps; {
          home.stateVersion = host.stateVersion or nixosConfig.sustem.stateVersion;

          #> Pass user data and apps to modules via _module.args
          _module.args.user = cfg // {inherit name userApps;};

          #> Conditionally import modules based on user's allowed applications
          imports =
            []
            ++ optionals dank-material-shell.isAllowed [dank-material-shell.module]
            ++ optionals noctalia-shell.isAllowed [noctalia-shell.module]
            ++ optionals nvf.isAllowed [nvf.module]
            ++ optionals plasma.isAllowed [plasma.module]
            ++ optionals zen-browser.isAllowed [zen-browser.module]
            ++ [(src + "/Packages/home")]
            ++ (cfg.imports or []);

          #> Enable programs based on module availability
          programs =
            {}
            // optionalAttrs dank-material-shell.isAllowed {
              dank-material-shell.enable = true;
            }
            // optionalAttrs noctalia-shell.isAllowed {
              noctalia-shell.enable = true;
            }
            // optionalAttrs nvf.isAllowed {
              nvf.enable = true;
            }
            // optionalAttrs plasma.isAllowed {
              plasma.enable = true;
            }
            // optionalAttrs zen-browser.isAllowed {
              zen-browser.enable = true;
            };
        };
  in {
    /**
    Security configuration for sudo access
    */
    security.sudo = {
      execWheelOnly = true;
      extraRules = mkSudoRules (adminsNames host);
    };

    /**
    System user and group configuration
    */
    users = {
      # Create a private group for each user
      groups = mapAttrs (_: _: {}) (userAttrs host);

      # Configure all system users (including service accounts)
      users = mapAttrs (name: cfg: {
        isNormalUser = cfg.role != "service";
        isSystemUser = cfg.role == "service";
        description = cfg.description or name;
        password = cfg.password or null;
        group = name;
        extraGroups =
          []
          ++ optionals (cfg.role or null != "service") ["users"]
          ++ optionals (isIn (cfg.role or null) ["admin" "administrator"]) ["wheel"]
          ++ optionals (host.devices.network != []) ["networkmanager"];
        shell = package {
          inherit pkgs;
          target = head (cfg.shells or ["bash"]);
        };
      }) (userAttrs host);
    };

    /**
    Home-manager configuration for eligible users (excludes service accounts and guests)
    */
    home-manager = {
      backupFileExtension = "BaC";
      overwriteBackup = true;
      useGlobalPkgs = true;
      useUserPackages = true;
      inherit extraSpecialArgs;

      # Only configure home-manager for eligible users
      # (excludes service accounts and guests)
      # users = mapAttrs mkHomeConfig homeUsers;
      users = mapAttrs (_: cfg: {
        config,
        nixosConfig,
        mkHomeModuleApps,
        homeModules,
        src,
        ...
      }: let
        userApps = mkHomeModuleApps {
          user = cfg;
          inherit homeModules pkgs config;
        };
      in
        with userApps; {
          home.stateVersion = host.stateVersion or nixosConfig.sustem.stateVersion;

          #> Pass user data and apps to modules via _module.args
          _module.args.user = cfg // {inherit name userApps;};

          #> Conditionally import modules based on user's allowed applications
          imports =
            []
            ++ optionals dank-material-shell.isAllowed [dank-material-shell.module]
            ++ optionals noctalia-shell.isAllowed [noctalia-shell.module]
            ++ optionals nvf.isAllowed [nvf.module]
            ++ optionals plasma.isAllowed [plasma.module]
            ++ optionals zen-browser.isAllowed [zen-browser.module]
            ++ [(src + "/Packages/home")]
            ++ (cfg.imports or []);

          #> Enable programs based on module availability
          programs =
            {}
            // optionalAttrs dank-material-shell.isAllowed {
              dank-material-shell.enable = true;
            }
            // optionalAttrs noctalia-shell.isAllowed {
              noctalia-shell.enable = true;
            }
            // optionalAttrs nvf.isAllowed {
              nvf.enable = true;
            }
            // optionalAttrs plasma.isAllowed {
              plasma.enable = true;
            }
            // optionalAttrs zen-browser.isAllowed {
              zen-browser.enable = true;
            };
        })
      homeUsers;
    };
  };

  /**
  Exported functions for external use.

  - mkUsers: Main user configuration builder
  - mkSudoRules: Sudo rule generator for admin users
  - homeModuleApps: Module availability detector for users
  */
  exports = {
    inherit
      mkUsers
      mkSudoRules
      ;
  };
in
  exports // {_rootAliases = exports;}
