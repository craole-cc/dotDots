{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) filterAttrs mapAttrs;
  inherit (lib.lists) elem head optionals;
  inherit (_.attrsets.resolution) package;
  inherit (_.applications.config) mkUserApps;
  inherit (_.lists.predicates) isIn;

  mkSudoRules = admins:
    map (name: {
      #> Apply this rule only to the named user.
      users = [name];

      #> Allow that user to run any command as any user/group, without password.
      #? Equivalent to: name ALL=(ALL:ALL) NOPASSWD: ALL
      commands = [
        {
          command = "ALL";
          options = ["SETENV" "NOPASSWD"];
        }
      ];
    })
    admins;

  # mkUserApps = {
  #   modules,
  #   pkgs,
  #   user,
  #   config,
  # }: {
  #   noctalia-shell = rec {
  #     isAllowed = hasInfix "noctalia" (user.interface.bar or "");
  #     variant = "default";
  #     module = modules.noctalia-shell.${variant} or {};
  #   };

  #   nvf =
  #     userApplicationConfig {
  #       inherit user pkgs config;
  #       name = "nvf";
  #       kind = "editor";
  #       category = "tty";
  #       resolutionHints = ["nvim" "neovim"];
  #       debug = true;
  #     }
  #     // {module = modules.nvf.default or {};};
  #   zen-browser = rec {
  #     isAllowed = hasInfix "zen" (user.applications.browser.firefox or "");
  #     variant =
  #       if hasInfix "twilight" (user.applications.browser.firefox or "")
  #       then "twilight"
  #       else "default";
  #     module = modules.zen-browser.${variant} or {};
  #   };
  # };

  userAttrs = host: host.users.data.enabled or {};
  adminsNames = host: host.users.names.elevated or [];

  mkUsers = {
    host,
    pkgs,
    homeModules,
    specialArgs,
    src,
    ...
  }: {
    security.sudo = {
      #> Restrict sudo to members of the wheel group (root is always allowed).
      execWheelOnly = true;

      #> For each admin user, grant passwordless sudo for all commands.
      extraRules = mkSudoRules (adminsNames host);
    };

    users = {
      #> Create a private group for each user
      #? This ensures the primary group exists before user creation
      groups = mapAttrs (_: _: {}) (userAttrs host);

      users =
        mapAttrs (name: cfg: {
          isNormalUser = cfg.role != "service";
          isSystemUser = cfg.role == "service";
          description = cfg.description or name;
          password = cfg.password or null;
          group = name;
          extraGroups =
            []
            ++ optionals (!isIn (cfg.role or null) ["service"]) ["users"]
            ++ optionals (isIn (cfg.role or null) ["admin" "administrator"]) ["wheel"]
            ++ optionals (host.devices.network != []) ["networkmanager"]
            ++ [];
          shell = package {
            inherit pkgs;
            target = head (cfg.shells or ["bash"]);
          };
        })
        (userAttrs host);
    };

    home-manager = {
      backupFileExtension = "BaC";
      overwriteBackup = true;
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = specialArgs // {inherit homeModules;};

      #> Merge all per-user home-manager configs
      users = mapAttrs (name: cfg: let
        userApps = mkUserApps {
          user = (userAttrs host).${name} or {};
          config = cfg;
          modules = homeModules;
          inherit pkgs;
        };
      in
        with userApps; {
          home = {inherit (host) stateVersion;};
          _module.args.user = cfg // {inherit name;};
          imports = with userApps;
            [(src + "/Packages/home")]
            ++ optionals (nvf.isAllowed) [nvf.module]
            ++ optionals (noctalia-shell.isAllowed) [noctalia-shell.module]
            ++ optionals (zen-browser.isAllowed) [zen-browser.module]
            ++ (cfg.imports or []);
          # config =
          #   {}
          #   // optionalAttrs (noctalia-shell.isAllowed) {
          #     inherit (noctalia-shell) programs home;
          #   }
          #   // optionalAttrs (nvf.isAllowed) {
          #     inherit (nvf) programs home;
          #   }
          #   // optionalAttrs (zen-browser.isAllowed) {
          #     inherit (zen-browser) programs home;
          #   }
          #   // {};
        })
      (filterAttrs (_: u: (!elem u.role ["service" "guest"])) (userAttrs host));
    };
  };
  exports = {inherit mkUsers mkSudoRules;};
in
  exports // {_rootAliases = exports;}
