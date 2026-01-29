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
      users = mapAttrs (name: user: {
        config,
        nixosConfig,
        mkHomeModuleApps,
        paths,
        ...
      }: let
        userApps = mkHomeModuleApps {
          inherit
            # config
            user
            ;
        };
        style = rec {
          theme = user.interface.style.theme or {};
          mode = toLower (theme.mode or "dark");
          variant = toLower (theme.${mode} or "Catppuccin Latte");
          accent = toLower (theme.accent or "rosewater");
          flavor =
            if hasInfix "frappe" variant || hasInfix "frappé" variant
            then "frappe"
            else if hasInfix "latte" variant
            then "latte"
            else if hasInfix "mocha" variant
            then "mocha"
            else if hasInfix "macchiato" variant
            then "macchiato"
            else if mode == "dark"
            then "frappe"
            else "latte";
          catppuccin = hasInfix "catppuccin" variant;
        };
      in
        with userApps; {
          #> Pass user data and apps to modules via _module.args
          _module.args.user = user // {inherit name userApps;};

          #> Update the stateVersion to mirror that of the host
          home = {inherit (nixosConfig.system) stateVersion;};

          #> Conditionally import modules based on user's allowed applications
          imports =
            [paths.store.pkgs.home]
            ++ optionals caelestia.isAllowed [
              caelestia.module
              {programs.caelestia.enable = true;}
            ]
            ++ optionals style.catppuccin [
              catppuccin.module
              {
                catppuccin = {
                  enable = true;
                  inherit (style) accent flavor;
                };
              }
            ]
            ++ optionals dank-material-shell.isAllowed [
              dank-material-shell.module
              {programs.dank-material-shell.enable = true;}
            ]
            ++ optionals noctalia-shell.isAllowed [
              noctalia-shell.module
              {programs.noctalia-shell.enable = true;}
            ]
            ++ optionals nvf.isAllowed [
              nvf.module
              {programs.nvf.enable = true;}
            ]
            ++ optionals plasma.isAllowed [
              plasma.module
              {programs.plasma.enable = true;}
            ]
            ++ optionals zen-browser.isAllowed [
              zen-browser.module
              {programs.zen-browser.enable = true;}
            ]
            ++ (user.imports or []);
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
