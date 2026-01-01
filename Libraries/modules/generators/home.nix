{
  _,
  lib,
  ...
}: let
  inherit (_.attrsets.resolution) package;
  inherit (_.lists.predicates) isIn;
  inherit (lib.attrsets) filterAttrs mapAttrs optionalAttrs;
  inherit (lib.lists) head optionals;
  inherit (lib.strings) hasInfix;

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
  Determines which home-manager modules should be enabled for a user.
  Checks user configuration and returns module availability status.

  Type: { modules, pkgs, user, config } -> AttrSet

  Returns: An attribute set where each key is a module name containing:
    - isAllowed: Boolean indicating if the module should be loaded
    - module: The actual module to import (if available)
    - variant: (Optional) Specific variant of the module to use

  Example:
    homeModuleApps { user = { applications.allowed = ["nvim"]; }; ... }
    => { nvf = { isAllowed = true; variant = "default"; module = ...; }; ... }
  */
  homeModuleApps = {
    modules,
    pkgs,
    user,
    config,
  }: {
    # Plasma Desktop Environment
    plasma = {
      isAllowed =
        hasInfix "plasma" (user.interface.desktopEnvironment or "")
        || hasInfix "kde" (user.interface.desktopEnvironment or "");
      module = modules.plasma.default or {};
    };

    # Dank Material Shell
    dank-material-shell = {
      isAllowed = isIn ["dank-material-shell" "dank" "dms"] (
        (user.applications.allowed or [])
        ++ [(user.applications.bar or null)]
      );
      module = modules.dank-material-shell.default or {};
    };

    # Noctalia Shell
    noctalia-shell = {
      isAllowed = isIn ["noctalia-shell" "noctalia" "noctalia-dev"] (
        (user.applications.allowed or [])
        ++ [(user.applications.bar or null)]
      );
      module = modules.noctalia-shell.default or {};
    };

    # NVF (Neovim Framework)
    nvf = rec {
      isAllowed = isIn ["nvf" "nvim" "neovim"] (
        (user.applications.allowed or [])
        ++ [(user.applications.editor.tty.primary or null)]
        ++ [(user.applications.editor.tty.secondary or null)]
      );
      variant = "default";
      module = modules.nvf.${variant} or {};
    };

    # Zen Browser
    zen-browser = rec {
      isAllowed =
        hasInfix "zen" (user.applications.browser.firefox or "")
        || isIn ["zen" "zen-browser" "zen-twilight" "zen-browser"] (
          user.applications.allowed or []
        );
      variant =
        if hasInfix "twilight" (user.applications.browser.firefox or "")
        then "twilight"
        else "default";
      module = modules.zen-browser.${variant} or {};
    };
  };

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
    homeModules,
    specialArgs,
    src,
    ...
  }: let
    #> Pre-filter users eligible for home-manager
    homeUsers = homeManagerUsers host;

    # Helper to build user-specific home-manager configuration
    mkHomeConfig = name: cfg: let
      userApps = homeModuleApps {
        user = (userAttrs host).${name} or {};
        config = cfg;
        modules = homeModules;
        inherit pkgs;
      };
    in
      {nixosConfig, ...}:
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
      extraSpecialArgs = specialArgs // {inherit homeModules;};

      # Only configure home-manager for eligible users
      # (excludes service accounts and guests)
      users = mapAttrs mkHomeConfig homeUsers;
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
      homeModuleApps
      ;
  };
in
  exports // {_rootAliases = exports;}
