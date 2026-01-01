{
  _,
  lib,
  ...
}: let
  inherit (_.attrsets.resolution) package;
  inherit (_.lists.predicates) isIn;
  inherit (lib.attrsets) filterAttrs mapAttrs optionalAttrs;
  inherit (lib.lists) elem head optionals;
  inherit (lib.strings) hasInfix;

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

  userAttrs = host: host.users.data.enabled or {};
  adminsNames = host: host.users.names.elevated or [];

  homeModuleApps = {
    modules,
    pkgs,
    user,
    config,
  }: {
    plasma = {
      isAllowed = (
        (hasInfix "plasma" (user.interface.desktopEnvironment or ""))
        || (hasInfix "kde" (user.interface.desktopEnvironment or ""))
      );
      module = modules.plasma.default or {};
    };

    noctalia-shell = {
      isAllowed =
        isIn ["noctalia-shell" "noctalia" "noctalia-dev"]
        (
          (user.applications.allowed or [])
          ++ [(user.applications.bar or null)]
        );
      module = modules.noctalia-shell.default or {};
    };

    nvf = rec {
      isAllowed =
        isIn ["nvf" "nvim" "neovim"]
        (
          (user.applications.allowed or [])
          ++ [(user.applications.editor.tty.primary or null)]
          ++ [(user.applications.editor.tty.secondary or null)]
        );
      variant = "default";
      module = modules.nvf.${variant} or {};
    };

    zen-browser = rec {
      isAllowed =
        hasInfix "zen" (user.applications.browser.firefox or "")
        || (
          isIn ["zen" "zen-browser" "zen-twilight" "zen-browser"]
          (user.applications.allowed or [])
        );
      variant =
        if hasInfix "twilight" (user.applications.browser.firefox or "")
        then "twilight"
        else "default";
      module = modules.zen-browser.${variant} or {};
    };
  };

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
        userApps = homeModuleApps {
          user = (userAttrs host).${name} or {};
          config = cfg;
          modules = homeModules;
          inherit pkgs;
        };
      in
        with userApps; {
          home = {inherit (host) stateVersion;};
          _module.args.user = cfg // {inherit name userApps;};
          imports = with userApps;
            []
            # [(src + "/Packages/home")]
            ++ optionals (noctalia-shell.isAllowed) [noctalia-shell.module]
            ++ optionals (nvf.isAllowed) [nvf.module]
            ++ optionals (zen-browser.isAllowed) [zen-browser.module]
            ++ (cfg.imports or []);

          programs =
            {}
            // optionalAttrs (noctalia-shell.isAllowed) {noctalia-shell.enable = true;}
            // optionalAttrs (nvf.isAllowed) {nvf.enable = true;}
            // optionalAttrs (zen-browser.isAllowed) {zen-browser.enable = true;}
            // {};
        })
      (filterAttrs (_: u: (!elem u.role ["service" "guest"])) (userAttrs host));
    };
  };

  exports = {inherit mkUsers mkSudoRules homeModuleApps;};
in
  exports // {_rootAliases = exports;}
